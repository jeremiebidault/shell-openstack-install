#!/bin/bash

dnf install -y https://www.rdoproject.org/repos/rdo-release.rpm
dnf install -y centos-release-openstack-train
dnf update -y
dnf install -y openstack-packstack

cd ~/

rm -rf answer.txt
packstack --gen-answer-file=answers.txt


sed -i "s/^CONFIG_HEAT_INSTALL=.*/CONFIG_HEAT_INSTALL=y/" answers.txt
sed -i "s/^CONFIG_COMPUTE_HOSTS=.*/CONFIG_COMPUTE_HOSTS=10.0.0.105/" answers.txt
sed -i "s/^CONFIG_KEYSTONE_ADMIN_PW=.*/CONFIG_KEYSTONE_ADMIN_PW=passwd/" answers.txt
sed -i "s/^CONFIG_NEUTRON_ML2_TYPE_DRIVERS=.*/CONFIG_NEUTRON_ML2_TYPE_DRIVERS=vlan,flat/" answers.txt
sed -i "s/^CONFIG_NEUTRON_ML2_TENANT_NETWORK_TYPES=.*/CONFIG_NEUTRON_ML2_TENANT_NETWORK_TYPES=vlan/" answers.txt
sed -i "s/^CONFIG_NEUTRON_ML2_MECHANISM_DRIVERS=.*/CONFIG_NEUTRON_ML2_MECHANISM_DRIVERS=openvswitch/" answers.txt
sed -i "s/^CONFIG_NEUTRON_ML2_VLAN_RANGES=.*/CONFIG_NEUTRON_ML2_VLAN_RANGES=physnet1:1000:2000/" answers.txt
sed -i "s/^CONFIG_NEUTRON_L2_AGENT=.*/CONFIG_NEUTRON_L2_AGENT=openvswitch/" answers.txt
sed -i "s/^CONFIG_NEUTRON_OVS_BRIDGE_MAPPINGS=.*/CONFIG_NEUTRON_OVS_BRIDGE_MAPPINGS=extnet:br-ex,physnet1:br-eth1/" answers.txt
sed -i "s/^CONFIG_NEUTRON_OVS_BRIDGE_IFACES=.*/CONFIG_NEUTRON_OVS_BRIDGE_IFACES=br-ex:eth0,br-eth1:eth1/" answers.txt
sed -i "s/^CONFIG_NEUTRON_OVS_BRIDGES_COMPUTE=.*/CONFIG_NEUTRON_OVS_BRIDGES_COMPUTE=br-eth1/" answers.txt
sed -i "s/^CONFIG_PROVISION_DEMO=.*/CONFIG_PROVISION_DEMO=n/" answers.txt
sed -i "s/^CONFIG_CINDER_VOLUMES_CREATE=.*/CONFIG_CINDER_VOLUMES_CREATE=n/" answers.txt


packstack --answer-file=answers.txt --timeout=600


. keystonerc_admin


wget https://nexus.horizon.ovh/repository/images/CentOS-7-x86_64-GenericCloud.qcow2
glance image-create --name='centos' --visibility=public --container-format=bare --disk-format=qcow2 < CentOS-7-x86_64-GenericCloud.qcow2


neutron net-create public_network --provider:network_type flat --provider:physical_network extnet --router:external
neutron subnet-create --name public_subnet --enable_dhcp=False --allocation-pool=start=10.0.0.200,end=10.0.0.249 --gateway=10.0.0.1 public_network 10.0.0.0/24
neutron net-create private_network
neutron subnet-create --name private_subnet private_network 172.16.0.0/24
neutron router-create router
neutron router-gateway-set router public_network
neutron router-interface-add router private_subnet
