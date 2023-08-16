# frozen_string_literal: true

module ForemanLiudeskCMDB
  module SyncAsset
    module SyncHardware
      # Attaches a thin hardware object to the context is one is available
      class FindThin
        include ::Interactor

        around do |interactor|
          interactor.call if facet.hardware?
        end

        def call
          context.hardware = ForemanLiudeskCMDB::API.get_asset(facet.hardware_model_type, facet.hardware_id, thin: true)
        rescue StandardError => e
          ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                            .error("#{self.class} error #{e}: #{e.backtrace}")
          context.fail!(error: "#{self.class}: #{e}")
        end

        private

        delegate :host, to: :context

        def facet
          host.liudesk_cmdb_facet
        end
      end
    end
  end
end
