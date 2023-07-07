# frozen_string_literal: true

module ForemanLiudeskCMDB
  # Main host facet for CMDB asset link
  #
  # Tracks asset and hardware objects separately to ease lookup
  class LiudeskCMDBFacet < ApplicationRecord
    # Allow use of asset type in jails
    class Jail < Safemode::Jail
      allow :asset_type
    end

    include Facets::Base

    belongs_to :liudesk_cmdb_server,
               class_name: "LiudeskCMDBServer",
               inverse_of: :liudesk_cmdb_facets

    validates_lengths_from_database

    validates :asset_type, presence: true

    def asset_model_type
      if asset_type.to_s.downcase == "server"
        :server_v1
      elsif asset_type.to_s.downcase == "client"
        case host.os&.family
        when /^windows/i
          :windows_client_v1
        else
          :linux_client_v1
        end
      else
        asset_type.to_s.downcase.to_sym
      end
    end

    def client?
      asset_type.to_s != "server"
    end

    def asset(thin: false)
      return unless asset_id

      liudesk_cmdb_server.get_asset(asset_model_type, asset_id, thin: thin)
    end

    def asset!(thin: false)
      return asset(thin: thin) if asset_id
      raise "Missing hardware ID" unless hardware_id

      new_asset = nil
      begin
        new_asset = liudesk_cmdb_server.get_asset(asset_model_type, host.name)
      rescue LiudeskCMDB::NotAcceptableError
        # Asset already exists, but as a different type
        raise
      rescue LiudeskCMDB::Error
        # Asset not found, create a new one
      end

      new_asset ||= liudesk_cmdb_server.create_asset(
        asset_model_type, **host.cmdb_asset_info(create: true).merge(hardware_id: hardware_id)
      )
      self.asset_id = new_asset.identifier
      new_asset
    end

    def hardware(thin: false)
      return unless hardware_id

      liudesk_cmdb_server.get_asset(:hardware_v1, hardware_id, thin: thin)
    end

    def hardware!(thin: false)
      return hardware(thin: thin) if hardware_id

      if host.cmdb_hardware_search.empty?
        hw = []
      else
        hw = liudesk_cmdb_server.find_asset(:hardware_v1, **host.cmdb_hardware_search)
        raise "Found multiple valid hardwares" if hw.count > 1
      end

      hw = if hw.count == 1
             hw.first
           else
             liudesk_cmdb_server.create_asset(:hardware_v1, **host.cmdb_hardware_info(create: true))
           end

      self.hardware_id = hw.identifier
      hw
    end
  end
end
