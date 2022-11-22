#!/bin/bash
# Managed by Ansible Controller

set -o errexit
set -o nounset

OWNER="kaio6fellipe"
REPO="ansible-devops"
ROLE_REPO_PATH="/roles/grafana_agent"
VAR_FILES_PATH=(
    "/group_vars/global_dev_vars.yaml"
)
BASE_URL=https://api.github.com/repos/${OWNER}/${REPO}/contents
ANSIBLE_DIR="/etc/ansible/"
GITOPS_TEMP_DIR="/tmp/gitops_agent/"

if [ $(command -v jq) = "" ]; then
    sudo apt install jq -y
fi

CURL=$(command -v curl)
JQ=$(command -v jq)

COMMAND=$(${CURL} -H "Accept: application/vnd.github+json" ${BASE_URL})

echo ${COMMAND} | jq ".[]"

function_get_repo_content () {
    echo "I am a function"
}

function_get_file_content () {
    echo "I am a function"
}

function_diff_repo_content () {
    echo "I am a function"
}

function_diff_file_content () {
    echo "I am a function"
}

function_replace_repo_content () {
    echo "I am a function"
}

function_replace_file_content () {
    echo "I am a function"
}

# Ansible commands to be executed if a diff was detected
# {% for command in ansible_command %}
# {{ command }} 
# {% endfor                         %}