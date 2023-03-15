class AddAdfsStrat < ActiveRecord::Migration[7.0]
  def change
    create_table :adfs_strat, id: :string do |t|
      t.timestamps

      t.string :name
      t.string :issuer
      t.json :idp_sso_target_url_runtime_params
      t.string :name_identifier_format, default: "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
      t.string :uid_attribute
      t.string :assertion_consumer_service_url
      t.string :idp_sso_target_url
      t.string :idp_cert
      t.string :idp_cert_fingerprint
      t.string :attribute_service_name
      t.json(:attribute_statements, default: {
        name: ["name"],
        email: %w[email mail],
        first_name: %w[first_name firstname firstName givenname],
        last_name: %w[last_name lastname lastName surname]
      })
      t.json(:request_attributes, default: [
        {name: "ImmutableID", name_format: "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
         friendly_name: "Login Name"},
        {name: "email", name_format: "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
         friendly_name: "Email address"},
        {name: "name", name_format: "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
         friendly_name: "Full name"},
        {name: "first_name", name_format: "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
         friendly_name: "Given name"},
        {name: "last_name", name_format: "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
         friendly_name: "Family name"}
      ])
      t.string :issuidp_slo_target_urler
      t.string :slo_default_relay_state
      t.string :authority_id
    end

    # add this in the authority migration
    # add_foreign_key(:articles, :authors, if_not_exists: true)
  end
end
