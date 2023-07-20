# frozen_string_literal: true

module ForemanLiudeskCMDB
  # Helper class for holding a CMDB API client
  class API
    def self.client
      @client ||= LiudeskCMDB::Client.new Settings[:liudesk_cmdb_url], subscription_key: Settings[:liudesk_cmdb_token]
    end

    def self.get_asset(asset_type, asset_id, thin: false)
      klass = LiudeskCMDB::Models.const_get(asset_type.to_s._cmdb_camel_case(capitalized: true).to_sym)
      return klass.new(client, asset_id) if thin

      klass.get connection, asset_id
    end

    def self.find_asset(asset_type, **search)
      klass = LiudeskCMDB::Models.const_get(asset_type.to_s._cmdb_camel_case(capitalized: true).to_sym)
      klass.search client, op: :or, **search
    end

    def self.create_asset(asset_type, save: true, **data)
      klass = LiudeskCMDB::Models.const_get(asset_type.to_s._cmdb_camel_case(capitalized: true).to_sym)
      asset = klass.new client, **data
      asset.create if save
      asset
    end
  end
end
