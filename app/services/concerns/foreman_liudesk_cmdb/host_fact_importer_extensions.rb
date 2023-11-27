# frozen_string_literal: true

module ForemanLiudeskCMDB
  # Extension for host fact import to trigger asset sync if necessary
  module HostFactImporterExtensions
    extend ActiveSupport::Concern

    def parse_facts(facts, type, source_proxy)
      super
    ensure
      host.cmdb_sync_asset if host.try :cmdb_orchestration_with_inherit?
    end
  end
end
