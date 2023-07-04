# frozen_string_literal: true

# Main database migration
class AddLiudeskCmdb < ActiveRecord::Migration[6.1]
  def change
    create_table :liudesk_cmdb_servers do |t|
      t.string :name, null: false, unique: true

      t.string :description, limit: 255
      t.string :url, null: false, limit: 255

      t.string :apikey, null: false, limit: 64

      t.timestamps null: false
    end

    create_table :liudesk_cmdb_facets do |t|
      t.references :liudesk_cmdb_server, null: false, foreign_key: true, index: true
      t.integer :host_id, null: false, index: true

      t.string :asset_type, null: false
      t.string :asset_id, null: true
      t.string :hardware_id, null: true
      t.timestamp :full_sync_at, null: true

      t.timestamps null: false
    end

    create_table :liudesk_cmdb_hostgroup_facets do |t|
      t.references :liudesk_cmdb_server, null: false, foreign_key: true, index: true
      t.integer :hostgroup_id, null: false, index: true

      t.string :asset_type, null: false

      t.timestamps null: false
    end
  end
end
