# frozen_string_literal: true

module RedmineMailRecipient
  module TrackerPatch
    def self.prepended(base)
      base.class_eval do
        has_many :mail_recipient, dependent: :destroy
      end
    end
  end
end

Tracker.prepend RedmineMailRecipient::TrackerPatch
