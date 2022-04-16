# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class DocumentsTest < Redmine::IntegrationTest
  include ActiveJob::TestHelper
  include Redmine::I18n

  fixtures :documents,
           :email_addresses,
           :enabled_modules,
           :enumerations,
           :member_roles,
           :members,
           :projects,
           :roles,
           :user_preferences,
           :users

  def setup
    Setting.bcc_recipients = false if Setting.available_settings.key?('bcc_recipients')
    Setting.notified_events = ['document_added']
    ActionMailer::Base.deliveries.clear
  end

  def test_document_add
    skip unless Redmine::VERSION::MAJOR >= 4

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      new_record(Document) do
        post(
          '/projects/ecookbook/documents',
          params: {
            document: {
              title: 'test',
              description: 'test',
              category_id: "1",
            }
          })
      end
    end

    assert_equal 2, ActionMailer::Base.deliveries.length
    assert_equal 1, ActionMailer::Base.deliveries[0].to.length
    assert_equal 1, ActionMailer::Base.deliveries[1].to.length

    to = ActionMailer::Base.deliveries.map(&:to).flatten

    assert_include 'jsmith@somenet.foo', to
    assert_include 'dlopper@somenet.foo', to
  end

  def test_document_add_compat3
    Project.find(1).enable_module!(:mail_delivery_compat3)

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      new_record(Document) do
        post(
          '/projects/ecookbook/documents',
          params: {
            document: {
              title: 'test',
              description: 'test',
              category_id: "1",
            }
          })
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal 2, ActionMailer::Base.deliveries.last.to.length
    assert_include 'jsmith@somenet.foo', ActionMailer::Base.deliveries.last.to
    assert_include 'dlopper@somenet.foo', ActionMailer::Base.deliveries.last.to
  end

  def test_document_add_recipient
    skip unless Redmine::VERSION::MAJOR >= 4

    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'document_added'
    m.to = '@author'
    m.cc_except_to = true
    m.save!

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      new_record(Document) do
        post(
          '/projects/ecookbook/documents',
          params: {
            document: {
              title: 'test',
              description: 'test',
              category_id: "1",
            }
          })
      end
    end

    assert_equal 2, ActionMailer::Base.deliveries.length

    m1 = ActionMailer::Base.deliveries.find { |m| m.to.present? }
    assert_equal 1, m1.to.length
    assert_include 'jsmith@somenet.foo', m1.to

    m2 = ActionMailer::Base.deliveries.find {|m| m.cc.present? }
    assert_equal 1, m2.cc.length
    assert_include 'dlopper@somenet.foo', m2.cc
  end

  def test_document_add_recipient_compat3
    Project.find(1).enable_module!(:mail_delivery_compat3)
    Project.find(1).enable_module!(:mail_recipient)

    m = MailRecipient.new
    m.project_id = 1
    m.notifiable = 'document_added'
    m.to = '@author'
    m.cc_except_to = true
    m.save!

    log_user('jsmith', 'jsmith')

    perform_enqueued_jobs do
      new_record(Document) do
        post(
          '/projects/ecookbook/documents',
          params: {
            document: {
              title: 'test',
              description: 'test',
              category_id: "1",
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
end
