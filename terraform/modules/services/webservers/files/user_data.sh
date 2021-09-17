#!/bin/bash
  sudo apt update -y \
  && sudo apt-add-repository --yes --update ppa:ansible/ansible \
  && sudo apt update -y \
  && sudo apt-get install git software-properties-common ansible unzip -y \
  && sudo apt-get install openjdk-8-jdk -y \
  && sudo apt-get install apt-transport-https ca-certificates curl software-properties-common -y \
  && wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add - \
  && sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list' \
  && sudo apt-get update -y \
  && sudo apt-get install jenkins -y \
  && sudo service jenkins start \
  && git clone git@github.com:makschihin/SS_task3.git /opt/petclinic_home \
  && ansible-playbook --connection=local   /opt/petclinic_home/ansible/all_server.yml \
  && sudo echo "hello" >> /home/ubuntu/hello.txt