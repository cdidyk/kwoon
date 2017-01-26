class AddInterestsToApplication < ActiveRecord::Migration
  def change
    add_column :applications, :interests, :string

    # existing applications with no interests should be set to
    # Shaolin Kung Fu since that was the only option at the time of application
    Application
      .where("interests IS NULL")
      .update_all(interests: "Shaolin Kung Fu")
  end
end
