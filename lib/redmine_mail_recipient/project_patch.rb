# frozen_string_literal: true

module RedmineMailRecipient
  module ProjectPatch
    def self.prepended(base)
      base.class_eval do
        has_many :mail_recipient, dependent: :destroy
      end
    end
  end
end

Project.prepend RedmineMailRecipient::ProjectPatch
