class AddOauthStrat < ActiveRecord::Migration[7.0]
  def change
    create_table :oauth_strat, id: :string do |t|
      t.timestamps

      t.string :name
      t.string :client_id
      t.string :client_secret
      t.json :info_mappings
      t.json :authorize_params
      t.json :ensure_matching
      t.string :site
      t.string :authorize_url
      t.string :token_method
      t.string :auth_scheme
      t.string :token_url
      t.string :scope
      t.string :raw_info_url
      t.string :authority_id
    end

    add_foreign_key(:oauth_strat, :authority, if_not_exists: true)
  end
end
