# frozen_string_literal: true

module ForemanLiudeskCMDB
  module ArchiveAsset
    # Attaches a CMDB hardware asset to the context is one is available
    class AttachThinHardware
      include ::Interactor

      around do |interactor|
        interactor.call if facet&.hardware?
      end

      def call
        context.hardware = ForemanLiudeskCMDB::Api.get_asset(facet.hardware_model_type, facet.hardware_id, thin: true)
      rescue StandardError => e
        ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                          .error("#{self.class} error #{e}: #{e.backtrace}")
        context.fail!(error_obj: e, error: "#{self.class}: #{e}")
      end

      private

      delegate :host, to: :context

      def facet
        host.liudesk_cmdb_facet
      end
    end
  end
end
