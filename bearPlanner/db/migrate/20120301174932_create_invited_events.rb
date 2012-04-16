class CreateInvitedEvents < ActiveRecord::Migration
  def change
    create_table :invited_events do |t|
      t.references :events
      t.references :calendars
      t.references :users
      t.timestamps
    end
  end
end
