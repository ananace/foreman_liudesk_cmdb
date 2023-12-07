# frozen_string_literal: true

module HostStatus
  # Attaches the status of the CMDB sync to the host
  class CMDBStatus < HostStatus::Status
    OK = 0
    OUTOFSYNC = 1
    ERRORED = 2

    def relevant?(_options = {})
      host.liudesk_cmdb_facet
    end

    def to_global(_options = {})
      case to_status
      when OK
        HostStatus::Global::OK
      when ERRORED
        HostStatus::Global::ERROR
      else
        HostStatus::Global::WARN
      end
    end

    def to_label(_options = {})
      case to_status
      when OK
        N_("OK")
      when OUTOFSYNC
        N_("Out of sync")
      when ERRORED
        N_("Errored")
      else
        N_("Unknown")
      end
    end

    def to_status(_options = {})
      return ERRORED if host.liudesk_cmdb_facet&.sync_error
      return OUTOFSYNC if host.liudesk_cmdb_facet&.out_of_sync? multiplier: 1.5

      OK
    end

    def self.status_name
      N_("CMDB Status")
    end
  end
end
