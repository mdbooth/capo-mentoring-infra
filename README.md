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

> **NOTE**
> Currently untested.

```
ansible-playbook ./ansible/prepare-stack.yaml
```

## References

- https://gist.github.com/gilangvperdana/356296c8f4c6726859da290321087e71
- https://gist.github.com/gilangvperdana/e74b3536c0c8786c68cb3ed51e4acbd2
