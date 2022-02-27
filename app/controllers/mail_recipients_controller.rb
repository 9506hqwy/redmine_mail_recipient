# frozen_string_literal: true

class MailRecipientsController < ApplicationController
  before_action :find_project_by_project_id, :authorize

  def update
    tracker_id = params[:mail_recipient_tracker_id].to_i if params[:mail_recipient_tracker_id].present?
    notifiable = params[:mail_recipient_notifiable]
    to = params[:mail_recipient_to]
    to_except_cc = params[:mail_recipient_to_except_cc].present?
    cc = params[:mail_recipient_cc]
    cc_except_to = params[:mail_recipient_cc_except_to].present?

    setting = @project.mail_recipient.where(tracker_id: tracker_id, notifiable: notifiable).first
    if setting.blank? && to.blank? && cc.blank?
      # PASS
    elsif to.blank? && cc.blank?
      if setting.destroy
        flash[:notice] = l(:notice_successful_update)
      end
    else
      setting ||= MailRecipient.new
      setting.project_id = @project.id
      setting.tracker_id = tracker_id
      setting.notifiable = notifiable
      setting.to = to
      setting.to_except_cc = to.blank? && to_except_cc
      setting.cc = cc
      setting.cc_except_to = cc.blank? && cc_except_to
      if setting.save
        flash[:notice] = l(:notice_successful_update)
      end
    end

    redirect_to settings_project_path(@project, tab: :mail_recipient)
  end
end
