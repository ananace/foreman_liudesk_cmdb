# frozen_string_literal: true

module ForemanLiudeskCMDB
  # A background job to sync the CMDB asset for a host
  class SyncAssetJob < ::ApplicationJob
    queue_as :cmdb_queue

    def perform(host_id)
      Host.find(host_id)&.cmdb_sync_asset_blocking
    end

    rescue_from(StandardError) do |error|
      Foreman::Logging.logger("background").error("CMDB sync: #{error.class} #{error}: #{error.backtrace}")
    end

    def humanized_name
      _("Sync CMDB asset")
    end
  end
end
