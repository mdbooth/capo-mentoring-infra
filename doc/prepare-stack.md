# OpenStack configuration

Below are the steps used to configure the clouds.

> **TODO**
> Convert these to Ansible.

## Network configuration

First, ensure that `br-ex` on the controller node is up and has an IP address
assigned to it. If not, you can configure this like so (as root):

```bash
ip a add 192.168.234.2/23 dev br-ex
ip link set br-ex up
```

Also ensure that masquerading is enabled on the bastion. If not, you can
configure this like so (as root):

```bash
export EXT_NET_CIDR='192.168.234.0/23'
iptables -t nat -A POSTROUTING -s ${EXT_NET_CIDR} -o eth0 -j MASQUERADE
```

Once done, configure a provider network, a tenant network, and a router. The
provider network uses the `provider_cidr` Ansible setting.

```bash
export EXT_NET_CIDR='192.168.234.0/23'
export EXT_NET_RANGE='start=192.168.234.100,end=192.168.235.254'
export EXT_NET_GATEWAY='192.168.234.1'

export DEMO_NET_CIDR='10.0.0.0/24'
export DEMO_NET_GATEWAY='10.0.0.1'
export DEMO_NET_DNS='8.8.8.8'

openstack network create --external --provider-physical-network physnet1 \
    --provider-network-type flat public1
openstack subnet create --no-dhcp --ip-version 4 \
    --allocation-pool ${EXT_NET_RANGE} --network public1 \
    --subnet-range ${EXT_NET_CIDR} --gateway ${EXT_NET_GATEWAY} public1-subnet

openstack network create demo-net
openstack subnet create --ip-version 4 \
    --subnet-range ${DEMO_NET_CIDR} --network demo-net \
    --gateway ${DEMO_NET_GATEWAY} --dns-nameserver ${DEMO_NET_DNS} \
    demo-subnet

openstack router create demo-router
openstack router add subnet demo-router demo-subnet
openstack router set --external-gateway public1 demo-router
```

## Flavor configuration

Create the standard flavors.

```bash
openstack flavor create --ram 1024 --disk 10 --vcpu 1 --public m1.tiny
openstack flavor create --ram 2048 --disk 15 --vcpu 1 --public m1.small
openstack flavor create --ram 4096 --disk 20 --vcpu 2 --public m1.medium
openstack flavor create --ram 8192 --disk 25 --vcpu 4 --public m1.large
openstack flavor create --ram 16384 --disk 40 --vcpu 4 --public m1.xlarge
```

## Image configuration

Upload a simple Cirros image for testing.

```bash
curl -L https://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img > /tmp/cirros-0.6.2-x86_64-disk.img
openstack image create --public --container-format bare --disk-format qcow2 --property hw_rng_model=virtio --file /tmp/cirros-0.6.2-x86_64-disk.img cirros-0.6.2-x86_64-disk
```

## User and project configuration

We have a single project, `capo`, that all students share. The students have
the `member` role, while the mentors have the `admin` role.

```bash
openstack project create capo

openstack group create mentors

users=( mbooth stephenfin )
for user in ${users[@]}; do
    pass=$(shuf -er -n20  {A..Z} {a..z} {0..9} | tr -d '\n')
    openstack user create \
      --project capo --password "${pass}" "${user}"
    openstack role add --user "${user}" --project capo admin
    openstack role add --user "${user}" --project capo load-balancer_admin
    openstack group add user mentors "${user}"
    echo "user: ${user}"
    echo "pass: ${pass}"
done

openstack group create students

users=( switt anastasr jddaggett shu )
for user in ${users[@]}; do
    pass=$(shuf -er -n20  {A..Z} {a..z} {0..9} | tr -d '\n')
    openstack user create \
      --project capo --password "${pass}" "${user}"
    openstack role add --user "${user}" --project capo member
    openstack role add --user "${user}" --project capo load-balancer_member
    openstack group add user students "${user}"
    echo "user: ${user}"
    echo "pass: ${pass}"
done
```

## Validation

Test it with a server:

```bash
openstack server create --image cirros-0.6.2-x86_64-disk \
    --flavor m1.tiny --network demo-net test-server
openstack floating ip create public1
openstack add floating ip test-server 192.168.235.215
```
