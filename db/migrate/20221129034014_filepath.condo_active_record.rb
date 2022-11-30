# This migration comes from condo_active_record (originally 20111106022500)
class Filepath < ActiveRecord::Migration[7.0]
    def change
        add_column        :condo_uploads, :file_path, :text
    end
end
