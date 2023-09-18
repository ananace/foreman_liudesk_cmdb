# frozen_string_literal: true

module ForemanLiudeskCMDB
  module SyncAsset
    module SyncHardware
      # Attaches a thin hardware object to the context is one is available
      class FindThin
        # Skip attaching the thin object if cached data is older than 24h
        FORCE_FULL_INTERVAL = 24 * 60 * 60

        include ::Interactor

        around do |interactor|
          interactor.call if facet.hardware?
        end

        def call
          context.hardware = ForemanLiudeskCMDB::API.get_asset facet.hardware_model_type, facet.hardware_id, thin: thin?
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

        def thin?
          (Time.now - (facet.sync_at || Time.now)) < ForemanLiudeskCMDB::LiudeskCMDBFacet::FULL_RESYNC_INTERVAL
        end
      end
    end
  end
end
