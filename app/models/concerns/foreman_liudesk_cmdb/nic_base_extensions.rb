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

    def network_access_role=(new_role)
      puts "For #{self}: Changing role to #{new_role}"

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
