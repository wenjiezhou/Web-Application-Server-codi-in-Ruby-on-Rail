class CreateCalendars < ActiveRecord::Migration
  def change
    create_table :calendars do |t|
      t.string :name, :null=> false
      t.text :description
      t.references :users
      t.timestamps
    end
  end
end
