# frozen_string_literal: true

module ForemanLiudeskCMDB
  # A background job to sync the CMDB asset for a host
  class SyncAssetJob < ::ApplicationJob
    queue_as :cmdb_queue

    def perform(host_id, ephemeral_attributes: nil)
      host = Host.find(host_id)
      return unless host

      if ephemeral_attributes
        host.liudesk_cmdb_facet!
        host.liudesk_cmdb_facet.ephemeral_attributes = ephemeral_attributes
      end

      host.cmdb_sync_asset_blocking
    end

    rescue_from(StandardError) do |error|
      Foreman::Logging.exception("CMDB sync error", error, logger: "background")
    end

    def humanized_name
      _("Sync CMDB asset")
    end
  end
end
