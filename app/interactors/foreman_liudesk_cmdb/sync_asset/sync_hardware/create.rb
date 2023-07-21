# frozen_string_literal: true

module ForemanLiudeskCMDB
  module SyncAsset
    module SyncHardware
      # Attaches a hardware object to the context is one is available
      class Create
        include ::Interactor

        around do |interactor|
          interactor.call unless context.hardware
        end

        def call
          context.hardware = ForemanLiudeskCMDB::API.create_asset(:hardware_v1, **cmbd_params[:hardware])
        rescue StandardError => e
          ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                            .error("#{self.class} error #{e}: #{e.backtrace}")
          context.fail!(error: "#{self.class}: #{e}")
        end

        private # rubocop:disable Lint/UselessAccessModifier

        delegate :cmdb_params, to: :context
      end
    end
  end
end
