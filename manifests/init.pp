# == Class: openstack_provision
#
# Full description of class openstack_provision here.
#
# === Parameters
#
# Document parameters here.
#
# [*tenant_name*]
#   Specify tenant for the Neutron [sub]networks. Default is _admin_.
#
# [*fixed_range*]
#   Specify the Neutron private network range. Default is _10.0.0.0/24_.
#
# [*floating_range*]
#   Specify the Neutron floating IPs range. Default is _172.24.4.224/28_.
#
# [*glance_images_hash*]
#   Specify Glance images to be uploaded as hash for *create_resources*.
#   Default value will upload CentOS 6.5 and Ubuntu 12.04.
#
# [*external_interface*]
#   Interface with internet access, only used if forward rules are added.
#   Default value is _eth0_.
#
# [*forward_rules*]
#   Boolean value indicating whether we should create forward rules for getting
#   internet connectiviy or not. Default is _true_.
#
# [*private_network_name*]
#   Name for Neutron private network. Default is _private_.
#
# [*private_subnet_name*]
#   Name for Neutron private subnet. Default is _private_subnet_.
#
# [*public_bridge_name*]
#   Name for external Neutron OVS bridge. Default is _br-ex_.
#
# [*public_network_name*]
#   Name for Neutron public network. Default is _public_.
#
# [*public_subnet_name*]
#   Name for Neutron public subnet. Default is _public_subnet_.
#
# [*router_name*]
#   Name for Neutron router. Default is _router1_.
#
# === Examples
#
#  class { openstack_provision:
#    forward_rules => false,
#  }
#
# === Authors
#
# Rafael Durán Castañeda <rafadurancastaneda@gmail.com>
#
# === Copyright
#
# Copyright 2014 Rafael Durán Castañeda
#
class openstack_provision (
  $tenant_name    = 'admin',
  $fixed_range          = '10.0.0.0/24',
  $floating_range       = '172.24.4.224/28',
  $glance_images_hash   = undef,
  $external_interface   = 'eth0',
  $forward_rules        = true,
  $private_network_name = 'private',
  $private_subnet_name  = 'private_subnet',
  $public_bridge_name   = 'br-ex',
  $public_network_name  = 'public',
  $public_subnet_name   = 'public_subnet',
  $router_name          = 'router1',
) {
  include 'cinder::setup_test_volume'
  $ubuntu_url = 'http://cloud-images.ubuntu.com/precise/current'
  $centos_url = 'http://repos.fedorapeople.org/repos/openstack/guest-images'

  if !$glance_images_hash {
    $glance_images_hash_real = {
      'Ubuntu 12.04' => {
        'source' => "${ubuntu_url}/precise-server-cloudimg-amd64-disk1.img"
      },
      'CentOS 6.5' => {
        'source' => "${centos_url}/centos-6.5-20140117.0.x86_64.qcow2"
      }
    }
  } else {
    $glance_images_hash_real = $glance_images_hash
  }

  neutron_network { $public_network_name:
    ensure          => present,
    router_external => true,
    tenant_id       => 'None',
  }

  neutron_subnet { $public_subnet_name:
    ensure          => 'present',
    cidr            => $floating_range,
    enable_dhcp     => false,
    network_name    => $public_network_name,
    tenant_name     => $tenant_name,
  }

  neutron_network { $private_network_name:
    ensure      => present,
    tenant_name => $tenant_name,
  }

  neutron_subnet { $private_subnet_name:
    ensure       => present,
    cidr         => $fixed_range,
    network_name => $private_network_name,
    tenant_name  => $tenant_name,
  }

  neutron_router { $router_name:
    ensure               => present,
    tenant_name          => $tenant_name,
    gateway_network_name => $public_network_name,
    # A neutron_router resource must explicitly declare a dependency on
    # the first subnet of the gateway network.
    require              => Neutron_subnet[$public_subnet_name],
  }

  neutron_router_interface { "${router_name}:${private_subnet_name}":
    ensure => present,
  }

  neutron_l3_ovs_bridge { $public_bridge_name:
    ensure      => present,
    subnet_name => $public_subnet_name,
  }

  if $forward_rules {
    firewall { '000 forward in':
      ensure     => 'present',
      action     => 'accept',
      chain      => 'FORWARD',
      iniface    => $public_bridge_name,
      proto      => 'all',
      table      => 'filter',
    }

    firewall { '000 forward out':
      ensure     => 'present',
      action     => 'accept',
      chain      => 'FORWARD',
      outiface   => $public_bridge_name,
      proto      => 'all',
      table      => 'filter',
    }

    firewall { '000 nat':
      ensure     => 'present',
      chain      => 'POSTROUTING',
      jump       => 'MASQUERADE',
      outiface   => $external_interface,
      proto      => 'all',
      source     => $floating_range,
      table      => 'nat',
    }
  }

  $image_defaults = {
    ensure           => present,
    is_public        => 'yes',
    container_format => 'bare',
    disk_format      => 'qcow2',
  }
  create_resources('glance_image', $glance_images_hash_real, $image_defaults)
}
