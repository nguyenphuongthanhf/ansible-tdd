require 'serverspec'
require 'net/ssh'
require 'yaml'
require 'json'
require ENV['ATDD_SOURCE_DIRECTORY']+'/commands/templates/serverspec/types/atddmemcache.rb'
require ENV['ATDD_SOURCE_DIRECTORY']+'/commands/templates/serverspec/types/atddredis.rb'
require ENV['ATDD_SOURCE_DIRECTORY']+'/commands/templates/serverspec/types/atddbeanstool.rb'
require ENV['ATDD_SOURCE_DIRECTORY']+'/commands/templates/serverspec/types/atddmysql.rb'
require ENV['ATDD_SOURCE_DIRECTORY']+'/commands/templates/serverspec/types/atddmongod.rb'

set :backend, :ssh
set :request_pty, true

playbook_directory= ENV['ATDD_PLAYBOOK_DIRECTORY']

ansible_global_vars=[]
if File.exist?("#{playbook_directory}/group_vars/all/vars.yml")
  ansible_global_vars = YAML.load_file("#{playbook_directory}/group_vars/all/vars.yml")
end

mockup_vars_path ="#{playbook_directory}/.log/mockup/" + ENV['TESTCASE_NAME'] +'/fact/vars.fact'
if File.exist?(mockup_vars_path)
  ansible_global_vars['mockup'] = YAML.load_file(mockup_vars_path)
end

host_info="#{playbook_directory}/.log/ansible_tdd_inventory.yml"
if File.exist?(host_info)
  ansible_global_vars['hosts'] =YAML.load_file(host_info)
end

set_property ansible_global_vars

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

host = ENV['ATDD_TARGET_HOST']

options = Net::SSH::Config.for(host)

options[:user] = ENV['ATDD_TARGET_SSH_USER']
if ENV['SSH_CUSTOM_KEY']
  options[:keys] = ENV['SSH_CUSTOM_KEY']
end

set :host,        options[:host_name] || host
set :ssh_options, options

# Disable sudo
# set :disable_sudo, true


# Set environment variables
# set :env, :LANG => 'C', :LC_MESSAGES => 'C'

# Set PATH
# set :path, '/sbin:/usr/local/sbin:$PATH'

def setupByAnsible()
  name_test_cases = ENV['TESTCASE_NAME']
  testcase_directory=  ENV['ATDD_PLAYBOOK_DIRECTORY']
  need_setup_by_ansible="#{testcase_directory}/tests/ansible-tdd/integration/#{name_test_cases}/setup.yml"
  if File.exist?(need_setup_by_ansible)
    puts "############### START ANSIBLE SETUP TESTCASE #{name_test_cases}"
    system "ansible-playbook -i #{testcase_directory}/.log/tdd_ec2_inventory.ini #{need_setup_by_ansible}  --extra-vars 'testcase_name=#{name_test_cases}'"
    puts "############### END ANSIBLE SETUP TESTCASE #{name_test_cases}"
  end
end

def teardownByAnsilbe()
  name_test_cases = ENV['TESTCASE_NAME']
  testcase_directory=  ENV['ATDD_PLAYBOOK_DIRECTORY']

  need_setup_by_ansible="#{testcase_directory}/tests/ansible-tdd/integration/#{name_test_cases}/teardown.yml"
  if File.exist?(need_setup_by_ansible)
    puts "############### START ANSIBLE TEARDOWN TESTCASE #{name_test_cases}"
    ENV['ATDD_SETUP_MOCKUP_VARS']="#{testcase_directory}/.log/mockup/#{name_test_cases}/fact/vars.fact"
    system "ansible-playbook -i #{testcase_directory}/.log/tdd_ec2_inventory.ini #{need_setup_by_ansible}  --extra-vars 'testcase_name=#{name_test_cases}'"

    # Clean all temporary data
    if File.exist?("#{testcase_directory}/.log/mockup/#{name_test_cases}/fact/vars.fact")
      system "rm  #{testcase_directory}/.log/mockup/#{name_test_cases}/fact/vars.fact -rf"
    end

    puts "############### END ANSIBLE TEARDOWN TESTCASE #{name_test_cases}"
  end

  ENV['TESTCASE_NAME']=""
  ENV['ATDD_PLAYBOOK_DIRECTORY']=""
  ENV['ATDD_SETUP_MOCKUP_VARS']=""
end


RSpec.configure do |config|
  config.tty = true
  config.color = true

  config.before(:all) do
    setupByAnsible()
  end

  config.after(:all) do
    teardownByAnsilbe()
  end
end

