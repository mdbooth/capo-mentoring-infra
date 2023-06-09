# CAPO mentoring infra

## Quickstart

```bash
terraform -chdir=terraform init
ansible-galaxy install -r ansible/requirements.yml
```

Deploy the VMs in Azure:

```
ansible-playbook ./ansible/infra-up.yaml
```

Deploy OpenStack:

```
ansible-playbook ./ansible/openstack-up.yaml
```

Configure OpenStack:

```
ansible-playbook ./ansible/prepare-stack.yaml
```
