# frozen_string_literal: true

module ForemanLiudeskCMDB
  # Helper class for holding a CMDB API client
  class API
    class << self
      def client
        @client ||= LiudeskCMDB::Client.new Setting[:liudesk_cmdb_url], subscription_key: Setting[:liudesk_cmdb_token]
      end

      def get_asset_type(asset_type)
        LiudeskCMDB::Models.const_get(asset_type.to_s._cmdb_camel_case(capitalized: true).to_sym)
      end

      def get_asset(asset_type, asset_id, thin: false)
        klass = get_asset_type(asset_type)
        return klass.new(client, asset_id) if thin

        klass.get client, asset_id
      end

      def find_asset(asset_type, **search)
        klass = get_asset_type(asset_type)
        klass.search client, op: :or, **search
      end

      def create_asset(asset_type, save: true, **data)
        klass = get_asset_type(asset_type)
        asset = klass.new client, **data
        asset.create if save
        asset
      end

      def network_access_roles
        Rails.cache.fetch("#{cache_key}/network_access_roles", expires_in: 8.hours) do
          JSON.parse(client.get("liudesk-cmdb/api/networkaccessroles", :v1)).sort
        end
      rescue StandardError => e
        Rails.logger.warn "Failed to retrieve CMDB network access roles, using fallback. #{e.class}: #{e}"
        %w[None]
      end

      private

      def cache_key
        url_hash = Setting[:liudesk_cmdb_url].bytes.inject(0xaf, :^)
        key_hash = Setting[:liudesk_cmdb_token].bytes.inject(0xed, :^)

        "LiudeskCMDBAPI/#{url_hash * key_hash}"
      end
    end
  end
end
