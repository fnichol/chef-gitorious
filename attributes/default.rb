default[:gitorious][:git][:url] = "git://gitorious.org/gitorious/mainline.git"
default[:gitorious][:git][:reference] = "master"

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

default[:gitorious][:host]                = "gitorious.local"
default[:gitorious][:support_email]       = "support@gitorious.org"
default[:gitorious][:notification_emails] = ""
default[:gitorious][:public_mode]         = "true"
default[:gitorious][:only_admins_create]  = "false"

default[:gitorious][:admin][:email]       = "admin@gitorious.local"
default[:gitorious][:admin][:password]    = "admin"

default[:gitorious][:locale]               = "en"
default[:gitorious][:hide_http_clone_urls] = "false"

default[:gitorious][:optional_tls][:url] =
  "git://github.com/collectiveidea/action_mailer_optional_tls.git"

default[:gitorious][:mailer][:delivery_method]  = "smtp"

default[:gitorious][:smtp][:tls]            = "false"
default[:gitorious][:smtp][:address]        = "smtp.example.com"
default[:gitorious][:smtp][:port]           = ""
default[:gitorious][:smtp][:domain]         = ""
default[:gitorious][:smtp][:authentication] = "plain"
default[:gitorious][:smtp][:username]       = ""
default[:gitorious][:smtp][:password]       = ""
