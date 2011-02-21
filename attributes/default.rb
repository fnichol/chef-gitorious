node[:webapp][:apps] << {
  :id           => "gitorious",
  :profile      => "rails",
  :host_name    => "_",
  :www_redirect => "delete",
  :user         => "git"
}

node[:webapp][:users][:git] = { :deploy_keys => [] }

# TODO: currently using bundler branch from cjohansen until his work is pushed
# to master mainline (approx Mar 04/11).
default[:gitorious][:git][:url] =
  "git://gitorious.org/~cjohansen/gitorious/cjohansens-mainline.git"
default[:gitorious][:git][:reference] =
  "68bdc6eae378fe51335ae6897bc1da25ba5afac8"

default[:gitorious][:web_server] = "nginx"

default[:gitorious][:app_user]      = "git"
default[:gitorious][:app_base_dir]  = "/srv/gitorious"
default[:gitorious][:git_base_dir]  = "/var/git"
default[:gitorious][:rails_env]     = "production"

default[:gitorious][:rvm_gemset] = "gitorious"

default[:gitorious][:db][:host]     = "localhost"
default[:gitorious][:db][:database] = "gitorious"
default[:gitorious][:db][:user]     = "gitor"
default[:gitorious][:db][:password] = "gitorious"

default[:gitorious][:host]                = "git.local"
default[:gitorious][:support_email]       = "support@gitorious.org"
default[:gitorious][:notification_emails] = ""
default[:gitorious][:public_mode]         = "true"
default[:gitorious][:only_admins_create]  = "false"
