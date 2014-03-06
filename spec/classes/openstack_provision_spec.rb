require 'spec_helper'

describe 'openstack_provision' do
  context 'with defaults' do
    it { should contain_class('cinder::setup_test_volume') }

    it {
      should contain_neutron_network('public').with({
        :ensure => 'present',
        :router_external => true,
        :tenant_id => 'None',
      })
    }

    it {
      should contain_neutron_subnet('public_subnet').with({
        :ensure => 'present',
        :cidr => '172.24.4.224/28',
        :enable_dhcp => false,
        :network_name => 'public',
        :tenant_name => 'admin',
      })
    }

    it {
      should contain_neutron_network('private').with({
        :ensure => 'present',
        :tenant_name => 'admin',
      })
    }

    it {
      should contain_neutron_subnet('private_subnet').with({
        :ensure => 'present',
        :cidr => '10.0.0.0/24',
        :network_name => 'private',
        :tenant_name => 'admin',
      })
    }

    it {
      should contain_neutron_router('router1').with({
        :ensure => 'present',
        :tenant_name => 'admin',
        :gateway_network_name => 'public',
        :require => 'Neutron_subnet[public_subnet]',
      })
    }

    it {
      should contain_neutron_l3_ovs_bridge('br-ex').with({
        :ensure => 'present',
        :subnet_name => 'public_subnet',
      })
    }

    it {
      should contain_firewall('000 forward in').with({
        :ensure => 'present',
        :action => 'accept',
        :chain => 'FORWARD',
        :iniface => 'br-ex',
        :proto => 'all',
        :table => 'filter',
      })
    }

    it {
      should contain_firewall('000 forward out').with({
        :ensure => 'present',
        :action => 'accept',
        :chain => 'FORWARD',
        :outiface => 'br-ex',
        :proto => 'all',
        :table => 'filter',
      })
    }

    it {
      should contain_firewall('000 nat').with({
        :ensure => 'present',
        :chain => 'POSTROUTING',
        :jump => 'MASQUERADE',
        :outiface => 'eth0',
        :proto => 'all',
        :source => '172.24.4.224/28',
        :table => 'nat',
      })
    }

    it {
      should contain_glance_image('Ubuntu 12.04').with({
        :ensure => 'present',
        :is_public => 'yes',
        :container_format => 'bare',
        :disk_format => 'qcow2',
        :source => 'http://cloud-images.ubuntu.com/precise/current/precise-server-cloudimg-amd64-disk1.img',
      })
    }

    it {
      should contain_glance_image('CentOS 6.5').with({
        :ensure => 'present',
        :is_public => 'yes',
        :container_format => 'bare',
        :disk_format => 'qcow2',
        :source => 'http://repos.fedorapeople.org/repos/openstack/guest-images/centos-6.5-20140117.0.x86_64.qcow2',
      })
    }
  end
end
