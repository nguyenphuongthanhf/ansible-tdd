# ansible-tdd
===========

# With docker

docker run -v $(dirname $SSH_AUTH_SOCK):$(dirname $SSH_AUTH_SOCK) -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK atdd command
docker run -it --name=atdd --volume=/home:/home atdd 

A small tool support deploy infrastructure with ansible & EC2. Support work with multi server EC2.

The provisioner works by passing the ansible repository based on attributes in `ansible_tdd.yml` & calling `ansible-playbook`.

![ansible-tdd](http://git.anphabe.net/ansible/ansible-tdd/raw/master/src/images/ansible-tdd.png "ansible-tdd, serverspec")


## Requirements
- [ansible-tdd](http://git.anphabe.net/ansible/ansible-tdd)
- [Ansible 2](https://github.com/ansible/ansible).
- [Serverspec](https://github.com/mizzy/serverspec).

## Installation & Setup

```
git clone http://git.anphabe.net/ansible/ansible-tdd
cd ansible-tdd
./install
```

## Example ansible_tdd.yml file

Support the same config of ansible ec2 module (http://docs.ansible.com/ansible/ec2_module.html)

```yaml
---
provision:
  app_name: ansible-tdd
  servers:
    - server_group: redis
      num_instances: 1
      region: 'us-west-2'
      key_name: 'xxxx'
      instance_tags: {}
      ansible_ssh_user: "centos"
      ansible_port: 22
    - server_group: web-server
      num_instances: 2
      region: 'us-west-2'
      key_name: 'xxxx'
      ansible_ssh_user: "centos"
      ansible_port: 22
    - server_group: statistic-server
      num_instances: 2
      region: 'us-west-2'
      key_name: 'xxxx'
      ansible_ssh_user: "centos"
      ansible_port: 22
test-cases:
  sample-testcases:
    - spec: web-server-connect-redis
      host_group: web-server
    - spec: statistic-server-connect-redis
      host_group: statistic-server
```
## Commands
```
Usage: atdd COMMAND [CONFIG]
Commands:
    init:       Generate scaffolding for ansible-tdd
    generate-role-testcase:       Generate scaffolding for role testcase
    generate-playbook-testcase:       Generate scaffolding for playbook
    create:     Create list aw2 instances belong file provisioning
    start:      Start/initialize all ec2 instances
    stop:       Stop all ec2 instances
    destroy:    Stop and remove all aw2 instances

    login:      Start a bash shell in a first instances.
        EX:
            atdd login group-host

    list:       List all instances
    prepare-test-tools: Upload all test tools to all server
    clear-test-tools: remove all test tools to all server

    test:       Run CONVERGE and verify by serverspec
        EX:
            atdd test playbook.yml

    converge:   Bootstrap a container for the config based on a template
        EX:
            atdd converge playbook.yml

    verify:     Only run serverspec verify server
        EX:
            Run a testcase
            atdd verify TEST-CASE-NAME
            Run all
            atdd verify
            atdd verify all

```

### Usage
Init project with command
```
atdd init
```
System will generate a scaffolding
```
.
+-- tests
¦   ¦   +-- ansible-tdd  
¦   ¦   ¦   +-- integration
+-- .log
+-- ansible_tdd.yml # edit provisioning information
+-- vault_ec2_secret_access.yml  # store aws access
+-- .vault_pass.txt # password unlock vault_ec2

```


Generate vault file has EC2 info
```aws_access.yml
vault_aws_access_key_id: {AWS_ACCESS_KEY_ID_ENTER_HERE}
vault_aws_secret_access_key: {AWS_SERCRET_ACCESS_KEY_ENTER_HERE}
```
Use vault module of ansible
```
ansible-vault encrypt aws_access.yml
```

and copy content after encrypt to file
```
vault_ec2_secret_access.yml

#enter password encrypt file to file
nano .vault_pass.txt
```

Create list EC2 instances
```
atdd create
```

Converge a script ansible by command
```
atdd converge xxxx_build_script.yml
```

Verify all instances by command
```
atdd verify
```

#### Directory

```
.
+-- roles
¦   +-- redis
¦   ¦   +-- tests # role tests
¦   ¦   ¦   +-- default.yml
¦   ¦   ¦   +-- ansible-tdd  
¦   ¦   ¦   ¦   +-- integration
¦   ¦   ¦   ¦   ¦    +-- redis-role-unittest
¦   ¦   ¦   ¦   ¦    ¦   +-- spec
¦   ¦   ¦   ¦   ¦    ¦   ¦    +-- redis_spec.rb
¦   +-- nginx
¦   ¦   +-- tests # role tests
¦   ¦   ¦   +-- default.yml
¦   ¦   ¦   +-- ansible-tdd  
¦   ¦   ¦   ¦   +-- integration
¦   ¦   ¦   ¦   ¦    +-- nginx-role-unittest
¦   ¦   ¦   ¦   ¦    ¦   +-- spec
¦   ¦   ¦   ¦   ¦    ¦   ¦    +-- nginx_spec.rb
+-- tests
¦   ¦   +-- ansible-tdd  
¦   ¦   ¦   +-- integration
¦   ¦   ¦   ¦    +-- xxx-playbook-testcase # playbook tests
¦   ¦   ¦   ¦    ¦   +-- setup.yml
¦   ¦   ¦   ¦    ¦   +-- teardown.yml
¦   ¦   ¦   ¦    ¦   +-- spec
¦   ¦   ¦   ¦    ¦   ¦    +-- nginx_connect_redis_spec.rb
+-- .log
+-- group_vars # store global variables
¦   +-- all
¦   ¦   +-- vars.yml
+-- ansible_tdd.yml

```

## Serverspec verify flow

ansible-tdd will run all role-testcase before run playbook testcase:

![ansible-tdd](http://git.anphabe.net/ansible/ansible-tdd/raw/master/src/images/flow-verify.png "ansible-tdd, serverspec")

### How to write a test role
Use command generate test role:

```
cd ./roles/xxx
atdd init
atdd generate-role-testcase {xxx-testcase-name}

.
+-- tests
¦   ¦   +-- ansible-tdd  
¦   ¦   ¦   +-- integration
¦   ¦   ¦   ¦   ¦    +-- {xxx-testcase-name}
¦   ¦   ¦   ¦   ¦    ¦   +-- spec
¦   ¦   ¦   ¦   ¦    ¦   ¦    +-- {xxx-testcase-name}_spec.rb
```
#### How to invoke test role when run playbook?
Add task at last line  ./roles/{redis}role_name/tasks/main.yml
```yml
- include: "{{ lookup('env','ATDD_INVOKE_VERIFY_ROLE') }}"
```
#### How to access to all variables of playbook on spec?
At serverspec accessed to all variables of roles by property
```ruby
require ENV['ATDD_ROLE_SPEC_HELPER']

describe 'Redis' do
  describe service('redis') do
    it { should  be_enabled }
    it { should  be_running }
  end

    # redis_port is a variable of role redis
    # redis_bind is a variable of role redis
  describe port(property['redis_port']) do
    it { should  be_listening.on(property['redis_bind']).with('tcp') }
  end
  describe file('/etc/redis.conf') do
    it { should  be_file }
    it { should  be_owned_by 'redis' }
  end

end

```

### How to write a test playbook
Generate a testcase for playbook:
```
cd {target-playbook}
atdd generate-playbook-testcase {xxx-testcase-name}

.
+-- tests
¦   ¦   +-- ansible-tdd  
¦   ¦   ¦   +-- integration
¦   ¦   ¦   ¦   ¦    +-- {xxx-testcase-name}
¦   ¦   ¦   ¦   ¦    ¦   +-- setup.yml
¦   ¦   ¦   ¦   ¦    ¦   +-- teardown.yml
¦   ¦   ¦   ¦   ¦    ¦   +-- spec
¦   ¦   ¦   ¦   ¦    ¦   ¦    +-- {xxx-testcase-name}_spec.rb
```

#### How to access to all variables of playbook on spec?
At serverspec accessed to all variables of roles by property
```ruby
require ENV['ATDD_ROLE_SPEC_HELPER']

describe 'Redis' do
  describe service('redis') do
    it { should  be_enabled }
    it { should  be_running }
  end

    # redis_port is a variable of role redis
    # redis_bind is a variable of role redis
  describe port(property['redis_port']) do
    it { should  be_listening.on(property['redis_bind']).with('tcp') }
  end
  describe file('/etc/redis.conf') do
    it { should  be_file }
    it { should  be_owned_by 'redis' }
  end

end

```
#### How to access to mockup variable (variable created by setup.yml on testcase folder) of playbook on spec?
```ruby
require ENV['ATDD_ROLE_SPEC_HELPER']

describe 'Redis' do
  describe port(property['{host_name}']['redis_port']) do
    it { should  be_listening.on(property['redis_bind']).with('tcp') }
  end
end

```

### Memcached client
#### Memcached client resource type.
its(:stdout), its(:stderr), its(:exit_status)
You can get the stdout, stderr and exit status of the command result, and can use any matchers RSpec supports.

https://github.com/jorisroovers/memclient

```ruby

context memcached('-h="localhost" -p="11211"  + ' set foo bar') do
  its (:stdout) { should match /OK/ }
end

context memcached('-h="localhost" -p="11211" get foo') do
  its (:stdout) { should match value }
end

```

### Redis client

#### Redis client resource type.
its(:stdout), its(:stderr), its(:exit_status)
You can get the stdout, stderr and exit status of the command result, and can use any matchers RSpec supports.

http://github.com/antirez/redis.git

```ruby

context redis('-h cache1.internal -p 3679   + ' set foo bar') do
  its (:stdout) { should match /OK/ }
end

context redis('-h cache1.internal -p 3679 get foo') do
  its (:stdout) { should match value }
end

```


## Beanstalk cliend
#### Memcached client resource type.
its(:stdout), its(:stderr), its(:exit_status)
You can get the stdout, stderr and exit status of the command result, and can use any matchers RSpec supports.

https://github.com/src-d/beanstool
```ruby

context beanstalk('stats') do
  its (:stdout) { should match /OK/ }
end


```


Add test suites to ansible_tdd.yml
```
# ansible_tdd.yml
...

test-cases:
  {xxx-testcase-name}:
    - spec: {xxx-testcase-name}_spec
      host_group: cache
```


## Notes

* The `default` in all of the above is the name of the test suite defined in the 'suites' section of your `ansible_tdd.yml`, so if you have more than suite of tests or change the name, you'll need to adapt the example accordingly.
* serverspec test files *must* be named `_spec.rb`

[Serverspec]: http://serverspec.org

## Tips

You can easily skip previous instructions and jump directly to the broken statement you just fixed by passing
an environment variable. Add the following to your `ansible_tdd.yml`:

```yaml
provision:
  app_name: ansible-tdd
  servers:
    - server_group: redis
      num_instances: 1
      region: 'us-west-2'
      key_name: 'xxxx'
      instance_tags: {}
      ansible_ssh_user: "centos"
      ansible_port: 22
```


