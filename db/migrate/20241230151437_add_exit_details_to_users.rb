class AddExitDetailsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :exit_location, :string
    add_column :users, :exit_time, :datetime
  end
end
