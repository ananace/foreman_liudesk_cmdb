# frozen_string_literal: true

module ForemanLiudeskCMDB
  # Main host facet for CMDB asset link
  #
  # Tracks asset and hardware objects separately to ease lookup
  class LiudeskCMDBFacet < ApplicationRecord # rubocop:disable Metrics/ClassLength
    # Allow use of asset type in jails
    class Jail < Safemode::Jail
      allow :asset_parameters
      allow :cached_asset_parameters
    end

    # Fully resync data at least once every 24 hours
    FULL_RESYNC_INTERVAL = 24 * 60 * 60

    include Facets::Base

    validates_lengths_from_database

    validates :host, presence: true, allow_blank: false
    validates :asset_type, presence: true

    validate :validate_ephemeral_attributes

    before_save :cleanup_hardware_network_roles
    after_initialize :clear_ephemeral!

    # Ephemeral attribute handling
    #

    attr_reader :ephemeral_attributes

    def set_ephemeral(section, key, value)
      clear_ephemeral! if @ephemeral_attributes.nil?

      raise ArgumentError, "Section must be one of #{ephemeral_attributes.keys.inspect}" \
        unless ephemeral_attributes.keys.include? section

      ephemeral_attributes[section][key] = value
    end

    def ephemeral_attributes=(attrs)
      clear_ephemeral! if @ephemeral_attributes.nil?

      attrs = attrs.slice(*ephemeral_attributes.keys).deep_symbolize_keys
      existing = (raw_data || { asset: {}, hardware: {} }).deep_symbolize_keys

      attrs.each do |section, params|
        params.transform_values! { |value| value.nil? ? "" : value }
        params.delete_if { |param_name, param_value| (existing.dig(section, param_name) || "") == param_value }
      end

      @ephemeral_attributes.merge! attrs.deep_symbolize_keys
    end

    def ephemeral_attributes_any?
      return false unless @ephemeral_attributes

      @ephemeral_attributes.any? { |_, v| v.any? }
    end

    def clear_ephemeral!
      @ephemeral_attributes = { asset: {}, hardware: {} }
    end

    # Asset type handling
    #

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

    # Type checks
    def server?
      asset_model_type.to_s =~ /server_/
    end

    def computerlab?
      asset_model_type.to_s =~ /_computerlab_/
    end

    def client?
      asset_model_type.to_s =~ /_client_/
    end

    # Model parameter handling
    #

    def asset_parameter_keys
      keys = %i[
        hostname
        operating_system_type operating_system operating_system_install_date
        management_system management_system_id
      ]
      keys + if server?
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
      ForemanLiudeskCMDB::AssetParameterDifference
        .call(host)
        .deep_merge(ephemeral_attributes || {})
        .delete_if { |_, v| v.empty? }
    end

    # Meta-parameter generation
    #

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

    # Sync helpers
    #

    def asset_will_change?(only: nil)
      return true if asset_type_changed?
      return true if ephemeral_attributes_any?
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

    # CMDB asset retrieval
    #

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

    # FOREMAN-37043
    def self.inherited_attributes(hostgroup, facet_attributes)
      (facet_attributes || {}).merge(super) { |_, left, right| left || right }
    end

    def read_attribute_for_validation(key)
      return super unless key.to_s.include?(".")

      path = key.to_s.split(".").map(&:to_sym)
      public_send(path.first).dig(*path[1..])
    end

    private

    LIUID_REX = /^[a-z]{1,5}\d{2,3}$/.freeze

    def cleanup_hardware_network_roles
      hardware_network_roles&.delete_if do |_mac, entry|
        !entry.key?("role") || entry["role"].nil? || entry["role"].empty?
      end
    end

    def validate_ephemeral_attributes
      return unless ephemeral_attributes_any?

      validate_ephemeral_asset_attributes if @ephemeral_attributes[:asset]&.any?
      validate_ephemeral_hardware_attributes if @ephemeral_attributes[:hardware]&.any?
    end

    def validate_ephemeral_asset_attributes
      attrs = @ephemeral_attributes[:asset]
      errors.add("ephemeral_attributes.asset.asset_owner", "must be a valid LiU ID") \
        if attrs[:asset_owner]&.present? && attrs[:asset_owner] !~ LIUID_REX
    end

    def validate_ephemeral_hardware_attributes
      attrs = @ephemeral_attributes[:hardware]
      errors.add("ephemeral_attributes.hardware.asset_owner", "must be a valid LiU ID") \
        if attrs[:asset_owner]&.present? && attrs[:asset_owner] !~ LIUID_REX
    end
  end
end
