# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2022_11_29_045002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "adfs_strat", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "issuer"
    t.json "idp_sso_target_url_runtime_params"
    t.string "name_identifier_format", default: "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
    t.string "uid_attribute"
    t.string "assertion_consumer_service_url"
    t.string "idp_sso_target_url"
    t.string "idp_cert"
    t.string "idp_cert_fingerprint"
    t.string "attribute_service_name"
    t.json "attribute_statements", default: {"name"=>["name"], "email"=>["email", "mail"], "first_name"=>["first_name", "firstname", "firstName", "givenname"], "last_name"=>["last_name", "lastname", "lastName", "surname"]}
    t.json "request_attributes", default: [{"name"=>"ImmutableID", "name_format"=>"urn:oasis:names:tc:SAML:2.0:attrname-format:basic", "friendly_name"=>"Login Name"}, {"name"=>"email", "name_format"=>"urn:oasis:names:tc:SAML:2.0:attrname-format:basic", "friendly_name"=>"Email address"}, {"name"=>"name", "name_format"=>"urn:oasis:names:tc:SAML:2.0:attrname-format:basic", "friendly_name"=>"Full name"}, {"name"=>"first_name", "name_format"=>"urn:oasis:names:tc:SAML:2.0:attrname-format:basic", "friendly_name"=>"Given name"}, {"name"=>"last_name", "name_format"=>"urn:oasis:names:tc:SAML:2.0:attrname-format:basic", "friendly_name"=>"Family name"}]
    t.string "issuidp_slo_target_urler"
    t.string "slo_default_relay_state"
    t.string "authority_id"
  end

  create_table "authentication", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uid", null: false
    t.string "provider", null: false
    t.string "user_id"
    t.string "authority_id"
  end

  create_table "authority", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.string "description"
    t.string "domain", null: false
    t.string "login_url"
    t.string "logout_url"
    t.json "internals"
    t.json "config"
  end

  create_table "condo_uploads", force: :cascade do |t|
    t.string "user_id"
    t.string "file_name"
    t.integer "file_size"
    t.string "file_id"
    t.string "provider_namespace"
    t.string "provider_name"
    t.string "provider_location"
    t.string "bucket_name"
    t.string "object_key"
    t.text "object_options"
    t.string "resumable_id"
    t.boolean "resumable", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "file_path"
    t.string "part_list"
    t.text "part_data"
  end

  create_table "ldap_strat", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.integer "port"
    t.string "auth_method"
    t.string "uid"
    t.string "host"
    t.string "base"
    t.string "bind_dn"
    t.string "password"
    t.string "filter"
    t.string "authority_id"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "oauth_strat", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "client_id"
    t.string "client_secret"
    t.json "info_mappings"
    t.json "authorize_params"
    t.json "ensure_matching"
    t.string "site"
    t.string "authorize_url"
    t.string "token_method"
    t.string "auth_scheme"
    t.string "token_url"
    t.string "scope"
    t.string "raw_info_url"
    t.string "authority_id"
  end

  create_table "user", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "nickname"
    t.string "client_secret"
    t.string "email"
    t.string "phone"
    t.string "country"
    t.string "image"
    t.string "ui_theme"
    t.string "misc"
    t.string "login_name"
    t.string "staff_id"
    t.string "first_name"
    t.string "last_name"
    t.string "building"
    t.string "department"
    t.string "preferred_language"
    t.string "password_digest"
    t.string "email_digest"
    t.string "card_number"
    t.string "groups", array: true
    t.boolean "deleted"
    t.string "access_token"
    t.string "refresh_token"
    t.bigint "expires_at"
    t.boolean "expires"
    t.string "password"
    t.boolean "sys_admin"
    t.boolean "support"
    t.string "authority_id"
  end

  add_foreign_key "adfs_strat", "authority"
  add_foreign_key "authentication", "authority"
  add_foreign_key "ldap_strat", "authority"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_strat", "authority"
  add_foreign_key "user", "authority"
end
