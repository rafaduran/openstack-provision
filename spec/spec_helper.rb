require 'puppetlabs_spec_helper/module_spec_helper'

RSpec.configure do |config|
  config.color_enabled = true
  config.tty = true
  config.formatter = :documentation
  config.default_facts = {
    :operatingsystem => 'CentOS',
    :osfamily => 'RedHat',
    :operatingsystemrelease => '6.4',
    :concat_basedir => '/dne',
  }
end
