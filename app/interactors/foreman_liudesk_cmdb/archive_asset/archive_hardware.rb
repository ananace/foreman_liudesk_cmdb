# frozen_string_literal: true

module ForemanLiudeskCMDB
  module ArchiveAsset
    # Archives the CMDB hardware asset if the host is a virtual machine
    class ArchiveHardware
      include ::Interactor

      around do |interactor|
        interactor.call if context.host.compute? && context.hardware
      end

      def call
        # FIXME: This is temporary until deprecation supports MAC reuse
        begin
          context.hardware.mac_and_network_access_roles = nil
          context.hardware.patch! if context.hardware.changed?
        rescue LiudeskCMDB::UnprocessableError => e
          ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                            .warn("#{self.class} ignoring error on mac patch #{e}: #{e.backtrace}")
        end

        context.hardware.delete!
      rescue LiudeskCMDB::NotFoundError
        # Already removed, nothing to do
      rescue StandardError => e
        ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                          .error("#{self.class} error #{e.class}: #{e}")
        context.fail!(error_obj: e, error: "#{self.class}: #{e}")
      end
    end
  end
end
