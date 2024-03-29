# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20210701192201) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "algorithms", id: :serial, force: :cascade do |t|
    t.string "name"
    t.json "parameters"
    t.integer "language"
    t.integer "output_type"
    t.string "title"
    t.boolean "multioutput", default: false
    t.json "multioutput_options"
    t.integer "input_type", default: 0
    t.integer "tile_size"
    t.boolean "single_queue_flag"
  end

  create_table "annotations", id: :serial, force: :cascade do |t|
    t.integer "image_id"
    t.json "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "label"
    t.integer "user_id"
    t.integer "width"
    t.integer "height"
    t.integer "x_point"
    t.integer "y_point"
    t.string "annotation_class"
    t.string "annotation_type"
    t.index ["user_id"], name: "index_annotations_on_user_id"
  end

  create_table "clinical_data", id: :serial, force: :cascade do |t|
    t.integer "image_id"
    t.string "meta_key"
    t.string "meta_value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "images", id: :serial, force: :cascade do |t|
    t.string "title", default: ""
    t.integer "height"
    t.integer "width"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "processing", default: false
    t.boolean "complete", default: false
    t.json "clinical_data"
    t.integer "image_type", default: 1
    t.integer "parent_id"
    t.integer "slice_order"
    t.integer "visibility", default: 0
    t.integer "generated_by_run_id"
    t.string "file_file_name"
    t.string "file_content_type"
    t.bigint "file_file_size"
    t.datetime "file_updated_at"
    t.integer "project_id"
  end

  create_table "landmarks", force: :cascade do |t|
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

  create_table "projects", force: :cascade do |t|
    t.string "title"
    t.integer "visibility"
    t.string "tissue_type"
    t.string "modality"
    t.string "method"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
  end

  create_table "results", id: :serial, force: :cascade do |t|
    t.integer "run_id"
    t.integer "tile_x"
    t.integer "tile_y"
    t.json "raw_data"
    t.json "svg_data"
    t.integer "run_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "exclude"
    t.string "output_key"
    t.integer "output_type"
    t.string "output_file"
    t.index ["exclude"], name: "index_results_on_exclude"
    t.index ["output_key"], name: "index_results_on_output_key"
    t.index ["output_type"], name: "index_results_on_output_type"
    t.index ["run_id"], name: "index_results_on_run_id"
    t.index ["tile_x"], name: "index_results_on_tile_x"
    t.index ["tile_y"], name: "index_results_on_tile_y"
  end

  create_table "runs", id: :serial, force: :cascade do |t|
    t.integer "algorithm_id"
    t.integer "image_id"
    t.integer "annotation_id"
    t.json "parameters"
    t.boolean "processing"
    t.boolean "complete"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.integer "run_at"
    t.integer "total_tiles"
    t.integer "tiles_processed", default: 0
    t.integer "lock_version", default: 0, null: false
    t.integer "tile_size"
    t.json "results"
    t.decimal "percentage"
    t.boolean "percentage_analysis_done"
    t.index ["user_id"], name: "index_runs_on_user_id"
  end

  create_table "user_project_ownerships", force: :cascade do |t|
    t.integer "user_id"
    t.integer "project_id"
  end

  create_table "user_run_ownerships", force: :cascade do |t|
    t.integer "user_id"
    t.integer "run_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "admin", default: 0
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.boolean "approved", default: false, null: false
    t.integer "reviewer", default: 0
    t.index ["approved"], name: "index_users_on_approved"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
