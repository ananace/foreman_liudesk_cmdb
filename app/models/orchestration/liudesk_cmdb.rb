# frozen_string_literal: true

module Orchestration
  # Adds orchestration methods for CMDB assets
  module LiudeskCMDB
    extend ActiveSupport::Concern

    included do
      after_validation :queue_cmdb_sync, if: :cmdb_orchestration_with_inherit?
      before_destroy :cmdb_archive_asset_blocking, if: :cmdb_orchestration?
    end

    delegate :asset_params_diff, to: :liudesk_cmdb_facet

    def cmdb_orchestration?
      return false unless Setting[:liudesk_cmdb_orchestration_enabled]

      !liudesk_cmdb_facet.nil?
    end

    def cmdb_orchestration_with_inherit?
      return false unless Setting[:liudesk_cmdb_orchestration_enabled]
      return true if liudesk_cmdb_facet&.asset_will_change?
      return false if liudesk_cmdb_facet
      return false unless hostgroup
      return false if hostgroup.inherited_facet_attributes(Facets.registered_facets[:liudesk_cmdb_facet]).empty?

      true
    end

    def queue_cmdb_sync
      return unless errors.empty?

      ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                        .info("Queued sync of CMDB data for #{name}, changing: #{asset_params_diff}")

      post_queue.create(
        name: _("Sync CMDB asset for host %s") % self, priority: 100, action: [self, :cmdb_sync_asset]
      )
    end

    def queue_cmdb_archive
      return unless errors.empty?

      ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                        .info("Queued archiving of CMDB entry for #{name}.")

      post_queue.create(
        name: _("Archive CMDB asset for host %s") % self, priority: 100, action: [self, :cmdb_archive_asset_blocking]
      )
    end

    def cmdb_sync_asset
      ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                        .info("Syncing CMDB data for #{name}")

      ForemanLiudeskCMDB::SyncAssetJob.perform_later(id)
    rescue StandardError => e
      ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                        .error("Failed to sync CMDB asset for #{name}. #{e.class}: #{e} - #{e.backtrace}")

      failure format(_("Failed to sync %<name>s with CMDB: %<message>s\n "), name: name, message: e.message), e
    end

    def cmdb_sync_asset_blocking
      ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                        .info("Syncing CMDB data for #{name}")

      ForemanLiudeskCMDB::SyncAsset::Organizer.call(host: self)
    rescue StandardError => e
      ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                        .error("Failed to sync CMDB asset for #{name}. #{e.class}: #{e} - #{e.backtrace}")

      failure format(_("Failed to sync %<name>s with CMDB: %<message>s\n "), name: name, message: e.message), e
    end

    def cmdb_archive_asset
      ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                        .info("Archiving CMDB asset for #{name}")

      ForemanLiudeskCMDB::ArchiveAssetJob.perform_later(id)
    rescue StandardError => e
      ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                        .error("Failed to archive CMDB asset for #{name}. #{e.class}: #{e} - #{e.backtrace}")

      failure format(_("Failed to archive %<name>s on CMDB: %<message>s\n "), name: name, message: e.message), e
    end

    def cmdb_archive_asset_blocking
      ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                        .info("Archiving CMDB asset for #{name}")

      ForemanLiudeskCMDB::ArchiveAsset::Organizer.call(host: self)
    rescue StandardError => e
      ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                        .error("Failed to archive CMDB asset for #{name}. #{e.class}: #{e} - #{e.backtrace}")

      failure format(_("Failed to archive %<name>s on CMDB: %<message>s\n "), name: name, message: e.message), e
    end
  end
end
