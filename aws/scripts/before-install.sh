#!/bin/bash
set -xe

# Delete the old  directory as needed. /home/ec2-user/ansible/
if [ -d /etc/ansible ]; then
    rm -rf /etc/ansible/
fi

mkdir -vp /etc/ansible