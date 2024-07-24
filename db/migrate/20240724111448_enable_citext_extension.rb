class EnableCitextExtension < ActiveRecord::Migration[7.1]
  def change
    enable_extension "citext"
  end
end
