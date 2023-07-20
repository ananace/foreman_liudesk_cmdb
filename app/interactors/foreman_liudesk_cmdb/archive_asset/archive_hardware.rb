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
        context.hardware.delete!
      rescue StandardError => e
        ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                          .error("#{self.class} error #{e}: #{e.backtrace}")
        context.fail!(error: "#{self.class}: #{e}")
      end
    end
  end
end
