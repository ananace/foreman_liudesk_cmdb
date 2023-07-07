# frozen_string_literal: true

module ForemanLiudeskCMDB
  # CMDB extensions
  #
  # Adds helper methods for working with client status and CMDB facet
  module HostExtensions
    extend ActiveSupport::Concern

    def self.prepended(base)
      base.instance_eval do
        # TODO
        # has_one :liudesk_cmdb_facet,
        #         class_name: "ForemanLiudeskCMDB::LiudeskCMDBFacet",
        #         foreign_key: :host_id,
        #         inverse_of: :host,
        #         dependent: :destroy

        # scoped_search on: :passwordstate_server_id,
        #               relation: :passwordstate_facet,
        #               rename: :passwordstate_server,
        #               complete_value: true,
        #               only_explicit: true

        after_update :ensure_cmdb_entry
        before_destroy :remove_cmdb_entry
      end
    end

    def liudesk_cmdb_facet!(**attrs)
      return liudesk_cmdb_facet if liudesk_cmdb_facet && attrs.empty?

      attrs = liudesk_cmdb_facet.attributes.merge(attrs) if liudesk_cmdb_facet
      attrs = hostgroup.inherited_facet_attributes(Facets.registered_facets[:liudesk_cmdb_facet]).merge(attrs) \
        if hostgroup

      if liudesk_cmdb_facet
        f = liudesk_cmdb_facet
        f.update_attributes attrs
      else
        f = build_liudesk_cmdb_facet attrs
      end
      f.save if persisted?

      f
    end

    def cmdb_client?
      liudesk_cmdb_facet&.client?
    end

    def cmdb_client=(client)
      raise "Not a CMDB asset" unless liudesk_cmdb_facet
      raise ArgumentError, "Not a boolean" unless [FalseClass, TrueClass].include? client.class

      # FIXME: Handle changing client <-> server
      liudesk_cmdb_facet.asset_type = client ? :client : :server
    end

    def cmdb_asset_info(create: false)
      info = {
        hostname: name
      }
      info[:network_access_role] = "None" if create
      info[:operating_system] = os&.title || "N/A"
      info[:operating_system_type] = os&.name || "N/A"
      info[:operating_system_install_date] = installed_at

      if managed?
        info[:management_system] = "ITI-Foreman"
        info[:management_system_id] = "#{SETTINGS[:fqdn]}/#{id}"
        info[:certificate_information] = certname
        info[:network_certificate_ca] = "PUPPETCA" if liudesk_cmdb_facet&.client?
        info[:foreman_link] = "https://#{SETTINGS[:fqdn]}/hosts/#{fqdn}" unless liudesk_cmdb_facet&.client?
      end

      info.compact
    end

    def cmdb_hardware_search
      info = {
        serial_number: facts["dmi::product::serial_number"],
        bios_uuid: facts["dmi::product::uuid"] || facts["uuid"]
      }

      info.compact
    end

    def cmdb_hardware_info(create: false)
      info = cmdb_hardware_search
      info.merge!(
        make: facts["dmi::manufacturer"] || "N/A",
        model: facts["dmi::product::name"],
        hostname: name
      )

      info[:mac_and_network_access_roles] = [mac: "", networkAccessRole: "None"] if create

      # Strip out manufacturer from product name, to avoid double-manufacturer identifiers
      info[:model] = info[:model]&.sub(info[:make], "")&.strip if info[:model]&.start_with? info[:make]
      info[:model] = "N/A" if info[:model].nil? || info[:model].empty?

      info.compact
    end

    def ensure_cmdb_entry
      return unless liudesk_cmdb_facet

      # TODO: Fully differential sync, a.k.a; no get, only put
      # asset = liudesk_cmdb_facet.asset(thin: true)
      # asset.blah = blah if blah_changed?
      # asset.save! if asset.changed?
      # hw = liudesk_cmdb_facet.hardware(thin: true)
      # hw.blah = blah if blah_changed?
      # hw.save! if hw.changed?

      # FIXME: This is ugly, should attempt assign elsewhere - service probably
      unless liudesk_cmdb_facet.asset_id
        reset_asset_id = true
        liudesk_cmdb_facet.asset_id = fqdn
      end
      asset = nil
      begin
        asset = liudesk_cmdb_facet.asset
      rescue LiudeskCMDB::NotFoundError
        liudesk_cmdb_facet.asset_id = nil if reset_asset_id
        # 404 is ok here
      end
      liudesk_cmdb_facet.hardware_id ||= asset.hardware_id if asset

      # FIXME: Needs more graceful error handling
      hw = liudesk_cmdb_facet.hardware!
      hw.update_attributes(**cmdb_hardware_info)
      hw.patch! if hw.changed?

      asset ||= liudesk_cmdb_facet.asset!
      asset.update_attributes(**cmdb_asset_info)
      asset.patch! if asset.changed?

      liudesk_cmdb_facet.save! if liudesk_cmdb_facet.changed?

      true
    rescue StandardError => e
      Foreman::Logging.exception "Failed to update CMDB entry - #{e.class}: #{e}", e, logger: "foreman_liudesk_cmdb"
      nil
    end

    def remove_cmdb_entry
      return unless liudesk_cmdb_facet
      return unless liudesk_cmdb_facet.asset_id

      asset = liudesk_cmdb_facet.asset(thin: true)

      # XXX Rename before deprecation to avoid collision
      # This is temporary until deprecation supports name storage
      asset.identifier += "-depr-#{Time.now.to_i}"
      asset.save!

      asset.destroy
    rescue StandardError => e
      Foreman::Logging.exception "Failed to remove CMDB entry - #{e.class}: #{e}", e, logger: "foreman_liudesk_cmdb"
      nil
    end
  end
end
