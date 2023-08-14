# frozen_string_literal: true

module ForemanLiudeskCMDB
  module SyncAsset
    module SyncHardware
      # Applies any pending hardware ID changes to the facet
      class UpdateFacet
        include ::Interactor

        around do |interactor|
          interactor.call if hardware && hardware.id != facet.hardware_id
        end

        def call
          facet.update hardware_id: hardware.id
        rescue StandardError => e
          ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                            .error("#{self.class} error #{e}: #{e.backtrace}")
          context.fail!(error: "#{self.class}: #{e}")
        end

        private

        delegate :host, :hardware, to: :context

        def facet
          host.liudesk_cmdb_facet
        end
      end
    end
  end
end
