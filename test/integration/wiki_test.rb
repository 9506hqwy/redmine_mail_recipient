# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class WikiTest < Redmine::IntegrationTest
  include Redmine::I18n

  fixtures :email_addresses,
           :enabled_modules,
           :enumerations,
           :member_roles,
           :members,
           :projects,
           :roles,
           :user_preferences,
           :users,
           :watchers,
           :wiki_content_versions,
           :wiki_contents,
           :wiki_pages,
           :wikis

  def setup
    Setting.bcc_recipients = false
    Setting.notified_events = ['wiki_content_added', 'wiki_content_updated']
    Project.find(1).enable_module!(:mail_delivery_compat3)
    ActionMailer::Base.deliveries.clear
  end

  def test_wiki_content_added
    log_user('jsmith', 'jsmith')

    new_record(WikiContent) do
      put(
        '/projects/ecookbook/wiki/Wiki',
        params: {
          content: {
            text: "wiki content"
          }
        })
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 2, ActionMailer::Base.deliveries.last.to.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
  end

  def test_wiki_content_added_recipient_author
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'wiki_content_added'
    m.to = '@author'
    m.cc_except_to = true
    m.save!

    log_user('jsmith', 'jsmith')

    new_record(WikiContent) do
      put(
        '/projects/ecookbook/wiki/Wiki',
        params: {
          content: {
            text: "wiki content"
          }
        })
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries.last.to.length
    assert_equal 1, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_wiki_content_added_recipient_watchers
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'wiki_content_added'
    m.to = '@watchers'
    m.cc_except_to = true
    m.save!

    log_user('jsmith', 'jsmith')

    new_record(WikiContent) do
      put(
        '/projects/ecookbook/wiki/Wiki',
        params: {
          content: {
            text: "wiki content"
          }
        })
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 0, ActionMailer::Base.deliveries.last.to.length
    assert_equal 2, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.cc
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_wiki_content_updated
    log_user('jsmith', 'jsmith')

    put(
      '/projects/ecookbook/wiki/CookBook_documentation',
      params: {
        content: {
          text: "wiki content"
        }
      })

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 2, ActionMailer::Base.deliveries.last.to.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
  end

  def test_wiki_content_updated_recipient_author
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'wiki_content_updated'
    m.to = '@author'
    m.cc_except_to = true
    m.save!

    log_user('jsmith', 'jsmith')

    put(
      '/projects/ecookbook/wiki/CookBook_documentation',
      params: {
        content: {
          text: "wiki content"
        }
      })

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries.last.to.length
    assert_equal 1, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_wiki_content_updated_recipient_watchers
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'wiki_content_updated'
    m.to = '@watchers'
    m.cc_except_to = true
    m.save!

    log_user('jsmith', 'jsmith')

    put(
      '/projects/ecookbook/wiki/CookBook_documentation',
      params: {
        content: {
          text: "wiki content"
        }
      })

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 0, ActionMailer::Base.deliveries.last.to.length
    assert_equal 2, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.cc
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end
end