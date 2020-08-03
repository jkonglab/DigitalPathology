class CreateLandmarks < ActiveRecord::Migration[5.1]
  def change
    create_table :landmarks do |t|
	t.integer "parent_id"
	t.integer "image_id"
	t.json "image_data"
	t.integer "ref_image_id"
	t.json "ref_image_data"
	t.datetime "created_at", null: false
	t.datetime "updated_at", null: false
	t.index ["image_id"], name: "index_landmaarks_on_image_id"
	t.index ["ref_image_id"], name: "index_landmaarks_on_ref_image_id"
    end
  end
end
