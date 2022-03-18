# frozen_string_literal: true

require_dependency 'mail_recipient/mailer_patch'
require_dependency 'mail_recipient/project_patch'
require_dependency 'mail_recipient/projects_helper_patch'
require_dependency 'mail_recipient/tracker_patch'
require_dependency 'mail_recipient/utils'

Redmine::Plugin.register :redmine_mail_recipient do
  name 'Redmine Mail Recipient plugin'
  author '9506hqwy'
  description 'This is a mail recipient plugin for Redmine'
  version '0.2.0'
  url 'https://github.com/9506hqwy/redmine_mail_recipient'
  author_url 'https://github.com/9506hqwy'

  if Redmine::VERSION::MAJOR >= 4
    requires_redmine_plugin :redmine_mail_delivery_compat3, version_or_higher: '0.1.0'
  end

  project_module :mail_recipient do
    permission :edit_mail_recipient, { mail_recipients: [:update] }
  end
end
