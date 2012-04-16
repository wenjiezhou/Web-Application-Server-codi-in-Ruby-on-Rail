class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :name, :null=>false
      t.datetime :starts_at, :null=>false
      t.datetime :ends_at, :null=>false
      t.references :users
      t.references :calendars
      t.timestamps
    end
  end
end
