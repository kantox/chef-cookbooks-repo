include_recipe "percona::package_repo"

percona = node["percona"]
server  = percona["server"]
conf    = percona["conf"]
mysqld  = (conf && conf["mysqld"]) || {}

# construct an encrypted passwords helper -- giving it the node and bag name
passwords = EncryptedPasswords.new(node, percona["encrypted_data_bag"])

datadir = mysqld["datadir"] || server["datadir"]
user    = mysqld["username"] || server["username"]

if platform?(%w{debian ubuntu})
  
  directory "/var/cache/local/preseeding" do
    owner "root"
    group "root"
    mode 0755
    recursive true
  end
  
  execute "preseed percona-server-server" do
    command "debconf-set-selections /var/cache/local/preseeding/percona-server-server.seed"
    action :nothing
  end
  
  template "/var/cache/local/preseeding/percona-server-server.seed" do
    variables(:root_password => passwords.root_password)
    source "percona-server-server.seed.erb"
    owner "root"
    group "root"
    mode "0600"
    notifies :run, resources(:execute => "preseed percona-server-server"), :immediately
  end
  
# setup the debian system user config
  template "/etc/mysql/debian.cnf" do
    source "debian.cnf.erb"
    variables(:debian_password => passwords.debian_password)
    owner "root"
    group "root"
    mode "0600"
  end
  
end

# install packages
package "percona-server-server" do
  action :install
  options "--force-yes"
end


# setup the data directory
directory datadir do
  owner user
  group user
  recursive true
  action :create
end

# install db to the data directory
execute "setup mysql datadir" do
  command "mysql_install_db --user=#{user} --datadir=#{datadir}"
  not_if "test -f #{datadir}/mysql/user.frm"
end

# setup the main server config file
template "/etc/my.cnf" do
  source "my.cnf.#{conf ? "custom" : server["role"]}.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, "service[mysql]", :immediately
end
#
# now let's set the root password only if this is the initial install
execute "Update MySQL root password" do
  command "mysqladmin -u root password '#{passwords.root_password}'"
  not_if "test -f /etc/mysql/grants.sql"
end

# define the service
service "mysql" do
  supports :restart => true, :status => true, :reload => true
  action [:enable]
end

# access grants
include_recipe "percona::access_grants"
include_recipe "percona::replication"
