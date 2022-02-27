# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class MailRecipientTest < ActiveSupport::TestCase
  fixtures :groups_users,
           :issues,
           :journals,
           :projects,
           :trackers,
           :users,
           :watchers

  def test_create
    p = projects(:projects_001)
    t = trackers(:trackers_001)

    m = MailRecipient.new
    m.project = p
    m.tracker = t
    m.notifiable = 'a'
    m.to = 'to'
    m.to_except_cc = false
    m.cc = 'cc'
    m.cc_except_to = true
    m.save!

    m.reload
    assert_equal p.id, m.project_id
    assert_equal t.id, m.tracker_id
    assert_equal 'a', m.notifiable
    assert_equal 'to', m.to
    assert_not m.to_except_cc
    assert_equal 'cc', m.cc
    assert m.cc_except_to
  end

  def test_update_mail_headers_author
    m = MailRecipient.new
    m.to = '@author'

    u001 = users(:users_001)
    recipients = {
      '@author' => u001,
    }

    h = {}
    users = User.all
    m.update_mail_headers(h, users, recipients)

    assert_equal 1, h[:to].length
    assert_equal 0, h[:cc].length
    assert_include u001, h[:to]
  end

  def test_update_mail_headers_commenter
    m = MailRecipient.new
    m.to = '@commenter'
    m.cc_except_to = true

    u001 = users(:users_001)
    recipients = {
      '@commenter' => u001,
    }

    h = {}
    users = User.all
    m.update_mail_headers(h, users, recipients)

    assert_equal 1, h[:to].length
    assert_equal 8, h[:cc].length
    assert_include u001, h[:to]
  end

  def test_update_mail_headers_assigned_to
    m = MailRecipient.new
    m.cc = '@assigned_to'

    u001 = users(:users_001)
    recipients = {
      '@assigned_to' => u001,
    }

    h = {}
    users = User.all
    m.update_mail_headers(h, users, recipients)

    assert_equal 0, h[:to].length
    assert_equal 1, h[:cc].length
    assert_include u001, h[:cc]
  end

  def test_update_mail_headers_previous_assignee
    m = MailRecipient.new
    m.cc = '@previous_assignee'
    m.to_except_cc = true

    u001 = users(:users_001)
    recipients = {
      '@previous_assignee' => u001,
    }

    h = {}
    users = User.all
    m.update_mail_headers(h, users, recipients)

    assert_equal 8, h[:to].length
    assert_equal 1, h[:cc].length
    assert_include u001, h[:cc]
  end

  def test_update_mail_headers_watchers
    m = MailRecipient.new
    m.to = '@author'
    m.cc = '@watchers'

    u001 = users(:users_001)
    u003 = users(:users_003)
    recipients = {
      '@author' => u001,
      '@watchers' => issues(:issues_002).notified_watchers,
    }

    h = {}
    users = User.all
    m.update_mail_headers(h, users, recipients)

    assert_equal 1, h[:to].length
    assert_equal 1, h[:cc].length
    assert_include u001, h[:to]
    assert_include u003, h[:cc]
  end

  def test_update_mail_headers_commenters
    m = MailRecipient.new
    m.to = '@author'
    m.cc = '@commenters'

    u001 = users(:users_001)
    u002 = users(:users_002)
    recipients = {
      '@author' => u001,
      '@commenters' => Journal.where(journalized_id: 1, journalized_type: 'Issue').map { |j| j.user },
    }

    h = {}
    users = User.all
    m.update_mail_headers(h, users, recipients)

    assert_equal 1, h[:to].length
    assert_equal 1, h[:cc].length
    assert_include u001, h[:to]
    assert_include u002, h[:cc]
  end

  def test_update_mail_headers_group
    m = MailRecipient.new
    m.to = '@assigned_to'

    u008 = users(:users_008)
    recipients = {
      '@assigned_to' => Group.find(10),
    }

    h = {}
    users = User.all
    m.update_mail_headers(h, users, recipients)

    assert_equal 1, h[:to].length
    assert_equal 0, h[:cc].length
    assert_include u008, h[:to]
  end
end
