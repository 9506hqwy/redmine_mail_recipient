# frozen_string_literal: true

module RedmineMailRecipient
  module ProjectsHelperPatch
    def project_settings_tabs
      action = {
        name: 'mail_recipient',
        controller: :mail_recipients,
        action: :update,
        partial: 'mail_recipients/show',
        label: :mail_recipient,
      }

      tabs = super
      tabs << action if User.current.allowed_to?(action, @project)
      tabs
    end

    def mail_recipient_wiki_extensions_enable?
      plugin = Redmine::Plugin.find(:redmine_wiki_extensions)
      version = plugin.version.split('.').map(&:to_i)
      ([0, 9, 3] <=> version) <= 0
    rescue Redmine::PluginNotFound
      return false
    end
  end
end

Rails.application.config.after_initialize do
  ProjectsController.send(:helper, RedmineMailRecipient::ProjectsHelperPatch)
end
