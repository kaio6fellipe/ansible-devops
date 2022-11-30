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
declare -a LIST=()

if [ $(command -v jq) = "" ]; then
    sudo apt install jq -y
fi

CURL=$(command -v curl)
JQ=$(command -v jq)
API_HEADER=${CURL}' -H "Accept: application/vnd.github+json" '
API_CALL=${API_HEADER}${BASE_URL}

function_scrap_dir () {
    SCRAP_URL="$1"
    DIR_NAME="$2"
    CURRENT_DIR="$3"
    mkdir -p ${CURRENT_DIR}/${DIR_NAME}
    NEW_CURRENT_DIR="${CURRENT_DIR}/${DIR_NAME}"
    RAW_OUTPUT=$(${API_HEADER}${SCRAP_URL})
    while IFS=$'\t' read -r name type url download_url; do
        if [ $type = "dir" ]; then
            function_scrap_dir "$url" "$name" "$NEW_CURRENT_DIR"
        elif [ $type = "file" ]; then
            function_download_file "$download_url" "$name" "$NEW_CURRENT_DIR"
        else
            echo "Type not specified: $type"
        fi
    done <<< $(echo -e $RAW_OUTPUT | jq -r '.[] | [.name, .type, (.url // "-"), (.download_url // "-")] | @tsv' 2>&1)
}

function_download_file () {
    DOWNLOAD_URL="$1"
    FILE_NAME="$2"
    CURRENT_DIR="$3"
    ${CURL} ${download_url} > ${CURRENT_DIR}/${FILE_NAME}
}

function_get_role_repo_content () {
    for role in "${ROLE_REPO_PATH[@]}"; do
        RAW_OUTPUT=$(${API_CALL}${role}${BRANCH})
        BASE_DIR=${GITOPS_TEMP_DIR}${role}
        mkdir -p ${BASE_DIR}
        while IFS=$'\t' read -r name type url download_url; do
            if [ $type = "dir" ]; then
                function_scrap_dir "$url" "$name" "$BASE_DIR"
            elif [ $type = "file" ]; then
                function_download_file "$download_url" "$name" "$BASE_DIR"
            else
                echo "Type not specified: $type"
            fi
        done <<< $(echo -e $RAW_OUTPUT | jq -r '.[] | [.name, .type, (.url // "-"), (.download_url // "-")] | @tsv' 2>&1)
    done
}

function_get_var_file_content () {
    for file in "${VAR_FILES_PATH[@]}"; do
        RAW_OUTPUT=$(${API_CALL}${file}${BRANCH})
        download_url=$(echo ${RAW_OUTPUT} | jq ".download_url" | cut -d '"' -f 2)
        file_name=$(echo ${RAW_OUTPUT} | jq ".name" | cut -d '"' -f 2)
        mkdir -p ${GITOPS_TEMP_DIR}/group_vars/all
        ${CURL} ${download_url} > ${GITOPS_TEMP_DIR}/group_vars/all/${file_name} 
    done
}

function_diff_replace_content () {
    EXEC_GROUP_VARS=${ANSIBLE_DIR}/inventory
    EXEC_ROLES=${ANSIBLE_DIR}
    REF_GROUP_VARS=${GITOPS_TEMP_DIR}/group_vars
    REF_ROLES=${GITOPS_TEMP_DIR}/roles

    VARS_DIFF=$(diff --brief --recursive $REF_GROUP_VARS $EXEC_GROUP_VARS/group_vars | wc -l)
    ROLES_DIFF=$(diff --brief --recursive $REF_ROLES $EXEC_ROLES/roles | wc -l)
    DIFF=$(($VARS_DIFF + $ROLES_DIFF))

    if [ $DIFF != 0 ]; then
        cp -r $REF_GROUP_VARS $EXEC_GROUP_VARS
        cp -r $REF_ROLES $EXEC_ROLES
        # Ansible commands to be executed if a diff was detected
        # {% for command in ansible_command %}
        # {{ command }} 
        # {% endfor                         %}
    else
        echo "No diff found"
    fi 
}

function_get_role_repo_content
function_get_var_file_content
function_diff_replace_content
