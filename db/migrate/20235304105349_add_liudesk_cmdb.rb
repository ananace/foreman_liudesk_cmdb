# frozen_string_literal: true

# Main database migration
class AddLiudeskCmdb < ActiveRecord::Migration[6.1]
  def change
    create_table :liudesk_cmdb_facets do |t|
      t.integer :host_id, null: false, index: true

      t.string :asset_type, null: false
      t.string :network_role, null: true

      t.string :asset_id, null: true
      t.string :hardware_id, null: true

      t.jsonb :raw_data, null: true
      t.timestamp :sync_at, null: true
      t.string :sync_error, null: true

      t.timestamps null: false
    end

    create_table :liudesk_cmdb_hostgroup_facets do |t|
      t.integer :hostgroup_id, null: false, index: true

      t.string :asset_type, null: false
      t.string :network_role, null: true

      t.timestamps null: false
    end
  end
end
