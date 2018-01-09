# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20180105181149) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "algorithms", force: :cascade do |t|
    t.string  "name"
    t.json    "parameters"
    t.integer "language"
    t.integer "output_type"
    t.string  "title"
  end

  create_table "annotations", force: :cascade do |t|
    t.integer  "image_id"
    t.json     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "label"
    t.integer  "user_id"
    t.integer  "width"
    t.integer  "height"
    t.integer  "x_point"
    t.integer  "y_point"
  end

  add_index "annotations", ["user_id"], name: "index_annotations_on_user_id", using: :btree

  create_table "clinical_data", force: :cascade do |t|
    t.integer  "image_id"
    t.string   "meta_key"
    t.string   "meta_value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "images", force: :cascade do |t|
    t.string   "title",               default: ""
    t.string   "slug"
    t.string   "format"
    t.string   "path"
    t.integer  "overlap"
    t.integer  "tile_size"
    t.integer  "height"
    t.integer  "width"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "processing",          default: false
    t.string   "upload_file_name"
    t.string   "file_name_prefix"
    t.integer  "user_id"
    t.json     "clinical_data"
    t.integer  "image_type",          default: 1
    t.integer  "parent_id"
    t.integer  "slice_order"
    t.integer  "visibility",          default: 0
    t.integer  "generated_by_run_id"
  end

  add_index "images", ["user_id"], name: "index_images_on_user_id", using: :btree

  create_table "results", force: :cascade do |t|
    t.integer  "run_id"
    t.integer  "tile_x"
    t.integer  "tile_y"
    t.json     "raw_data"
    t.json     "svg_data"
    t.integer  "run_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "runs", force: :cascade do |t|
    t.integer  "algorithm_id"
    t.integer  "image_id"
    t.integer  "annotation_id"
    t.json     "parameters"
    t.boolean  "processing"
    t.boolean  "complete"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "run_at"
    t.integer  "total_tiles"
    t.integer  "tiles_processed", default: 0
    t.integer  "lock_version",    default: 0, null: false
    t.integer  "tile_size"
  end

  add_index "runs", ["user_id"], name: "index_runs_on_user_id", using: :btree

  create_table "user_image_ownerships", force: :cascade do |t|
    t.integer "user_id"
    t.integer "image_id"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
