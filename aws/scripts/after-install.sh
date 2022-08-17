#!/bin/bash
set -xe

chown -R ec2-user:ec2-user /etc/ansible

if [ -f /etc/crontab ]; then
    rm -f /etc/crontab
fi

echo "Managed by Code Deploy" >> /etc/crontab
echo "SHELL=/bin/bash" >> /etc/crontab
echo "PATH=/sbin:/bin:/usr/sbin:/usr/bin" >> /etc/crontab
echo "MAILTO=root" >> /etc/crontab
ENV_DEPLOY=$(sudo -Hiu root env | grep ENV | cut -c5-7)
echo "*/5 * * * * ec2-user ansible-playbook -i /etc/ansible/inventory_${ENV_DEPLOY}_aws_ec2.yaml /etc/ansible/playbooks/*" >> /etc/crontab