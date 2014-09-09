class CreateMemberships < ActiveRecord::Migration
  def change
    create_table :memberships do |table|
      table.belongs_to :user
      table.belongs_to :meetup
      table.string :role, null: false

      table.timestamps
    end
  end
end
