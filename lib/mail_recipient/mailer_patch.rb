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
      end

      nil
    end

    def mail_recipient_find_setting_by_project(project)
      return nil unless project

      if Redmine::VERSION::MAJOR >= 4 && !project.module_enabled?(:mail_delivery_compat3)
        return nil
      end

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
      else
        nil
      end
    end

    def mail_recipient_classify_recipients(headers, setting)
      users = headers.fetch(:to, []) | headers.fetch(:cc, [])
      return if users.blank?

      recipients = {
        '@author' => @author,
      }

      if @journal # issue_edit
        recipients['@author'] = @issue.author
        recipients['@assigned_to'] = @issue.assigned_to if @issue.assigned_to
        if Redmine::VERSION::MAJOR >= 4 && @issue.previous_assignee
          # FIXME: previous_assignee does not work.
          recipients['@previous_assignee'] = @issue.previous_assignee
        end
        recipients['@watchers'] = @journal.notified_watchers
        recipients['@commenter'] = @author
        recipients['@commenters'] = Journal
          .where(journalized_id: @issue.id, journalized_type: 'Issue')
          .map { |j| j.user }
          .uniq
      elsif @issue # issue_add
        recipients['@assigned_to'] = @issue.assigned_to if @issue.assigned_to
        recipients['@watchers'] = @issue.notified_watchers
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
