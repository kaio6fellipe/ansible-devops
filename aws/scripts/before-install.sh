#!/bin/bash
set -xe

# Delete the old  directory as needed. /home/ec2-user/ansible/
if [ -d /home/ec2-user/ansible ]; then
    rm -rf /home/ec2-user/ansible/
fi

mkdir -vp /home/ec2-user/ansible