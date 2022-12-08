# **Ansible GitOps Agent (Testing)** 

So basically, this role will configure a gitops agent to run via crontab or systemd timer on Linux servers, checking diff from the main branch and after that, executing `ansible-playbook` commands for each role provided in the group vars.

- Dependencies
  - Ansible installed and pre-configured on the host that will run the agent (Installed by the gitops_agent role).
  - Var file and a role that need to be monitored by the gitops agent.
