# frozen_string_literal: true

module RedmineMailRecipient
  module ProjectsHelperPatch
    def mail_recipient_setting_tabs(tabs)
      action = {
        name: 'mail_recipient',
        controller: :mail_recipients,
        action: :update,
        partial: 'mail_recipients/show',
        label: :mail_recipient,
      }

      tabs << action if User.current.allowed_to?(action, @project)
      tabs
    end
  end

  module ProjectsHelperPatch4
    include ProjectsHelperPatch

    def self.included(base)
      base.class_eval do
        alias_method_chain(:project_settings_tabs, :mail_recipient)
      end
    end

    def project_settings_tabs_with_mail_recipient
      mail_recipient_setting_tabs(project_settings_tabs_without_mail_recipient)
    end
  end

  module ProjectsHelperPatch5
    include ProjectsHelperPatch

    def project_settings_tabs
      mail_recipient_setting_tabs(super)
    end
  end
end

if ActiveSupport::VERSION::MAJOR >= 5
  ProjectsHelper.prepend RedmineMailRecipient::ProjectsHelperPatch5
else
  ProjectsHelper.include RedmineMailRecipient::ProjectsHelperPatch4
end
