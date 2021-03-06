# frozen_string_literal: true

module RedmineMailRecipient
  module MailerPatch
    private

    def mail_recipient_find_project_by_container
      if @issue
        return @issue.project
      elsif @document
        return @document.project
      elsif @attachments
        return @attachments.first.container.project
      elsif @news
        return @news.project
      elsif @message && @message.is_a?(Message)
        return @message.project
      elsif @wiki_content
        return @wiki_content.project
      elsif @text && @project
        # for redmine_wiki_extensions
        return @project
      end

      nil
    end

    def mail_recipient_find_setting_by_project(project)
      return nil unless project
      return nil unless project.module_enabled?(:mail_recipient)
      return nil unless mail_recipient_notifiable

      tracker_id = @issue.tracker_id if @issue
      setting = project.mail_recipient
        .where(notifiable: mail_recipient_notifiable, tracker_id: tracker_id)
        .first
      if setting.blank? && @issue
        setting = project.mail_recipient
          .where(notifiable: mail_recipient_notifiable, tracker_id: nil)
          .first
      end

      setting
    end

    def mail_recipient_notifiable
      if @journal
        'issue_updated'
      elsif @issue
        'issue_added'
      elsif @document
        'document_added'
      elsif @attachments
        container = @attachments.first.container
        if container.is_a?(Document)
          'document_added'
        else
          'file_added'
        end
      elsif @comment
        'news_comment_added'
      elsif @news
        'news_added'
      elsif @message && @message.is_a?(Message)
        'message_posted'
      elsif @wiki_content
        if @wiki_content.version == 1
          'wiki_content_added'
        else
          'wiki_content_updated'
        end
      elsif @text && @project
        # for redmine_wiki_extensions
        'wiki_comment_added'
      else
        nil
      end
    end

    def mail_recipient_classify_recipients(headers, setting)
      users = []
      [:to, :cc, :bcc].each do |key|
        u = headers.fetch(key, [])
        users |= u.is_a?(Enumerable) ? u : [u]
      end
      return if users.blank?

      recipients = {
        '@author' => @author,
      }

      if @journal # issue_edit
        recipients['@author'] = @issue.author
        recipients['@assigned_to'] = @issue.assigned_to if @issue.assigned_to
        assigned_to_value = @journal.detail_for_attribute('assigned_to_id')
        if assigned_to_value.present?
          recipients['@previous_assignee'] = Principal.find_by_id(assigned_to_value.old_value)
        end
        recipients['@watchers'] = @journal.notified_watchers
        recipients['@commenter'] = @author
        recipients['@commenters'] = Journal
          .where(journalized_id: @issue.id, journalized_type: 'Issue')
          .map { |j| j.user }
          .uniq
        if mail_recipient_enable_mention
          @journal.mail_recipient_parse_mentions_for_issue_edit
          recipients['@mentioned'] = @journal.notified_mentions | @journal.journalized.notified_mentions
        end
      elsif @issue # issue_add
        recipients['@assigned_to'] = @issue.assigned_to if @issue.assigned_to
        recipients['@watchers'] = @issue.notified_watchers
        if mail_recipient_enable_mention
          @issue.mail_recipient_parse_mentions_for_issue_add
          recipients['@mentioned'] = @issue.notified_mentions
        end
      elsif @document # document_added
        # PASS
      elsif @attachments # attachments_added
        # PASS
      elsif @comment # news_comment_added
        recipients['@watchers'] = @news.notified_watchers
      elsif @news # news_added
        recipients['@watchers'] = @news.notified_watchers_for_added_news
      elsif @message && @message.is_a?(Message) # message_posted
        recipients['@watchers'] = @message.root.notified_watchers | @message.board.notified_watchers
      elsif @wiki_content # wiki_content_added / wiki_content_updated
        recipients['@watchers'] = @wiki_content.page.wiki.notified_watchers | @wiki_content.page.notified_watchers
        if mail_recipient_enable_mention
          @wiki_content.mail_recipient_parse_mentions_for_wiki_content
          recipients['@mentioned'] = @wiki_content.notified_mentions
        end
      elsif @text && @project
        # for redmine_wiki_extensions
        # PASS
      end

      setting.update_mail_headers(headers, users, recipients)
    end

    def mail_recipient_update_header(headers)
      project = mail_recipient_find_project_by_container
      setting = mail_recipient_find_setting_by_project(project)
      if setting
        if @user && @user.is_a?(Enumerable)
          @user = nil
        end

        mail_recipient_classify_recipients(headers, setting)
      end
    end

    def mail_recipient_enable_mention
      Redmine::VERSION::MAJOR >= 5
    end
  end

  module MailerPatch4
    include MailerPatch

    def self.included(base)
      base.class_eval do
        alias_method_chain(:mail, :mail_recipient)
      end
    end

    def mail_with_mail_recipient(headers={}, &block)
      mail_recipient_update_header(headers)
      mail_without_mail_recipient(headers, &block)
    end
  end

  module MailerPatch5
    include MailerPatch

    def mail(headers={}, &block)
      mail_recipient_update_header(headers)
      super
    end
  end
end

if ActiveSupport::VERSION::MAJOR >= 5
  Mailer.prepend RedmineMailRecipient::MailerPatch5
else
  Mailer.include RedmineMailRecipient::MailerPatch4
end
