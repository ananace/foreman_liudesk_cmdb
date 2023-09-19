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
      # Avoid pushing impossible role changes
      data.delete :network_access_role unless @active.dig(:asset, :certificate_information)
      # data.delete :network_access_role if data[:network_access_role]

      # Ignore case difference on OS type, LiUDesk likes to capitalize the input data
      case_issues = %i[operating_system_type]
      case_issues.each do |key|
        data.delete key if data[key]&.downcase == @cached.dig(:asset, key)&.downcase
      end
    end

    def cleanup_hardware(data)
      # Ignore case difference on hardware make, LiUDesk likes to capitalize the input data
      case_issues = %i[make]
      case_issues.each do |key|
        data.delete key if data[key]&.downcase == @cached.dig(:hardware, key)&.downcase
      end
    end
  end
end
