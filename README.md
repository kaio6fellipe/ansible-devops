# **A project to practice Ansible** 

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=kaio6fellipe_ansible-devops&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=kaio6fellipe_ansible-devops)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=kaio6fellipe_ansible-devops&metric=security_rating)](https://sonarcloud.io/summary/new_code?id=kaio6fellipe_ansible-devops)
[![Reliability Rating](https://sonarcloud.io/api/project_badges/measure?project=kaio6fellipe_ansible-devops&metric=reliability_rating)](https://sonarcloud.io/summary/new_code?id=kaio6fellipe_ansible-devops)
![](https://img.shields.io/github/commit-activity/w/kaio6fellipe/ansible-devops)

| Env | Status |
| --- | ------ |
| Development | ![Build and package](https://github.com/kaio6fellipe/ansible-devops/actions/workflows/build_package.yml/badge.svg) |

This repository manage the configuration present in every machine of my platform (In creation) with a different approach of Ansible usage, using it in a "GitOps" flow with a pipeline linked to an "Ansible Controller" in AWS. Infrastructure bootstrap and management is being realized in my [terraform-devops](https://github.com/kaio6fellipe/terraform-devops) repository.

So basically this would be the flow that the code in this repository goes through:
- GitHub
- Build and Package (GitActions) 
- Upload to S3 
- CodePipeline ([aws folder](https://github.com/kaio6fellipe/ansible-devops/tree/development/aws/scripts))
  - Ansible Controller
    - After that, all playbooks will be executed, ensuring that all configs present in this repo will be provisioned in all machines present in the dynamic inventory

![](./how-it-works.drawio.svg)

### Things that are already included:
- [x] Common role to deal with user management and everything that all machines must have in common
- [x] Grafana Dashboards config role
- [x] Grafana Agent config role
- [x] Grafana Loki config role
- [x] Grafana Mimir config role (Testing)
- [x] Dynamic inventory based on AWS tags
- [x] SonarQube coverage
- [x] Granular GitOps Agent for Ansible
### Things that will be included (or not):
- [ ] GoTeleport config role (maybe not)
- [ ] Grafana Tempo config role
- [ ] Helm config role for EKS
- [ ] Amazon Linux 2 optimization role

## **[Role directory structure](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html#role-directory-structure)**
An Ansible role has a defined directory structure with eight main standard directories. You must include at least one of these directories in each role. You can omit any directories the role does not use. For example:

```shell
# playbooks
site.yml
webservers.yml
fooservers.yml
```
```shell
roles/
    common/               # this hierarchy represents a "role"
        tasks/            #
            main.yml      #  <-- tasks file can include smaller files if warranted
        handlers/         #
            main.yml      #  <-- handlers file
        templates/        #  <-- files for use with the template resource
            ntp.conf.j2   #  <------- templates end in .j2
        files/            #
            bar.txt       #  <-- files for use with the copy resource
            foo.sh        #  <-- script files for use with the script resource
        vars/             #
            main.yml      #  <-- variables associated with this role
        defaults/         #
            main.yml      #  <-- default lower priority variables for this role
        meta/             #
            main.yml      #  <-- role dependencies
        library/          # roles can also include custom modules
        module_utils/     # roles can also include custom module_utils
        lookup_plugins/   # or other types of plugins, like lookup in this case

    webtier/              # same kind of structure as "common" was above, done for the webtier role
    monitoring/           # ""
    fooapp/               # ""
```
