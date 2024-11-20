# frozen_string_literal: true

class MailRecipient < RedmineMailRecipient::Utils::ModelBase
  belongs_to :project
  belongs_to :tracker

  validates :project, presence: true
  validates :notifiable, presence: true

  def update_mail_headers(headers, users, recipients)
    to_users = users & notifiable_users(to, recipients)
    cc_users = users & notifiable_users(cc, recipients)

    if to_except_cc
      headers[:to] = users - cc_users
    else
      headers[:to] = to_users
    end

    if cc_except_to
      headers[:cc] = users - to_users
    elsif to_except_cc
      headers[:cc] = cc_users
    else
      headers[:cc] = cc_users - to_users
    end
  end

  private

  def notifiable_users(keys, recipients)
    users = []

    (keys || '').split(',').collect { |k| k.strip }.each do |key|
      if recipients.key? key
        case key
        when '@author', '@commenter'
          users |= [recipients[key]]
        when '@assigned_to', '@previous_assignee'
          users |= recipients[key].is_a?(Group)? recipients[key].users : [recipients[key]]
        when '@watchers', '@commenters', '@mentioned'
          users |= recipients[key]
        end
      end
    end

    users
  end
end
