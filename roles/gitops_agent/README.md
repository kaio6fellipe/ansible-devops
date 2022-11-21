# **Ansible GitOps Agent (Testing)** 

So basically, this role will configure a gitops agent to run via crontab on Linux servers, checking diff from the main branch and after that, executing `ansible-playbook` commands for each command provided in the host vars.

- Dependencies to develop and test this role
  - Ansible installed and pre-configured on the host that will run the agent
  - Var file and a role that need to be monitored by the gitops agent, and for that, include a command that needs to be executed if a change is detected on the vars.yml
