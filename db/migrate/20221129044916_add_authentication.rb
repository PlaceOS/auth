class AddAuthentication < ActiveRecord::Migration[7.0]
  def change
    create_table :authentication, id: :string do |t|
      t.timestamps

      t.string :uid, null: false
      t.string :provider, null: false
      t.string :user_id
      t.string :authority_id
    end
  end
end
