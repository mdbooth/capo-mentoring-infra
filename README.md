# CAPO mentoring infra

## Quickstart

```bash
terraform -chdir=terraform init
ansible-galaxy install -r ansible/requirements.yml
```

```
ansible-playbook ./ansible/infra-up.yaml
```
