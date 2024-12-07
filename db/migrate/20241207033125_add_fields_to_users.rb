class AddFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :last_scan_time, :datetime
    add_column :users, :last_scan_location, :string
  end
end
