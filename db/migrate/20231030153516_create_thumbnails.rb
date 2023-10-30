class CreateThumbnails < ActiveRecord::Migration[7.1]
  def change
    create_table :thumbnails do |t|
      t.string :title
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
