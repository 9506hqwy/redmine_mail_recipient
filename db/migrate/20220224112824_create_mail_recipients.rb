# frozen_string_literal: true

class CreateMailRecipients < RedmineMailRecipient::Utils::Migration
  def change
    create_table :mail_recipients do |t|
      t.belongs_to :project, null: false, foreign_key: true
      t.string :notifiable, null: false
      t.belongs_to :tracker, foreign_key: true
      t.string :to
      t.boolean :to_except_cc
      t.string :cc
      t.boolean :cc_except_to

      t.index [:project_id, :notifiable, :tracker_id], name: 'mail_recipient_by_notifiable', unique: true
    end
  end
end
