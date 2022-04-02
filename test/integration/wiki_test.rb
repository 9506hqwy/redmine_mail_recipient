# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class WikiTest < Redmine::IntegrationTest
  include ActiveJob::TestHelper
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
    Setting.bcc_recipients = false if Setting.available_settings.key?('bcc_recipients')
    Setting.notified_events = ['wiki_content_added', 'wiki_content_updated', 'wiki_comment_added']
    Project.find(1).enable_module!(:mail_delivery_compat3)
    ActionMailer::Base.deliveries.clear
  end

  def test_wiki_content_added
    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      new_record(WikiContent) do
        put(
          '/projects/ecookbook/wiki/Wiki',
          params: {
            content: {
              text: "wiki content"
            }
          })
      end
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

    perform_enqueued_jobs do
      new_record(WikiContent) do
        put(
          '/projects/ecookbook/wiki/Wiki',
          params: {
            content: {
              text: "wiki content"
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

  def test_wiki_content_added_recipient_watchers
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'wiki_content_added'
    m.to = '@watchers'
    m.cc_except_to = true
    m.save!

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      new_record(WikiContent) do
        put(
          '/projects/ecookbook/wiki/Wiki',
          params: {
            content: {
              text: "wiki content"
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

  def test_wiki_content_added_recipient_mentioned
    skip unless Redmine::VERSION::MAJOR >= 5

    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'wiki_content_added'
    m.to = '@mentioned'
    m.save!

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      new_record(WikiContent) do
        put(
          '/projects/ecookbook/wiki/Wiki',
          params: {
            content: {
              text: "@admin"
            }
          })
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries.last.to.length
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_equal 0, ActionMailer::Base.deliveries.last.cc.length
  end

  def test_wiki_content_updated
    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      put(
        '/projects/ecookbook/wiki/CookBook_documentation',
        params: {
          content: {
            text: "wiki content"
          }
        })
    end

    expect = 0
    expect += 1 if default_watcher_added

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 2, ActionMailer::Base.deliveries.last.to.length
    assert_equal expect, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.cc if default_watcher_added
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

    perform_enqueued_jobs do
      put(
        '/projects/ecookbook/wiki/CookBook_documentation',
        params: {
          content: {
            text: "wiki content"
          }
        })
    end

    expect = 1
    expect += 1 if default_watcher_added

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries.last.to.length
    assert_equal expect, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.cc
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.cc if default_watcher_added
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

    perform_enqueued_jobs do
      put(
        '/projects/ecookbook/wiki/CookBook_documentation',
        params: {
          content: {
            text: "wiki content"
          }
        })
    end

    expect = 0
    expect += 1 if default_watcher_added

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal expect, ActionMailer::Base.deliveries.last.to.length
    assert_equal 2, ActionMailer::Base.deliveries.last.cc.length
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.to if default_watcher_added
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.cc
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.cc
  end

  def test_wiki_content_updated_recipient_mentioned
    skip unless Redmine::VERSION::MAJOR >= 5

    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'wiki_content_updated'
    m.to = '@mentioned'
    m.save!

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      put(
        '/projects/ecookbook/wiki/CookBook_documentation',
        params: {
          content: {
            text: "@admin"
          }
        })
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries.last.to.length
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_equal 0, ActionMailer::Base.deliveries.last.cc.length
  end

  def test_wiki_comment_added
    skip unless Redmine::Plugin.installed?(:redmine_wiki_extensions)

    plugin = Redmine::Plugin.find(:redmine_wiki_extensions)
    version = plugin.version.split('.').map(&:to_i)
    skip unless ([0, 9, 3] <=> version) <= 0

    Project.find(1).enable_module!(:wiki_extensions)
    Role.find(1).add_permission!(:add_wiki_comment)

    page = wiki_pages(:wiki_pages_001)
    page.add_watcher(users(:users_001)) unless default_watcher_added

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      post(
        '/projects/ecookbook/wiki_extensions/add_comment',
        params: {
          wiki_page_id: page.id,
          comment: 'test comment',
        })
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 3, ActionMailer::Base.deliveries.last.to.length
    assert_include 'admin@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
  end

  def test_wiki_comment_added_author
    skip unless Redmine::Plugin.installed?(:redmine_wiki_extensions)

    plugin = Redmine::Plugin.find(:redmine_wiki_extensions)
    version = plugin.version.split('.').map(&:to_i)
    skip unless ([0, 9, 3] <=> version) <= 0

    Project.find(1).enable_module!(:mail_recipient)
    Project.find(1).enable_module!(:wiki_extensions)
    Role.find(1).add_permission!(:add_wiki_comment)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'wiki_comment_added'
    m.to = '@author'
    m.save!

    page = wiki_pages(:wiki_pages_001)
    page.add_watcher(users(:users_001)) unless default_watcher_added

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      post(
        '/projects/ecookbook/wiki_extensions/add_comment',
        params: {
          wiki_page_id: page.id,
          comment: 'test comment',
        })
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries.last.to.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
  end

  private

  def default_watcher_added
    return true if Redmine::VERSION.revision.to_i >= 21016
    return true if Redmine::VERSION::MAJOR >= 5

    (RedMica::VERSION::ARRAY[0..1] <=> [1, 3]) >= 0
  rescue
    false
  end
end
