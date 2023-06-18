#!/bin/bash

sudo labauto ansible
sudo ansible-pull -i localhost, -U https://github.com/sai-pranay-teja/roboshop-ansible.git roboshop-app.yml -e env=dev -e components=${component} >/opt/ansible.log
