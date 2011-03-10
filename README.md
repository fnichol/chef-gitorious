# Description

Installs a full Gitorious server software stack. Details to be filled in.

# Requirements

## Platform

Currently known to work with Ubuntu and Debian systems.

## Cookbooks

In brief, these cookbooks are used to build a full running Gitorious stack:

* rvm [https://github.com/fnichol/chef-rvm](https://github.com/fnichol/chef-rvm)
* rvm_passenger [https://github.com/fnichol/chef-rvm_passenger](https://github.com/fnichol/chef-rvm_passenger)
* webapp [https://github.com/fnichol/chef-webapp](https://github.com/fnichol/chef-webapp)
* nginx [https://github.com/fnichol/chef-cookbooks](https://github.com/fnichol/chef-cookbooks)
* mysql [https://github.com/fnichol/chef-cookbooks](https://github.com/fnichol/chef-cookbooks)
* imagemagick [https://github.com/opscode/cookbooks](https://github.com/opscode/cookbooks)
* stompserver [https://github.com/fnichol/chef-cookbooks](https://github.com/fnichol/chef-cookbooks)

# Attributes

## `git/url`

The Git URL to the Gitorious codebase. This can be swapped out for an alternate
or forked version. The default points to the Gitorious mainline,
[git://gitorious.org/gitorious/mainline.git](git://gitorious.org/gitorious/mainline.git).

## `git/reference`

A Git SHA hash, tag, or branch reference on the `node[:gitorious][:git][:url]`
Git repository. Use this to lock down a specific revision (for reliable
rebuilds over time), or to use an alternate branch. The default is `master`.

**Note:** The Gitorious codebase is synced from the Git URL, meaning that
running Chef again after some time could update the Rails application. If this
is not your desired behavior be sure to set this attribute to a Git tag or
SHA hash to lock in your version.

## `web_server`

The HTTP web server front end to handle Gitorious traffic. Valid values are
`nginx` and `apache2`. The default is `nginx`.

**Note:** Currently on nginx has full support. Apache2 work is ongoing.

## `ssl/key`

The SSL private key to be used by the HTTP web server. This file is expected
to exist in the operating system's default location (i.e. `/etc/ssl/private`
under Debian flavors). The default is `ssl-cert-snakeoil.key` and should be
replaced when running in production (nobody wants to accept a self-signed
certificate in the wild).

## `ssl/cert`

The SSL public key to be used by the HTTP web server. This file is expected
to exist in the operating system's default location (i.e. `/etc/ssl/certs`
under Debian flavors). The default is `ssl-cert-snakeoil.pem` and should be
replaced when running in production.

## `app_user`

The unix account that will run the Gitorious web application. This will also
be the SSH account in the Git URL. The default is `git`.

## `app_base_dir`

The base path containing the Gitorious web application. The default is
`/srv/gitorious`.

**Note:** the rails application actually is installed in
`#{node[:gitorious][:app_base_dir]}/current`, corresponding to the capistrano
conventions.

## `git_base_dir`

The base path containing the Git repositories managed by Gitorious. The
default is `/var/git`.

## `rails_env`

The Rails environment mode under which Gitorious will operate. There shouldn't
be a need to override this value except for development or other
experimentation. The default is `production`.

**Note:** this value gets used when running the Rails application and
when calling all rake tasks.

## `rvm_gemset`

All gems for the Gitorious Rails application will be installed in this RVM
gemset. The default is `gitorious`.

**Note:** using bundler with `--deployment` proved less than successful so
we can use RVM to isolate gems instead in the meantime.

## `db/host`

The host that runs the MySQL server. The default is `localhost` which is currently
the only well-supported value. Work needs to be done to optionally handle a
database operating on another server instance.

## `db/database`

The MySQL database name, which will be created. The default is `gitorious`.

## `db/user`

The MySQL database user for Gitorious, which will be created. The default is
`gitor` which seems odd except MySQL usernames cannot exceed 8 characters.

## `db/password`

The MySQL user's password. The default is `gitorious`.

**Note:** This attribute should be set to ensure good application security.

## `host`

The virtual host name resolving to the Gitorious Rails application. This value
gets used in cookie names, web server configuration and other places. The
default is `gitorious.local` and should be customized for Gitorious to operate
properly.

**Note:** as described in the [Gitorious wiki](http://gitorious.org/gitorious/pages/ErrorMessages#The+specified+gitorious_host+is+reserved+in+Gitorious),
a value of `git` should be avoided as it is reserved. Too bad, since that's
usually a great first choice.

## `support_email`

Email address to the support for the Gitorious server. The default is
`support@gitorious.org` and should be customized.

## `notification_emails`

List of email addresses to send server errors to seperated by whitespace.
The default is an empty string.

## `public_mode`

Determines if Gitorious operates in a public mode (`true`) or in private
mode (`false`). The default is `true` (public mode).

## `only_admins_create`

Determines whether or not only site admins can create new projects. The
default is `false`.

## `admin/email`

The email address given to the `admin` which is used to initially log in.
A default admin user will be created to manage the Gitorious instance. The
default is `admin@gitorious.local` and this should be customized for any
emails to be properly delivered.

## `admin/password`

An initial password for the `admin` user which is used to initially log in.
The default is `admin`.

**Note:** This attribute should be set or immediately updated to ensure
good application security.

## `locale`

Sets the locale for Gitorious. Known values are `en`, `es`, `fr`, and
`pt-BR`. The default is `en`.

## `hide_http_clone_urls`

Determines whether or not HTTP clone URLs are hidden from the interface.
The default is `false`.

## `optional_tls/url`

The Git URL to the *action_mailer_optional_tls* rails plugin which is used
to support SMTP/TLS mail deliveries. The default is
[git://github.com/collectiveidea/action_mailer_optional_tls.git](git://github.com/collectiveidea/action_mailer_optional_tls.git).

## `mailer/delivery_methods`

Configures the delivery method for the Rails ActionMailer. For more details
regarding ActionMailer tuning, see the [Rails Guides](http://guides.rubyonrails.org/v2.3.8/action_mailer_basics.html#action-mailer-configuration).
The default is `smtp`.

## `smtp/tls`

Determines whether or not to require TLS when negotiating with the SMTP
server. The default is `false`.

## `smtp/address`

The SMTP server that will deliver mail from Gitorious. The default is
`smtp.example.com` which must be customized to ensure proper operation
of Gitorious.

## `smtp/port`

The port that the SMTP server listens to. The default will attempt to connect
on port 25.

**Note:** If SSL/TLS is used, then you will want to customize the port. For
example, Google's Gmail SMTP servers listen on port 587.

## `smtp/domain`

Allows the *action_mailer_optional_tls* rails plugin to set a domain which
is primarily used when talking to Google's Gmail servers. Please see
the plugin's [project page](https://github.com/collectiveidea/action_mailer_optional_tls)
for more details. The default is an empty string.

## `smtp/authentication`

The authentication method to use when connecting to the SMTP server. The
default is `plain`. To disable this attribute, set it to an empty string.

## `smtp/username`

The username to use when authenticating to the SMTP server. This will only
be used if set. The default is unset (an empty string).

## `smtp/password`

The password to use when authenticating to the SMTP server. This will only
be used if set. The default is unset (an empty string).

# Usage

# References

* [Gitorious code mainline](http://gitorious.org/gitorious/mainline)
* [Gitorious Ubuntu installation wiki](http://gitorious.org/gitorious/pages/UbuntuInstallation)
* [Christian Johansen's Ubuntu installation](http://cjohansen.no/en/ruby/setting_up_gitorious_on_your_own_server)
* [action_mailer_optional_tls plugin](https://github.com/collectiveidea/action_mailer_optional_tls)
* [Rubygems 1.6 issue](http://cjohansen.no/en/ruby/setting_up_gitorious_on_your_own_server#toc52631_11_3)
* [Rubygems 1.6 thread deprecation](http://www.ruby-forum.com/topic/1193619)
* [RVM project](http://rvm.beginrescueend.com/)

# License and Author

Author:: Fletcher Nichol (<fnichol@nichol.ca>)

Contributors:: Rodrigo Rosenfeld Rosas (<rr_rosas@yahoo.com.br>)

Copyright:: 2010, 2011, Fletcher Nichol

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
