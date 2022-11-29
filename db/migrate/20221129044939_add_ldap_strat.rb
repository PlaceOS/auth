class AddLdapStrat < ActiveRecord::Migration[7.0]
  def change
    create_table :ldap_strat, id: :string do |t|
      t.timestamps

      t.string :name
      t.integer :port
      t.string :auth_method
      t.string :uid
      t.string :host
      t.string :base
      t.string :bind_dn
      t.string :password
      t.string :filter
      t.string :authority_id
    end

    add_foreign_key(:ldap_strat, :authority, if_not_exists: true)
  end
end
