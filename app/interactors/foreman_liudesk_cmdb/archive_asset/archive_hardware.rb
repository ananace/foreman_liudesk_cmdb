# frozen_string_literal: true

module ForemanLiudeskCMDB
  module ArchiveAsset
    # Archives the CMDB hardware asset if the host is a virtual machine
    class ArchiveHardware
      include ::Interactor

      around do |interactor|
        interactor.call if context.host.compute? && context.hardware
      rescue LiudeskCMDB::NotFoundError
        # Already removed, nothing to do
      end

      def call
        # FIXME: This is temporary until deprecation supports MAC reuse
        context.hardware.mac_and_network_access_roles = nil
        context.hardware.patch! if context.hardware.changed?

        context.hardware.delete!
      rescue StandardError => e
        ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                          .error("#{self.class} error #{e}: #{e.backtrace}")
        context.fail!(error: "#{self.class}: #{e}")
      end
    end
  end
end
