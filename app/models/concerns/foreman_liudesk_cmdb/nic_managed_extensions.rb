# frozen_string_literal: true

module ForemanLiudeskCMDB
  module NicManagedExtensions
    extend ActiveSupport::Concern

    def network_access_role
      return unless mac
      return unless host&.liudesk_cmdb_facet

      roles = host.liudesk_cmdb_facet.hardware_network_roles || []
      roles.find { |role| role["identifier"] == identifier || role["mac"] == mac }&.fetch("role", nil)
    end

    def network_access_role=(new_role)
      return unless mac
      return unless host&.liudesk_cmdb_facet

      roles = host.liudesk_cmdb_facet.hardware_network_roles || []
      found = roles.find { |role| role["identifier"] == identifier || role["mac"] == mac }
      unless found
        found = {
          "identifier" => identifier,
          "mac" => mac
        }
        roles << found
      end

      found["role"] = new_role
      found.compact!

      host.liudesk_cmdb_facet.hardware_network_roles = roles
    end
  end
end
