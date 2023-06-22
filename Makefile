.PHONY: infra-up
infra-up:
	ansible-playbook ./ansible/infra-up.yaml

.PHONY: infra-destroy
infra-destroy:
	ansible-playbook ./ansible/infra-destroy.yaml

.PHONY: openstack-up
openstack-up:
	ansible-playbook ./ansible/openstack-up.yaml
