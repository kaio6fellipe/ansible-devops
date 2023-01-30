#!/bin/bash
# Managed by Ansible Controller

set -o errexit
set -o nounset
set -x

PROJECT_ID="{{ base_info.owner }}"
BRANCH="?ref={{ base_info.branch }}"
PAT_TOKEN="{{ vault_personal_access_token }}"
BASE_URL=https://"{{ gitlab_domain }}"/api/v4/projects/${PROJECT_ID}/repository
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
API_HEADER=${CURL}' -H PRIVATE-TOKEN:'${PAT_TOKEN}' '
BASE_API_CALL=${API_HEADER}${BASE_URL}

function_get_role_repo_content () {
    for ROLE in "${ROLE_REPO_PATH[@]}"; do
        URL_ROLE=$(echo $ROLE | cut -c2- | sed 's/\//\%2F/g' )
        API_CALL=$(echo ${BASE_API_CALL}'/tree'${BRANCH}'&recursive=false&per_page=50&path='${URL_ROLE}'')
        RAW_OUTPUT=$(${API_CALL})
        ROLE_NAME=$(echo $ROLE | sed 's|.*\/||' )
        BASE_DIR=${GITOPS_TEMP_DIR}'/roles/'${ROLE_NAME}
        mkdir -p ${BASE_DIR}
        echo -e $RAW_OUTPUT | ${JQ} -r '.[] | [.name, .type, .path] | @csv' 2>&1 | while IFS=, read -r raw_name raw_type raw_path
        do
            name=$(echo $raw_name | cut -d '"' -f 2)
            type=$(echo $raw_type | cut -d '"' -f 2)
            path=$(echo $raw_path | cut -d '"' -f 2)
            echo "$name, type: $type"
            if [ $type = "tree" ]; then
                function_scrap_dir "$path" "$name" "$BASE_DIR"
            elif [ $type = "blob" ]; then
                function_download_file "$path" "$name" "$BASE_DIR"
            else
                echo "Type not specified: $type"
            fi
        done
        
    done
}

function_scrap_dir () {
    DIR_PATH="$1"
    DIR_NAME="$2"
    CURRENT_DIR="$3"
    mkdir -p ${CURRENT_DIR}/${DIR_NAME}
    NEW_CURRENT_DIR="${CURRENT_DIR}/${DIR_NAME}"
    URL_DIR_PATH=$(echo $DIR_PATH | sed 's/\//\%2F/g' )
    API_CALL=$(echo ${BASE_API_CALL}'/tree'${BRANCH}'&recursive=false&per_page=50&path='${URL_DIR_PATH}'')
    RAW_OUTPUT=$(${API_CALL})
    echo -e $RAW_OUTPUT | ${JQ} -r '.[] | [.name, .type, .path] | @csv' 2>&1 | while IFS=, read -r raw_name raw_type raw_path
    do
        name=$(echo $raw_name | cut -d '"' -f 2)
        type=$(echo $raw_type | cut -d '"' -f 2)
        path=$(echo $raw_path | cut -d '"' -f 2)
        echo "$name, type: $type"
        if [ $type = "tree" ]; then
            function_scrap_dir "$path" "$name" "$NEW_CURRENT_DIR"
        elif [ $type = "blob" ]; then
            function_download_file "$path" "$name" "$NEW_CURRENT_DIR"
        else
            echo "Type not specified: $type"
        fi
    done
}

function_download_file () {
    FILE_PATH="$1"
    FILE_NAME="$2"
    CURRENT_DIR="$3"
    URL_PATH=$( echo $FILE_PATH | sed 's/\//\%2F/g' )
    FILE_OUTPUT=$(${BASE_API_CALL}'/files/'${URL_PATH}${BRANCH})
    echo -e $FILE_OUTPUT | ${JQ} -r '. | [.content] | @csv' 2>&1 | cut -d '"' -f 2 | base64 --decode > ${CURRENT_DIR}/${FILE_NAME}
}

#TO-DO
function_get_var_file_content () {
    for file in "${VAR_FILES_PATH[@]}"; do
        RAW_OUTPUT=$(${API_CALL}${file}${BRANCH})
        download_url=$(echo ${RAW_OUTPUT} | ${JQ} ".download_url" | cut -d '"' -f 2)
        file_name=$(echo ${RAW_OUTPUT} | ${JQ} ".name" | cut -d '"' -f 2)
        mkdir -p ${GITOPS_TEMP_DIR}/group_vars/all
        ${CURL} ${download_url} > ${GITOPS_TEMP_DIR}/group_vars/all/${file_name} 
    done
}

#TO-DO
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
#function_get_var_file_content
#function_diff_replace_content
