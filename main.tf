# Launch Template Resource
resource "aws_launch_template" "template-main" {
  name = "${var.env}-${var.component}-template"

  image_id = data.aws_ami.centos-ami.id
  instance_type = var.instance_type
  iam_instance_profile {
    name = aws_iam_instance_profile.Full-access-profile.name
  }

  vpc_security_group_ids = [aws_security_group.app-traffic.id]
 
    user_data = base64encode(templatefile("${path.module}/userdata.sh" , {
    component=var.component
}))

  instance_market_options {
    market_type = "spot"
  }



  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.env}-${var.component}" 
      Monitor="yes"
    }
  }
}



resource "aws_autoscaling_group" "asg-main" {
  name                      = "${var.env}-${var.component}-roboshop"
  max_size                  = var.max_size
  min_size                  = var.min_size

  desired_capacity          = var.desired_capacity

  vpc_zone_identifier       = var.subnets_ids
  launch_template {
    id      = aws_launch_template.template-main.id
    version = "$Latest"
  }
  tag {
    key="Name"
    propagate_at_launch = true
    value = "${var.env}-${var.component}-asg"
  }
  
}

resource "aws_autoscaling_policy" "asg-policy" {
  autoscaling_group_name = "CPULoadMonitor"
  name                   = aws_autoscaling_group.asg-main.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    target_value = 20.0
    predefined_metric_specification {
        predefined_metric_type = "ASGAverageCPUUtilization"

    }
  }
}


resource "aws_security_group" "app-traffic" {
  name        = "${var.env}-${var.component}-SG"
  description = "APP traffic"
  vpc_id=var.vpc_id


  ingress {
    description      = "App Traffic"
    from_port        = var.port
    to_port          = var.port
    protocol         = "tcp"
    cidr_blocks      = var.allow_subnets
  }

  ingress {
    description      = "SSH Traffic"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [data.aws_vpc.default.cidr_block]
  }

    ingress {
    description      = "Prometheus Traffic"
    from_port        = 9100
    to_port          = 9100
    protocol         = "tcp"
    cidr_blocks      = [data.aws_vpc.default.cidr_block]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.env}-${var.component} traffic"
  }
}


resource "aws_lb_target_group" "tg-main" {
  name        = "${var.env}-${var.component}-tg"
  port        = var.port
  protocol    = "HTTP"
  health_check {
    enabled=true
    path = "/health"
    healthy_threshold = 2
    unhealthy_threshold = 5
    timeout = 4
    interval = 5
}
deregistration_delay = 30
tags = {
    Name = "${var.env}-${var.component} Target-groups"
}
vpc_id      = var.vpc_id
}


resource "aws_route53_record" "roboshop" {
    zone_id = data.aws_route53_zone.mine.zone_id
    name    = local.dns_name
    type    = "CNAME"
    ttl     = 30
    records = [var.alb_dns_name]
}

resource "aws_lb_listener_rule" "listener-rule" {
  listener_arn = var.listener_arn
  priority     = var.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg-main.arn
  }

  condition {
    host_header {
        values=[local.dns_name]
    }
  }
}

