class CreateTrils < ActiveRecord::Migration
  def self.up
    create_table :trils do |t|
    end
  end

  def self.down
    drop_table :trils
  end
end
