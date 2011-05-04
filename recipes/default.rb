#
# Cookbook Name:: gitorious
# Recipe:: default
#
# Copyright 2011, Fletcher Nichol
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include_recipe "rvm"
include_recipe "rvm_passenger::#{node[:gitorious][:web_server]}"

case node[:gitorious][:web_server]
when "apache2"
  apache_module "rewrite"
  apache_module "ssl"
end

rvm_ruby      = select_ruby(node[:rvm_passenger][:rvm_ruby]) + "@" +
                  node[:gitorious][:rvm_gemset]

web_server    = node[:gitorious][:web_server]
git_url       = node[:gitorious][:git][:url]
git_reference = node[:gitorious][:git][:reference]
app_user      = node[:gitorious][:app_user]
rails_env     = node[:gitorious][:rails_env]
deploy_to     = node[:gitorious][:app_base_dir]
current_path  = "#{node[:gitorious][:app_base_dir]}/current"
shared_path   = "#{node[:gitorious][:app_base_dir]}/shared"
git_base_dir  = node[:gitorious][:git_base_dir]
db_host       = node[:gitorious][:db][:host]
db_database   = node[:gitorious][:db][:database]
db_username   = node[:gitorious][:db][:user]
db_password   = node[:gitorious][:db][:password]
bin_path      = ::File.dirname(node[:rvm][:root_path])
g_ruby_bin    = "#{bin_path}/bin/gitorious_ruby"
g_rake_bin    = "#{bin_path}/bin/gitorious_rake"
g_bundle_bin  = "#{bin_path}/bin/gitorious_bundle"
g_gem_bin     = "#{bin_path}/bin/gitorious_gem"

node[:webapp][:users][:git] = { :deploy_keys => [] }
node.set[:stompserver][:rvm_ruby] = select_ruby(rvm_ruby) + "@stompserver"

rvm_gemset rvm_ruby

rvm_wrapper "gitorious" do
  ruby_string rvm_ruby
  binaries    %w{ rake ruby gem bundle }
end

include_recipe "webapp"

user_account app_user do
  gid             app_user
end

webapp_vhost_skel "gitorious" do               
  host_name       node[:gitorious][:host]
  non_ssl_server  true
  ssl_server      true
  ssl_cert        node[:gitorious][:ssl][:cert]
  ssl_key         node[:gitorious][:ssl][:key]
end

webapp_app_skel "gitorious" do
  vhost           "gitorious"
  profile         "rails"
  user            app_user
end

include_recipe "mysql::server"
require 'rubygems'
Gem.clear_paths
require 'mysql'

include_recipe "imagemagick"
include_recipe "stompserver"

package "ssh"
package "sphinxsearch"
package "memcached"
package "apg"
package "git-svn"
package "libonig-dev"
package "libmagickwand-dev"
package "geoip-bin"
package "libgeoip-dev"


user app_user do
  system    true
end

group "gitorious" do
  members [ app_user ]
  append  true
end

group "rvm" do
  members [ app_user ]
  append  true
end

file "/home/#{app_user}/.ssh/authorized_keys" do
  owner       app_user
  group       app_user
  mode        "0600"
  action      :create
  not_if do
    ::File.exists? "/home/#{app_user}/.ssh/authorized_keys"
  end
end

directory git_base_dir do
  owner       app_user
  group       app_user
  mode        "2755"
  recursive   true
end

%w{ repositories tarballs tarballs-work }.each do |dir|
  directory "#{git_base_dir}/#{dir}" do
    owner       app_user
    group       app_user
    mode        "2755"
    recursive   true
  end
end

execute "create_gitorious_mysql_database" do
  command <<-CREATE
    /usr/bin/mysqladmin -u root -p#{node[:mysql][:server_root_password]} \
      create #{db_database}
  CREATE
  not_if do
    m = Mysql.new(db_host, "root", node[:mysql][:server_root_password])
    m.list_dbs.include?(db_database)
  end
end

execute "install_gitorious_mysql_privileges" do
  command <<-GRANTS
    /usr/bin/mysql -u root -p#{node[:mysql][:server_root_password]} \
      < /etc/mysql/gitorious-grants.sql
  GRANTS
  action :nothing
end

template "/etc/mysql/gitorious-grants.sql" do
  path    "/etc/mysql/gitorious-grants.sql"
  source  "grants.sql.erb"
  owner   "root"
  group   "root"
  mode    "0600"
  variables(
    :database => db_database,
    :user     => db_username,
    :password => db_password
  )
  notifies :run, "execute[install_gitorious_mysql_privileges]", :immediately
end

%w{ system pids patches }.each do |dir|
  directory ::File.join(shared_path, dir) do
    owner       app_user
    group       app_user
    mode        "2775"
    recursive   true
  end
end

execute "restart_gitorious_webapp" do
  command     %{touch #{current_path}/tmp/restart.txt}
  user        app_user
  group       app_user
  action      :nothing
end

git current_path do
  repository  git_url
  reference   git_reference
  user        app_user
  group       app_user
  action      :sync
  notifies    :run, "execute[restart_gitorious_webapp]"
end

template "#{current_path}/.rvmrc" do
  source      "rvmrc.erb"
  owner       app_user
  group       app_user
  mode        "0644"
  variables(
    :rvm_env_path => "#{node[:rvm][:root_path]}/environments/#{rvm_ruby}",
    :ruby_string  => rvm_ruby
  )
  notifies    :run, "execute[restart_gitorious_webapp]"
end

rvm_shell "trust_rvmrc" do
  ruby_string rvm_ruby
  code        %{rvm rvmrc trust #{current_path}}
end

%w{ post-receive pre-receive }.each do |hook|
  execute "fix_#{hook}_hooks_shebangs" do
    cwd         ::File.join(current_path, "data", "hooks")
    user        app_user
    group       app_user
    command     %{sed -e 's|^#!/.*$|#!#{g_ruby_bin}|' -i #{hook}}
    not_if      <<-NOTIF
      grep -q "^#!#{g_ruby_bin}$" \
        #{::File.join(current_path, "data", "hooks", hook)}
    NOTIF
  end
end

# Gitorious is vendored with Rails 2.3.5 which is not compatible with newer RubyGems
rvm_shell "set_rubygems_version" do
  ruby_string rvm_ruby
  code        %{gem --version | grep 1.5.2 || rvm rubygems 1.5.2}
end

execute "gitorious_bundle" do
  cwd         current_path
  user        "root"
  group       "root"
  command     <<-CMD
    su --login --command "cd #{current_path} ; #{g_bundle_bin} install \
      --verbose --without development test" #{app_user}
  CMD
  not_if      <<-NOTIF
    #{g_gem_bin} list --no-versions --no-details --local stomp | \
      grep -q '^stomp$'
  NOTIF
  notifies    :run, "execute[restart_gitorious_webapp]"
end

execute "create_gitorious_tmp" do
  cwd         current_path
  user        app_user
  group       app_user
  command     <<-CMD
    #{g_rake_bin} RAILS_ENV=#{rails_env} tmp:create
  CMD
  not_if do
    ::File.directory?("#{current_path}/tmp/pids")
  end
end

execute "install_options_tls_plugin" do
  cwd         current_path
  user        app_user
  group       app_user
  command     <<-CMD
    #{g_ruby_bin} script/plugin install #{node[:gitorious][:optional_tls][:url]}
  CMD
  creates   "#{current_path}/vendor/plugins/action_mailer_optional_tls/init.rb"
  notifies    :run, "execute[restart_gitorious_webapp]"
end

case web_server
when "nginx"
  file "#{current_path}/public/.htaccess" do
    action    :delete
  end
end

directory "#{current_path}/log" do
  action      :delete
  recursive   true
  only_if do
    ::File.directory?("#{current_path}/log")
  end
end

directory "/var/log/gitorious" do
  owner       app_user
  group       app_user
  mode        "2755"
  recursive   true
end

[ "#{current_path}/log", "#{shared_path}/log" ].each do |sym|
  link sym do
    owner     app_user
    group     app_user
    to        "/var/log/gitorious"
  end
end

template "/etc/logrotate.d/gitorious" do
  source      "gitorious-logrotate.erb"
  owner       "root"
  group       "root"
  mode        "0644"
  variables(
    :current_path => current_path
  )
end

template "/usr/local/bin/gitorious" do
  source      "gitorious_script_wrapper.erb"
  owner       "root"
  group       "root"
  mode        "0755"
  variables(
    :rails_env    => rails_env,
    :current_path => current_path,
    :ruby_string  => rvm_ruby
  )
end

cookbook_file "#{current_path}/config/setup_load_paths.rb" do
  source      "setup_load_paths.rb"
  owner       app_user
  group       app_user
  mode        "0644"
  notifies    :run, "execute[restart_gitorious_webapp]"
end

template "#{current_path}/config/environments/#{rails_env}.rb" do
  source      "environments_production.rb.erb"
  owner       app_user
  group       app_user
  mode        "0640"
  variables(
    :delivery_method  => node[:gitorious][:mailer][:delivery_method],
    :tls              => node[:gitorious][:smtp][:tls],
    :address          => node[:gitorious][:smtp][:address],
    :port             => node[:gitorious][:smtp][:port],
    :domain           => node[:gitorious][:smtp][:domain],
    :authentication   => node[:gitorious][:smtp][:authentication],
    :username         => node[:gitorious][:smtp][:username],
    :password         => node[:gitorious][:smtp][:password]
  )
  notifies    :run, "execute[restart_gitorious_webapp]"
end

template "#{current_path}/config/database.yml" do
  source      "database.yml.erb"
  owner       app_user
  group       app_user
  mode        "0640"
  variables(
    :rails_env    => rails_env,
    :db_adapter   => "mysql",
    :db_host      => db_host,
    :db_database  => db_database,
    :db_username  => db_username,
    :db_password  => db_password
  )
  notifies    :run, "execute[restart_gitorious_webapp]"
end

execute "create_cookie_secret" do
  cwd         current_path
  user        app_user
  group       app_user
  command     <<-CMD
    apg -m 64 > #{current_path}/config/cookie_secret.txt
  CMD
  creates     "#{current_path}/config/cookie_secret.txt"
end

ruby_block "fetch_cookie_secret" do
  block do
    file = ::File.open("#{current_path}/config/cookie_secret.txt", "rb")
    secret = file.read
    file.close

    secret = secret.gsub(/$/, '\\').sub(/\\\n\\\z/, '') # fix line endings
    node.set[:gitorious][:cookie_secret] = secret
  end
end

template "#{current_path}/config/gitorious.yml" do
  source      "gitorious.yml.erb"
  owner       app_user
  group       app_user
  mode        "0644"
  variables(
    :rails_env    => rails_env
  )
  notifies    :run, "execute[restart_gitorious_webapp]"
end

template "#{current_path}/config/broker.yml" do
  source      "broker.yml.erb"
  owner       app_user
  group       app_user
  mode        "0644"
  variables(
    :rails_env    => rails_env
  )
  notifies    :run, "execute[restart_gitorious_webapp]"
end

execute "migrate_gitorious_database" do
  cwd         current_path
  user        app_user
  group       app_user
  command     <<-CMD
    #{g_rake_bin} RAILS_ENV=#{rails_env} db:create && \
    #{g_rake_bin} RAILS_ENV=#{rails_env} db:migrate
  CMD
  notifies    :run, "execute[restart_gitorious_webapp]"
  not_if do
    m = Mysql.new(db_host, db_username, db_password)
    m.select_db db_database
    m.list_tables.include? "schema_migrations"
  end
end

execute "bootstrap_gitorious_ultrasphinx" do
  cwd         current_path
  user        app_user
  group       app_user
  command     <<-CMD
    #{g_rake_bin} RAILS_ENV=#{rails_env} ultrasphinx:bootstrap
  CMD
  creates     "#{current_path}/config/ultrasphinx/#{rails_env}.conf"
  notifies    :run, "execute[restart_gitorious_webapp]"
end

template "/etc/init.d/git-ultrasphinx" do
  source      "git-ultrasphinx.erb"
  owner       "root"
  group       "root"
  mode        "0755"
  variables(
    :rails_env    => rails_env,
    :rake_bin     => g_rake_bin,
    :current_path => current_path
  )
end

template "/etc/init.d/git-daemon" do
  source      "git-daemon.erb"
  owner       "root"
  group       "root"
  mode        "0755"
  variables(
    :g_ruby_bin   => g_ruby_bin,
    :current_path => current_path
  )
end

template "/etc/init.d/git-poller" do
  source      "git-poller.erb"
  owner       "root"
  group       "root"
  mode        "0755"
  variables(
    :rails_env    => rails_env,
    :g_ruby_bin   => g_ruby_bin,
    :current_path => current_path
  )
end

cron "gitorious_ultrasphinx_reindexing" do
  user        app_user
  command     <<-CRON.sub(/^ {4}/, '')
    cd #{current_path} && #{g_rake_bin} RAILS_ENV=#{rails_env} ultrasphinx:index
  CRON
end

service "git-ultrasphinx" do
  action      [ :enable, :start ]
  pattern     "searchd"
  supports    :restart => true, :reload => true, :status => false
end

service "git-daemon" do
  action      [ :enable, :start ]
  supports    :restart => true, :reload => false, :status => false
end

service "git-poller" do
  action      [ :enable, :start ]
  pattern     "poller"
  supports    :restart => true, :reload => true, :status => false
end

execute "create_gitorious_admin_user" do
  cwd         current_path
  user        app_user
  group       app_user
  command     <<-CMD.sub(/^ {4}/, '')
    cat <<_INPUT | RAILS_ENV=#{rails_env} #{g_ruby_bin} script/create_admin
    #{node[:gitorious][:admin][:email]}
    #{node[:gitorious][:admin][:password]}
    _INPUT
  CMD
  only_if     <<-ONLYIF
    cd #{current_path} && \
    RAILS_ENV=#{rails_env} #{g_ruby_bin} script/runner \
      'User.find_by_is_admin(true) and abort'
  ONLYIF
end
