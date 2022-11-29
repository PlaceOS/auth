class AddUser < ActiveRecord::Migration[7.0]
  def change
    create_table :user, id: :string do |t|
      t.timestamps

      t.string :name
      t.string :nickname
      t.string :client_secret
      t.string :email
      t.string :phone
      t.string :country
      t.string :image
      t.string :ui_theme
      t.string :misc
      t.string :login_name
      t.string :staff_id
      t.string :first_name
      t.string :last_name
      t.string :building
      t.string :department
      t.string :preferred_language
      t.string :password_digest
      t.string :email_digest
      t.string :card_number
      t.string :groups, array: true

      t.boolean :deleted

      t.string :access_token
      t.string :refresh_token
      t.bigint :expires_at
      t.boolean :expires

      t.string :password

      t.boolean :sys_admin
      t.boolean :support

      t.string :authority_id
    end

    add_foreign_key(:user, :authority, if_not_exists: true)
  end
end
