# frozen_string_literal: true

module ForemanLiudeskCMDB
  module HostsControllerExtensions
    extend ActiveSupport::Concern

    def host_params
      return super unless params[:host][:liudesk_cmdb_facet_attributes]

      nic_params = []
      params[:host][:interfaces_attributes].each do |_, iface|
        next unless iface[:liudesk_cmdb_facet_attributes]

        nic_params << {
          identifier: iface[:identifier].nil? || iface[:identifier].empty? ? nil : iface[:identifier],
          mac: iface[:mac],
          role: iface.delete(:liudesk_cmdb_facet_attributes)[:network_role]
        }.compact
      end

      copy = super
      copy[:liudesk_cmdb_facet_attributes].merge!(hardware_network_roles: nic_params)

      copy
    end
  end
end
