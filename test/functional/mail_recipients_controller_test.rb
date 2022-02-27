# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

# user:2   ----->  project:1
#            role:1
#          ----->  project:2
#            role:2
#          ----->  project:5  ----->  mail_recipient:1
#            role:1

class MailRecipientsControllerTest < Redmine::ControllerTest
  include Redmine::I18n

  fixtures :member_roles,
           :members,
           :projects,
           :roles,
           :trackers,
           :users,
           :mail_recipients

  def setup
    @request.session[:user_id] = 2

    role = Role.find(1)
    role.add_permission! :edit_mail_recipient
  end

  def test_update_create
    project = Project.find(1)
    project.enable_module!(:mail_recipient)

    put :update, params: {
      project_id: project.id,
      mail_recipient_tracker_id: '1',
      mail_recipient_notifiable: 'a',
      mail_recipient_to: 'b',
      # mail_recipient_to_except_cc: true,
      mail_recipient_cc: '',
      mail_recipient_cc_except_to: true,
    }

    assert_redirected_to "/projects/#{project.identifier}/settings/mail_recipient"
    assert_not_nil flash[:notice]
    assert_nil flash[:error]

    project.reload
    m = project.mail_recipient.find { |m| m.tracker_id == 1 && m.notifiable == 'a' }
    assert_equal 'b', m.to
    assert_not m.to_except_cc
    assert_equal '', m.cc
    assert m.cc_except_to
  end

  def test_update_update
    project = Project.find(5)
    project.enable_module!(:mail_recipient)

    put :update, params: {
      project_id: project.id,
      mail_recipient_tracker_id: '2',
      mail_recipient_notifiable: 'd',
      mail_recipient_to: '',
      mail_recipient_to_except_cc: true,
      mail_recipient_cc: 'c',
      # mail_recipient_cc_except_to: true,
    }

    assert_redirected_to "/projects/#{project.identifier}/settings/mail_recipient"
    assert_not_nil flash[:notice]
    assert_nil flash[:error]

    project.reload
    m = project.mail_recipient.find { |m| m.tracker_id == 2 && m.notifiable == 'd' }
    assert_equal '', m.to
    assert m.to_except_cc
    assert_equal 'c', m.cc
    assert_not m.cc_except_to
  end

  def test_update_destroy
    project = Project.find(5)
    project.enable_module!(:mail_recipient)

    put :update, params: {
      project_id: project.id,
      mail_recipient_tracker_id: '2',
      mail_recipient_notifiable: 'a',
      mail_recipient_to: '',
      # mail_recipient_to_except_cc: true,
      mail_recipient_cc: '',
      # mail_recipient_cc_except_to: true,
    }

    assert_redirected_to "/projects/#{project.identifier}/settings/mail_recipient"
    assert_not_nil flash[:notice]
    assert_nil flash[:error]

    project.reload
    m = project.mail_recipient.find { |m| m.tracker_id == 2 && m.notifiable == 'a' }
    assert_nil m
  end

  def test_update_none
    project = Project.find(1)
    project.enable_module!(:mail_recipient)

    put :update, params: {
      project_id: project.id,
      mail_recipient_tracker_id: '1',
      mail_recipient_notifiable: 'a',
      mail_recipient_to: '',
      # mail_recipient_to_except_cc: true,
      mail_recipient_cc: '',
      # mail_recipient_cc_except_to: true,
    }

    assert_redirected_to "/projects/#{project.identifier}/settings/mail_recipient"
    assert_nil flash[:notice]
    assert_nil flash[:error]
  end

  def test_update_deny_permission
    project = Project.find(2)
    project.enable_module!(:mail_recipient)

    put :update, params: {
      project_id: project.id,
      mail_recipient_tracker_id: '1',
      mail_recipient_notifiable: 'a',
    }

    assert_response 403
  end
end
