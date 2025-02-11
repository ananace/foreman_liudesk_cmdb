# frozen_string_literal: true

module ForemanLiudeskCMDB
  # A background job to archive the CMDB asset for a host
  class ArchiveAssetJob < ::ApplicationJob
    queue_as :cmdb_queue

    def perform(host_id)
      Host.find(host_id)&.cmdb_archive_asset_blocking
    end

    rescue_from(StandardError) do |error|
      Foreman::Logging.exception("CMDB archive error", error, logger: 'background')
    end

    def humanized_name
      _("Archive CMDB asset")
    end
  end
end
