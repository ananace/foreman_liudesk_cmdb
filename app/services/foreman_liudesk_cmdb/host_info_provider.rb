# frozen_string_literal: true

module ForemanLiudeskCMDB
  # Attaches CMDB info to the ENC data
  class HostInfoProvider < HostInfo::Provider
    def host_info
      return {} unless host.liudesk_cmdb_facet

      {
        cmdb: JSON.parse(ForemanLiudeskCMDB::CachedAssetParameters.call(host, sliced: false, compacted: true).merge(
          sync: {
            at: host.liudesk_cmdb_facet.sync_at,
            error: host.liudesk_cmdb_facet.sync_error
          }.compact
        ).to_json)
      }
    end
  end
end
