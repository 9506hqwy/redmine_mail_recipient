# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class TrackerTest < ActiveSupport::TestCase
  fixtures :trackers,
           :mail_recipients

  def test_destroy
    Issue.where(tracker_id: 2).delete_all

    t = trackers(:trackers_002)
    t.destroy!

    begin
      mail_recipients(:mail_recipients_001)
      assert false
    rescue ActiveRecord::RecordNotFound
      assert true
    end
  end
end
