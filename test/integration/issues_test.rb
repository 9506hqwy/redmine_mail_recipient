# frozen_string_literal: true

require 'test_after_commit' if ActiveRecord::VERSION::MAJOR < 5
require File.expand_path('../../test_helper', __FILE__)

class IssuesTest < Redmine::IntegrationTest
  include ActiveJob::TestHelper
  include Redmine::I18n

  fixtures :email_addresses,
           :enabled_modules,
           :enumerations,
           :issues,
           :issue_categories,
           :issue_statuses,
           :journal_details,
           :journals,
           :member_roles,
           :members,
           :projects,
           :projects_trackers,
           :roles,
           :user_preferences,
           :users,
           :trackers,
           :versions,
           :watchers

  def setup
    Setting.bcc_recipients = false if Setting.available_settings.key?('bcc_recipients')
    Setting.notified_events = ['issue_added', 'issue_updated']
    ActionMailer::Base.deliveries.clear
  end

  def test_issue_add_compat3
    Project.find(1).enable_module!(:mail_delivery_compat3)

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      new_record(Issue) do
        post(
          '/projects/ecookbook/issues',
          params: {
            issue: {
              tracker_id: '1',
              start_date: '2000-01-01',
              priority_id: "5",
              subject: "test issue",
            }
          })
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 2, ActionMailer::Base.deliveries.last.to.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
  end

  def test_issue_add_recipient_author_compat3
    Project.find(1).enable_module!(:mail_delivery_compat3)
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'issue_added'
    m.to = '@author'
    m.cc_except_to = true
    m.save!

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      new_record(Issue) do
        post(
          '/projects/ecookbook/issues',
          params: {
            issue: {
              tracker_id: '1',
              start_date: '2000-01-01',
              priority_id: "5",
              subject: "test issue",
            }
          })
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries.last.to.length
    assert_equal 1, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_issue_add_recipient_assigned_to_compat3
    Project.find(1).enable_module!(:mail_delivery_compat3)
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'issue_added'
    m.to = '@assigned_to'
    m.cc_except_to = true
    m.save!

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      new_record(Issue) do
        post(
          '/projects/ecookbook/issues',
          params: {
            issue: {
              tracker_id: '1',
              start_date: '2000-01-01',
              priority_id: "5",
              assigned_to_id: 3,
              subject: "test issue",
            }
          })
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries.last.to.length
    assert_equal 1, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_issue_add_recipient_watchers_compat3
    Project.find(1).enable_module!(:mail_delivery_compat3)
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'issue_added'
    m.to = '@watchers'
    m.cc_except_to = true
    m.save!

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      new_record(Issue) do
        post(
          '/projects/ecookbook/issues',
          params: {
            issue: {
              tracker_id: '1',
              start_date: '2000-01-01',
              priority_id: "5",
              subject: "test issue",
            }
          })
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 0, ActionMailer::Base.deliveries.last.to.length
    assert_equal 2, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.cc
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_issue_add_recipient_mentioned_compat3
    skip unless Redmine::VERSION::MAJOR >= 5

    Project.find(1).enable_module!(:mail_delivery_compat3)
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'issue_added'
    m.to = '@mentioned'
    m.save!

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      new_record(Issue) do
        post(
          '/projects/ecookbook/issues',
          params: {
            issue: {
              tracker_id: '1',
              start_date: '2000-01-01',
              priority_id: "5",
              subject: "test issue",
              description: '@admin',
            }
          })
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries.last.to.length
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_equal 0, ActionMailer::Base.deliveries.last.cc.length
  end

  def test_issue_edit_compat3
    Project.find(1).enable_module!(:mail_delivery_compat3)

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      put_issue_edit do
        put(
          '/issues/2',
          params: {
            issue: {
              subject: "test issue",
            }
          })
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 2, ActionMailer::Base.deliveries.last.to.length
    assert_equal 1, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_issue_edit_recipient_author_compat3
    Project.find(1).enable_module!(:mail_delivery_compat3)
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'issue_updated'
    m.to = '@author'
    m.cc_except_to = true
    m.save!

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      put_issue_edit do
        put(
          '/issues/2',
          params: {
            issue: {
              subject: "test issue",
            }
          })
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries.last.to.length
    assert_equal 2, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.cc
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_issue_edit_recipient_assigned_to_compat3
    Project.find(1).enable_module!(:mail_delivery_compat3)
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'issue_updated'
    m.to = '@assigned_to'
    m.cc_except_to = true
    m.save!

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      put_issue_edit do
        put(
          '/issues/2',
          params: {
            issue: {
              subject: "test issue",
            }
          })
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries.last.to.length
    assert_equal 2, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.cc
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_issue_edit_recipient_previous_assignee_compat3
    Project.find(1).enable_module!(:mail_delivery_compat3)
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'issue_updated'
    m.to = '@previous_assignee'
    m.cc_except_to = true
    m.save!

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      put_issue_edit do
        put(
          '/issues/2',
          params: {
            issue: {
              assigned_to_id: 2,
            }
          })
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries.last.to.length
    assert_equal 2, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.cc
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_issue_edit_recipient_watchers_compat3
    Project.find(1).enable_module!(:mail_delivery_compat3)
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'issue_updated'
    m.to = '@watchers'
    m.cc_except_to = true
    m.save!

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      put_issue_edit do
        put(
          '/issues/2',
          params: {
            issue: {
              subject: "test issue",
            }
          })
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 2, ActionMailer::Base.deliveries.last.to.length
    assert_equal 1, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_issue_edit_recipient_commenter_compat3
    Project.find(1).enable_module!(:mail_delivery_compat3)
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'issue_updated'
    m.to = '@commenter'
    m.cc_except_to = true
    m.save!

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      put_issue_edit do
        put(
          '/issues/2',
          params: {
            issue: {
              subject: "test issue",
            }
          })
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries.last.to.length
    assert_equal 2, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.cc
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_issue_edit_recipient_commenters_compat3
    Project.find(1).enable_module!(:mail_delivery_compat3)
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'issue_updated'
    m.to = '@commenters'
    m.cc_except_to = true
    m.save!

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      put_issue_edit do
        put(
          '/issues/2',
          params: {
            issue: {
              subject: "test issue",
            }
          })
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries.last.to.length
    assert_equal 2, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.cc
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_issue_edit_recipient_mentioned_description_compat3
    skip unless Redmine::VERSION::MAJOR >= 5

    Project.find(1).enable_module!(:mail_delivery_compat3)
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'issue_updated'
    m.to = '@mentioned'
    m.save!

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      put_issue_edit do
        put(
          '/issues/2',
          params: {
            issue: {
              subject: "test issue",
              description: '@admin',
            }
          })
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries.last.to.length
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_equal 0, ActionMailer::Base.deliveries.last.cc.length
  end

  def test_issue_edit_recipient_mentioned_notes_compat3
    skip unless Redmine::VERSION::MAJOR >= 5

    Project.find(1).enable_module!(:mail_delivery_compat3)
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'issue_updated'
    m.to = '@mentioned'
    m.save!

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      put_issue_edit do
        put(
          '/issues/2',
          params: {
            issue: {
              subject: "test issue",
              notes: '@admin',
            }
          })
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries.last.to.length
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_equal 0, ActionMailer::Base.deliveries.last.cc.length
  end

  def put_issue_edit(&block)
    if ActiveRecord::VERSION::MAJOR >= 5
      yield
    else
      TestAfterCommit.with_commits(true, &block)
    end
  end
end
