# frozen_string_literal: true

module ForemanLiudeskCMDB
  # Generates CMDB asset differences between last update and current data
  class AssetParameterDifference
    def self.call(host)
      new(host).call
    end

    def initialize(host)
      @host = host
    end

    def call
      cached = CachedAssetParameters.call(host)
      active = AssetParameters.call(host)

      deep_diff(active, cached)
    end

    private

    attr_accessor :host

    def deep_diff(h_a, h_b)
      (h_a.keys | h_b.keys).each_with_object({}) do |diff, k|
        if h_a[k] != h_b[k]
          diff[k] = if h_a[k].is_a?(Hash) && h_b[k].is_a?(Hash)
                      deep_diff(h_a[k], h_b[k])
                    else
                      h_a[k]
                    end
        end
        diff
      end
    end
  end
end
