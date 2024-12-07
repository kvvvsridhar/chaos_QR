class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :id_number
      t.integer :age
      t.string :location

      t.timestamps
    end
  end
end
