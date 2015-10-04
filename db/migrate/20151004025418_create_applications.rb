class CreateApplications < ActiveRecord::Migration
  def change
    create_table :applications do |t|
      t.integer :user_id
      t.text :address
      t.string :phone
      t.string :emergency_contact_name
      t.string :emergency_contact_phone
      t.text :wahnam_courses
      t.text :martial_arts_experience
      t.text :health_issues
      t.text :bio
      t.text :why_shaolin
      t.boolean :ten_shaolin_laws

      t.timestamps
    end

    add_index :applications, :user_id
  end
end
