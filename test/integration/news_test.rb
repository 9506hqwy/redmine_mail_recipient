# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class NewssTest < Redmine::IntegrationTest
  include Redmine::I18n

  fixtures :comments,
           :email_addresses,
           :enabled_modules,
           :enumerations,
           :member_roles,
           :members,
           :news,
           :projects,
           :roles,
           :user_preferences,
           :users

  def setup
    Setting.bcc_recipients = false if Setting.available_settings.key?('bcc_recipients')
    Setting.notified_events = ['news_added', 'news_comment_added']
    Project.find(1).enable_module!(:mail_delivery_compat3)
    ActionMailer::Base.deliveries.clear
  end

  def test_news_add
    log_user('jsmith', 'jsmith')

    new_record(News) do
      post(
        '/projects/ecookbook/news',
        params: {
          news: {
            title: 'test',
            description: 'test',
            summary: "test",
          }
        })
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 2, ActionMailer::Base.deliveries.last.to.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
  end

  def test_news_add_recipient_author
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'news_added'
    m.to = '@author'
    m.cc_except_to = true
    m.save!

    log_user('jsmith', 'jsmith')

    new_record(News) do
      post(
        '/projects/ecookbook/news',
        params: {
          news: {
            title: 'test',
            description: 'test',
            summary: "test",
          }
        })
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries.last.to.length
    assert_equal 1, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_news_add_recipient_watchers
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'news_added'
    m.to = '@watchers'
    m.cc_except_to = true
    m.save!

    log_user('jsmith', 'jsmith')

    new_record(News) do
      post(
        '/projects/ecookbook/news',
        params: {
          news: {
            title: 'test',
            description: 'test',
            summary: "test",
          }
        })
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 0, ActionMailer::Base.deliveries.last.to.length
    assert_equal 2, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.cc
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_news_comment_add
    log_user('jsmith', 'jsmith')

    post(
      '/news/1/comments',
      params: {
        comment: {
          comments: "test",
        },
      })

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 2, ActionMailer::Base.deliveries.last.to.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
  end

  def test_news_comment_add_recipient_author
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'news_comment_added'
    m.to = '@author'
    m.cc_except_to = true
    m.save!

    log_user('jsmith', 'jsmith')

    post(
      '/news/1/comments',
      params: {
        comment: {
          comments: "test",
        },
      })

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries.last.to.length
    assert_equal 1, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_news_comment_add_recipient_watchers
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'news_comment_added'
    m.to = '@watchers'
    m.cc_except_to = true
    m.save!

    log_user('jsmith', 'jsmith')

    post(
      '/news/1/comments',
      params: {
        comment: {
          comments: "test",
        },
      })

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 0, ActionMailer::Base.deliveries.last.to.length
    assert_equal 2, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.cc
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end
end
