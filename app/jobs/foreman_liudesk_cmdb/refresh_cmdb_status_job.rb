# frozen_string_literal: true

module ForemanLiudeskCMDB
  # A background job to refresh CMDB statuses
  class RefreshCMDBStatusJob < ::ApplicationJob
    queue_as :cmdb_status_refresh

    def perform(host_ids)
      Host::Managed.where(id: host_ids).each(&:refresh_cmdb_status)
    end

    rescue_from(StandardError) do |error|
      Foreman::Logging.exception("Failed to refresh CMDB status", error, logger: "background")
    end

    def humanized_name
      _("Refresh CMDB sync status")
    end
  end
end
