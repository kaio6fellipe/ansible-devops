#!/bin/bash
# Managed by Ansible Controller

set -o errexit
set -o nounset

OWNER="kaio6fellipe"
REPO="ansible-devops"
BRANCH="?ref=ansible-gitops-agent"
BASE_URL=https://api.github.com/repos/${OWNER}/${REPO}/contents
ANSIBLE_DIR="$(pwd)"
GITOPS_TEMP_DIR="$(pwd)/tmp/gitops_agent"

declare -a ROLE_REPO_PATH=(
    "/roles/grafana_agent"
)
declare -a VAR_FILES_PATH=(
    "/group_vars/dev/global_dev_vars.yaml"
)

if [ $(command -v jq) = "" ]; then
    sudo apt install jq -y
fi

CURL=$(command -v curl)
JQ=$(command -v jq)
API_CALL=${CURL}' -H "Accept: application/vnd.github+json" '${BASE_URL}

# ${API_CALL} | jq "."

function_scrap_dir () {
    echo "I am a function"
}

function_get_role_repo_content () {
    for role in "${ROLE_REPO_PATH[@]}"; do
        RAW_OUTPUT=$(${API_CALL}${role}${BRANCH})
        # RAW_OUTPUT=$($RAW_OUTPUT | sed 's/\n//g' | sed 's/\[//' | sed 's/.$//' | sed 's/},/\n/g')
        while IFS=$'}\n{' read -r line; do
            echo -e $line
            echo -e teste
        done <<< $RAW_OUTPUT | tr -d ' ' | tr -d '\n' | sed 's/\[//' | sed 's/.$//' | sed 's/},/}\n/g'
        # for item in "${LIST[@]}"; do
        #     echo $item
    done
}

function_get_role_repo_content_recursive () {
    echo "I am a function"
}

function_get_role_repo_content

function_get_var_file_content () {
    for file in "${VAR_FILES_PATH[@]}"; do
        RAW_OUTPUT=$(${API_CALL}${file}${BRANCH})
        download_url=$(echo ${RAW_OUTPUT} | jq ".download_url" | cut -d '"' -f 2)
        file_name=$(echo ${RAW_OUTPUT} | jq ".name" | cut -d '"' -f 2)
        ${CURL} ${download_url} > ${GITOPS_TEMP_DIR}/group_vars/all/${file_name} 
    done
}

# function_get_var_file_content

function_diff_role_repo_content () {
    echo "I am a function"
}

function_diff_var_file_content () {
    echo "I am a function"
}

function_replace_role_repo_content () {
    echo "I am a function"
}

function_replace_var_file_content () {
    echo "I am a function"
}

# Ansible commands to be executed if a diff was detected
# {% for command in ansible_command %}
# {{ command }} 
# {% endfor                         %}