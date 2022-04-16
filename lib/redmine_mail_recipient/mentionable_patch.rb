# frozen_string_literal: true

module RedmineMailRecipient
  module MentionablePatch
    def mail_recipient_parse_mentions_for_issue_add
      self.mentionable_attributes.each do |attr|
        mail_recipient_get_mentioned_users(self, nil, send(attr))
      end
    end

    def mail_recipient_parse_mentions_for_issue_edit
      details = self.details.select {|d| d.property == 'attr' && Issue.mentionable_attributes.include?(d.prop_key) }
      details.each do |detail|
        old_content = detail.old_value
        new_content = self.journalized.send(detail.prop_key)
        mail_recipient_get_mentioned_users(self.journalized, old_content, new_content)
      end

      self.mentionable_attributes.each do |attr|
        mail_recipient_get_mentioned_users(self, nil, send(attr))
      end
    end

    def mail_recipient_parse_mentions_for_wiki_content
      self.mentionable_attributes.each do |attr|
        if self.version == 1
          mail_recipient_get_mentioned_users(self, nil, send(attr))
        else
          current = self.versions.find_by(version: self.version)
          previous = current.previous
          mail_recipient_get_mentioned_users(self, previous.text, send(attr))
        end
      end
    end

    private

    def mail_recipient_get_mentioned_users(target, old_content, new_content)
      target.mentioned_users = []

      previous_matches =  scan_for_mentioned_users(old_content)
      current_matches = scan_for_mentioned_users(new_content)
      new_matches = (current_matches - previous_matches).flatten

      if new_matches.any?
        target.mentioned_users = User.visible.active.where(login: new_matches)
      end
    end
  end
end

if Redmine::VERSION::MAJOR >= 5
  Redmine::Acts::Mentionable.include RedmineMailRecipient::MentionablePatch
end
