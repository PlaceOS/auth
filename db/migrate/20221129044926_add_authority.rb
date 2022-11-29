class AddAuthority < ActiveRecord::Migration[7.0]
  def change
    create_table :authority, id: :string do |t|
      t.timestamps

      t.string :name, null: false
      t.string :description
      t.string :domain, null: false
      t.string :login_url
      t.string :logout_url

      t.json :internals
      t.json :config
    end

    add_foreign_key(:adfs_strat, :authority, if_not_exists: true)
    add_foreign_key(:authentication, :authority, if_not_exists: true)
  end
end
