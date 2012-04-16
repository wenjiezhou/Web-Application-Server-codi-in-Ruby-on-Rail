class Event < ActiveRecord::Base
  validates :name, :presence=>true
  validates :starts_at, :presence=>true
  validates :ends_at, :presence=>true
  belongs_to :calendars
end
