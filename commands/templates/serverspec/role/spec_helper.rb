require 'serverspec'
require 'net/ssh'
require 'json'
require ENV['ATDD_SOURCE_DIRECTORY']+'/commands/templates/serverspec/types/atddmemcache.rb'
require ENV['ATDD_SOURCE_DIRECTORY']+'/commands/templates/serverspec/types/atddredis.rb'
require ENV['ATDD_SOURCE_DIRECTORY']+'/commands/templates/serverspec/types/atddbeanstool.rb'


file = File.read(ENV['ATDD_EXTRA_VARS_VERIFY_ROLES_JSON'])
properties = JSON.parse(file)

set_property properties

set :backend, :ssh
set :request_pty, true

if ENV['ASK_SUDO_PASSWORD']
  begin
    require 'highline/import'
  rescue LoadError
    fail "highline is not available. Try installing it."
  end
  set :sudo_password, ask("Enter sudo password: ") { |q| q.echo = false }
else
  set :sudo_password, ENV['SUDO_PASSWORD']
end

host = ENV['ATDD_ANSIBLE_HOSTNAME']

options = Net::SSH::Config.for(host)

options[:user] = ENV['ATDD_ANSIBLE_SSH_USER']

set :host,        options[:host_name] || host
set :ssh_options, options

# Disable sudo
# set :disable_sudo, true


# Set environment variables
# set :env, :LANG => 'C', :LC_MESSAGES => 'C' 

# Set PATH
# set :path, '/sbin:/usr/local/sbin:$PATH'

