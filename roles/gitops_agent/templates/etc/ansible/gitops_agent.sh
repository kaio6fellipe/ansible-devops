# /bin/bash

# Some script to scrape files passed in vars
#
#
#

# Ansible commands to be executed if a diff was detected
{% for command in ansible_command %}
{{ command }} 
{% endfor                         %}