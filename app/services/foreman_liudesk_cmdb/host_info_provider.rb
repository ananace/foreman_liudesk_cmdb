# frozen_string_literal: true

module ForemanLiudeskCMDB
  # Attaches CMDB info to the ENC data
  class HostInfoProvider < HostInfo::Provider
    def host_info
      return {} unless host.liudesk_cmdb_facet

      {
        cmdb: host.liudesk_cmdb_facet.cached_asset_parameters.merge(
          sync: {
            at: host.liudesk_cmdb_facet.sync_at,
            error: host.liudesk_cmdb_facet.sync_error
          }.compact
        )
      }
    end
  end
end
