# frozen_string_literal: true

module ForemanLiudeskCMDB
  # Main host facet for CMDB asset link
  #
  # Tracks asset and hardware objects separately to ease lookup
  class LiudeskCMDBFacet < ApplicationRecord # rubocop:disable Metrics/ClassLength
    # Allow use of asset type in jails
    class Jail < Safemode::Jail
      allow :cached_asset_parameters
    end

    # Fully resync data at least once every 24 hours
    FULL_RESYNC_INTERVAL = 24 * 60 * 60

    include Facets::Base

    validates_lengths_from_database

    validates :host, presence: true, allow_blank: false
    validates :asset_type, presence: true

    before_save :cleanup_hardware_network_roles

    def asset_model_type
      if asset_type.to_s.downcase == "server"
        :server_v1
      elsif %w[client computerlab].include? asset_type.to_s.downcase
        case host.os&.family
        when /^windows/i
          :"windows_#{asset_type}_v1"
        when /^darwin/i
          :"mac_#{asset_type}_v1"
        else
          :"linux_#{asset_type}_v1"
        end
      else
        asset_type.to_s.downcase.to_sym
      end
    end

    def hardware_model_type
      :hardware_v1
    end

    def deep_network_role
      return network_role unless network_role.nil? || network_role.empty?

      host.hostgroup
        &.inherited_facet_attributes(Facets.registered_facets[:liudesk_cmdb_facet])
        &.[]("network_role")
    end

    def deep_hardware_fallback_role
      return hardware_fallback_role unless hardware_fallback_role.nil? || hardware_fallback_role.empty?

      host.hostgroup
        &.inherited_facet_attributes(Facets.registered_facets[:liudesk_cmdb_facet])
        &.[]("hardware_fallback_role")
    end

    def server?
      asset_type.to_s.downcase == "server"
    end

    def client?
      !server?
    end

    def asset_parameter_keys
      base = %i[
        hostname
        operating_system_type operating_system operating_system_install_date
        management_system management_system_id
      ]
      base + if server?
               %i[foreman_link]
             else
               %i[certificate_information network_access_role network_certificate_ca]
             end
    end

    def hardware_parameter_keys
      %i[
        make model
        mac_and_network_access_roles
        serial_number bios_uuid
      ]
    end

    def asset_parameters
      ForemanLiudeskCMDB::AssetParameters.call(host)
    end

    def cached_asset_parameters
      ForemanLiudeskCMDB::CachedAssetParameters.call(host)
    end

    def asset_params_diff
      ForemanLiudeskCMDB::AssetParameterDifference.call(host)
    end

    def asset_will_change?(only: nil)
      return true if asset_type_changed?
      return (asset_params_diff[only] || {}).any? if only
      return true if out_of_sync?

      asset_params_diff.any?
    end

    def out_of_sync?(multiplier: 1)
      (Time.now - (sync_at || Time.now)) >= FULL_RESYNC_INTERVAL * multiplier
    end

    def force_resync!
      update sync_at: Time.at(0)
    end

    def asset?
      !asset_id.nil?
    end

    def asset
      return unless asset_id

      ForemanLiudeskCMDB::API.get_asset(asset_model_type, asset_id)
    end

    def hardware?
      !hardware_id.nil?
    end

    def hardware
      return unless hardware_id

      ForemanLiudeskCMDB::API.get_asset(hardware_model_type, hardware_id)
    end

    private

    def cleanup_hardware_network_roles
      hardware_network_roles&.delete_if do |_mac, entry|
        !entry.key?("role") || entry["role"].nil? || entry["role"].empty?
      end
    end
  end
end
