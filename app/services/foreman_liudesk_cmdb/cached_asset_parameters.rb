# frozen_string_literal: true

module ForemanLiudeskCMDB
  # Asset parameters retrieval helper
  class AssetParameters
    def self.call(host)
      new(host).call
    end

    def initialize(host)
      @host = host
    end

    def call
      {
        asset: asset_params,
        hardware: hardware_params
      }
    end

    private

    def asset_params
      params = host.liudesk_cmdb_facet.raw_data[:asset]
      return {} unless params

      params.slice host.liudesk_cmdb_facet.asset_parameter_keys
    end

    def hardware_params
      params = host.liudesk_cmdb_facet.raw_data[:hardware]
      return {} unless params

      params.slice host.liudesk_cmdb_facet.hardware_parameter_keys
    end
  end
end
