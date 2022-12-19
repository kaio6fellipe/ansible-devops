#!/bin/bash
# Managed by Ansible Controller

set -o errexit
set -o nounset

OWNER="{{ base_info.owner }}"
REPO="{{ base_info.repository }}"
BRANCH="?ref={{ base_info.branch }}"
USER_AUTH="{{ vault_user_auth }}"
PAT_TOKEN="{{ vault_personal_access_token }}"
BASE_URL=https://api.github.com/repos/${OWNER}/${REPO}/contents
ANSIBLE_DIR="/etc/ansible"
GITOPS_TEMP_DIR="${ANSIBLE_DIR}/tmp/gitops_agent"

declare -a ROLE_REPO_PATH=(
{% for role in monitored_roles %}
    "{{ role.path }}"
{% endfor                      %}
)
declare -a VAR_FILES_PATH=(
{% for var_file in extra_var_files %}
    "{{ var_file.path }}"
{% endfor                          %}
)

if [ "$(command -v jq)" = "" ]; then
    sudo yum install jq -y
fi

CURL=$(command -v curl)
JQ=$(command -v jq)
API_HEADER=${CURL}' -u ${USER_AUTH}:${PAT_TOKEN} -H "Accept: application/vnd.github+json" '
API_CALL=${API_HEADER}${BASE_URL}

function_scrap_dir () {
    SCRAP_URL="$1"
    DIR_NAME="$2"
    CURRENT_DIR="$3"
    mkdir -p ${CURRENT_DIR}/${DIR_NAME}
    NEW_CURRENT_DIR="${CURRENT_DIR}/${DIR_NAME}"
    RAW_OUTPUT=$(${API_HEADER}${SCRAP_URL})
    echo -e $RAW_OUTPUT | ${JQ} -r '.[] | [.name, .type, (.url // "-"), (.download_url // "-")] | @csv' 2>&1 | while IFS=, read -r raw_name raw_type raw_url raw_download_url 
    do
        name=$(echo $raw_name | cut -d '"' -f 2)
        type=$(echo $raw_type | cut -d '"' -f 2)
        url=$(echo $raw_url | cut -d '"' -f 2)
        download_url=$(echo $raw_download_url | cut -d '"' -f 2)
        echo "$name, type: $type"
        if [ $type = "dir" ]; then
            function_scrap_dir "$url" "$name" "$NEW_CURRENT_DIR"
        elif [ $type = "file" ]; then
            function_download_file "$download_url" "$name" "$NEW_CURRENT_DIR"
        else
            echo "Type not specified: $type"
        fi
    done
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
        echo -e $RAW_OUTPUT | ${JQ} -r '.[] | [.name, .type, (.url // "-"), (.download_url // "-")] | @csv' 2>&1 | while IFS=, read -r raw_name raw_type raw_url raw_download_url
        do
            name=$(echo $raw_name | cut -d '"' -f 2)
            type=$(echo $raw_type | cut -d '"' -f 2)
            url=$(echo $raw_url | cut -d '"' -f 2)
            download_url=$(echo $raw_download_url | cut -d '"' -f 2)
            echo "$name, type: $type"
            if [ $type = "dir" ]; then
                function_scrap_dir "$url" "$name" "$BASE_DIR"
            elif [ $type = "file" ]; then
                function_download_file "$download_url" "$name" "$BASE_DIR"
            else
                echo "Type not specified: $type"
            fi
        done
    done
}

function_get_var_file_content () {
    for file in "${VAR_FILES_PATH[@]}"; do
        RAW_OUTPUT=$(${API_CALL}${file}${BRANCH})
        download_url=$(echo ${RAW_OUTPUT} | ${JQ} ".download_url" | cut -d '"' -f 2)
        file_name=$(echo ${RAW_OUTPUT} | ${JQ} ".name" | cut -d '"' -f 2)
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
        {% for role in monitored_roles %}
        python3 $(which ansible-playbook) -i inventory/inventory.localhost all.yml --tags {{ role.tag }}
        {% endfor                      %}

    else
        echo "No diff found"
    fi 
}

function_get_role_repo_content
function_get_var_file_content
function_diff_replace_content
