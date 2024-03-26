# frozen_string_literal: true

module ForemanLiudeskCMDB
  # Extensions for Nic::Base to handle per-NIC network roles
  module NicBaseExtensions
    extend ActiveSupport::Concern

    def network_access_role
      return unless mac
      return unless host&.liudesk_cmdb_facet

      roles = host.liudesk_cmdb_facet.hardware_network_roles || {}
      roles[mac.downcase]&.fetch("role", nil)
    end

    def deep_network_access_role
      role = network_access_role ||
             host&.liudesk_cmdb_facet&.deep_hardware_fallback_role
      return nil if role.nil? || role.empty?

      role
    end

    def network_access_role=(new_role)
      return unless mac
      return unless host&.liudesk_cmdb_facet

      roles = host.liudesk_cmdb_facet.hardware_network_roles || {}
      found = roles[mac.downcase]

      unless found
        found = {}
        roles[mac] = found
      end

      found["role"] = new_role
      found.compact!

      host.liudesk_cmdb_facet.hardware_network_roles = roles
    end
  end
end
