# This migration comes from condo_active_record (originally 20160214022500)
class Parallel < ActiveRecord::Migration
    def change
        add_column  :condo_uploads, :part_list, :string
        add_column  :condo_uploads, :part_data, :text
        remove_column :condo_uploads, :custom_params
    end
end
