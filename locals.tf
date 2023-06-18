locals {
    dns_word=var.env=="prod" ? "www":"${var.env}"
    dns_name=var.component=="frontend" ? "${local.dns_word}.${var.domain_name}":"${var.env}-${var.component}.${var.domain_name}"

    parameters=concat([var.component], var.parameters)
}