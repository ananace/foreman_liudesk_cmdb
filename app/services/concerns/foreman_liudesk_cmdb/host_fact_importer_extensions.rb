# frozen_string_literal: true

module ForemanLiudeskCMDB
  # Extension for host fact import to trigger asset sync if necessary
  module HostFactImporterExtensions
    extend ActiveSupport::Concern

    def parse_facts(facts, type, source_proxy)
      super

      host.cmdb_sync_asset if host.cmdb_orchestration_with_inherit?
    end
  end
end
