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
      @cached = CachedAssetParameters.call(host)
      @active = AssetParameters.call(host)

      diff = deep_diff(@active, @cached)

      cleanup_asset(diff[:asset]) if diff[:asset]
      cleanup_hardware(diff[:hardware]) if diff[:hardware]

      diff.delete_if { |_, v| v.nil? || v.empty? }

      diff
    end

    private

    attr_accessor :host

    def facet
      host.liudesk_cmdb_facet
    end

    def deep_diff(h_a, h_b)
      (h_a.keys | h_b.keys).each_with_object({}) do |k, diff|
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

    def cleanup_asset(data)
      data.delete :network_access_role if facet.network_role.nil? || facet.network_role.empty?
    end

    def cleanup_hardware(data)
      data.delete :make if data[:make]&.downcase == @active[:make]&.downcase
      data.delete :mac_and_network_access_roles # FIXME: Only created, not updated
      # data[:mac_and_network_access_roles]&.each { |macs| macs.delete :networkAccessRole }
    end
  end
end
