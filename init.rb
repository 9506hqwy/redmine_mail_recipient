# frozen_string_literal: true

basedir = File.expand_path('../lib', __FILE__)
libraries =
  [
    'redmine_mail_recipient/mailer_patch',
    'redmine_mail_recipient/mentionable_patch',
    'redmine_mail_recipient/project_patch',
    'redmine_mail_recipient/projects_helper_patch',
    'redmine_mail_recipient/tracker_patch',
    'redmine_mail_recipient/utils',
  ]

libraries.each do |library|
  require_dependency File.expand_path(library, basedir)
end

Redmine::Plugin.register :redmine_mail_recipient do
  name 'Redmine Mail Recipient plugin'
  author '9506hqwy'
  description 'This is a mail recipient plugin for Redmine'
  version '0.3.0'
  url 'https://github.com/9506hqwy/redmine_mail_recipient'
  author_url 'https://github.com/9506hqwy'

  project_module :mail_recipient do
    permission :edit_mail_recipient, { mail_recipients: [:update] }
  end
end
