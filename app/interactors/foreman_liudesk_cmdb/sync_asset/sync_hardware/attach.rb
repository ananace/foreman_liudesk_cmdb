# frozen_string_literal: true

module ForemanLiudeskCMDB
  module SyncAsset
    module SyncHardware
      # Attaches a full hardware object to the context if one is assigned to the facet
      class Attach
        include ::Interactor

        around do |interactor|
          interactor.call if facet.hardware? && !context.hardware
        end

        def call
          context.hardware = ForemanLiudeskCMDB::API.get_asset facet.hardware_model_type, facet.hardware_id
        rescue LiudeskCMDB::NotFoundError
          # Hardware likely removed externally, mark for re-discovery/creation
          facet.update hardware_id: nil
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
end
