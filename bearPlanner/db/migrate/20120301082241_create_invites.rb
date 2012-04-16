class CreateInvites < ActiveRecord::Migration
  def change
    create_table :invites do |t|
      t.references :events
      t.references :users
      t.text :messag
      t.timestamps
    end
  end
end
