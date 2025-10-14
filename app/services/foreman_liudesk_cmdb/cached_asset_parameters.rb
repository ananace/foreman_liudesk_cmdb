# frozen_string_literal: true

module ForemanLiudeskCMDB
  # Cached asset parameters retrieval helper
  class CachedAssetParameters
    def self.call(host, **params)
      new(host, **params).call
    end

    def initialize(host, sliced: true, compacted: false)
      @host = host
      @sliced = sliced
      @compacted = compacted
    end

    def call
      {
        asset: asset_params,
        asset_type: asset_type_param,
        hardware: hardware_params,
        hardware_type: hardware_type_param
      }
    end

    private

    attr_accessor :host, :sliced, :compacted

    def facet
      host.liudesk_cmdb_facet
    end

    def raw_data
      (facet.raw_data || {}).deep_symbolize_keys
    end

    def asset_params
      return {} unless raw_data.key? :asset

      asset_klass = ForemanLiudeskCMDB::Api.get_asset_type(asset_type_param || facet.asset_model_type || :server_v1)

      params = asset_klass.convert_cmdb_to_ruby(raw_data[:asset] || {})
      params = params.slice(*host.liudesk_cmdb_facet.asset_parameter_keys) if sliced
      params = params.transform_values { |v| v == "" ? nil : v }.compact if compacted

      params
    end

    def asset_type_param
      return unless raw_data.key? :asset_type

      raw_data[:asset_type].to_sym
    end

    def hardware_params
      return {} unless raw_data.key? :hardware

      asset_klass = ForemanLiudeskCMDB::Api.get_asset_type(hardware_type_param || :hardware_v1)

      params = asset_klass.convert_cmdb_to_ruby(raw_data[:hardware] || {})
      params = params.slice(*host.liudesk_cmdb_facet.hardware_parameter_keys) if sliced
      params = params.transform_values { |v| v == "" ? nil : v }.compact if compacted

      params
    end

    def hardware_type_param
      return unless raw_data.key? :hardware_type

      raw_data[:hardware_type].to_sym
    end
  end
end
