# CAPO mentoring infra

A collection of playbooks to deploy a two-node OpenStack deployment on Azure.
This was used when mentoring students that were working on Cluster API Provider
OpenStack (CAPO).

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
> This is incomplete and untested. A document describing actual steps taken can
> be found [here](doc/prepare-stack.md).

```
ansible-playbook ./ansible/prepare-stack.yaml
```

## Debugging

As this is a standard Kolla-Ansible deployment, everything is deployed in
Docker containers.

```
docker ps
```

```bash
docker exec -ti nova_libvirt bash
```

## References

- https://gist.github.com/gilangvperdana/356296c8f4c6726859da290321087e71
- https://gist.github.com/gilangvperdana/e74b3536c0c8786c68cb3ed51e4acbd2
