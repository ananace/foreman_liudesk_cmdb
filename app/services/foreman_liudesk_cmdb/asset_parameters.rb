# frozen_string_literal: true

module ForemanLiudeskCMDB
  # Asset parameters retrieval helper
  class AssetParameters
    def self.call(host)
      new(host).call
    end

    def initialize(host)
      @host = host
    end

    def call
      {
        asset: asset_params.merge(facet.ephemeral_attributes[:asset]),
        asset_type: host.liudesk_cmdb_facet.asset_model_type,
        hardware: hardware_params.merge(facet.ephemeral_attributes[:hardware]),
        hardware_type: host.liudesk_cmdb_facet.hardware_model_type
      }
    end

    private

    attr_accessor :host

    def facet
      host.liudesk_cmdb_facet
    end

    def asset_params
      facet.asset_parameter_keys.map { |param| send("find_asset_#{param}") }.inject({}, :merge)
    end

    def hardware_params
      facet.hardware_parameter_keys.map { |param| send("find_hardware_#{param}") }.inject({}, :merge)
    end

    def find_asset_hostname
      { hostname: host.name }
    end

    def find_asset_network_access_role
      role = facet.deep_network_role
      role = nil if role&.empty?
      role = nil unless facet.asset_parameter_keys.include? :certificate_information

      {
        network_access_role: role
      }.compact
    end

    def find_asset_operating_system
      { operating_system: host.os&.title || "N/A" }
    end

    def find_asset_operating_system_type
      { operating_system_type: host.os&.name || "N/A" }
    end

    def find_asset_operating_system_install_date
      { operating_system_install_date: host.installed_at&.round }.compact
    end

    def find_asset_management_system
      { management_system: "ITI-Foreman" }
    end

    def find_asset_management_system_id
      { management_system_id: "#{SETTINGS[:fqdn]}/#{host.id}" }
    end

    def find_asset_foreman_link
      { foreman_link: "https://#{SETTINGS[:fqdn]}/hosts/#{host.fqdn}" }
    end

    def find_asset_certificate_information
      { certificate_information: host.certname || host.fqdn }
    end

    def find_asset_network_certificate_ca
      { network_certificate_ca: "PUPPETCA" }
    end

    def find_hardware_make
      manufacturer = host.facts["dmi::manufacturer"] || host.facts["manufacturer"] || "N/A"
      manufacturer = manufacturer.sub(%r{ // .+$}, "") # Make FUJITSU friendlier in CMDB

      { make: manufacturer }
    end

    def find_hardware_model
      make = find_hardware_make[:make]
      model = host.facts["dmi::product::name"] || host.facts["productname"]

      model = model&.sub(make, "")&.strip if model&.start_with? make
      model = "N/A" if model.nil? || model.empty?

      { model: model }
    end

    def find_hardware_bios_uuid
      { bios_uuid: host.facts["dmi::product::uuid"] || host.facts["uuid"] }.compact
    end

    def find_hardware_serial_number
      { serial_number: host.facts["dmi::product::serial_number"] || host.facts["serialnumber"] }.compact
    end

    def find_hardware_mac_and_network_access_roles
      roles = {}
      host.interfaces.select { |iface| iface&.mac }.compact.each do |iface|
        roles[iface.mac.upcase] ||= iface.deep_network_access_role
      end

      {
        mac_and_network_access_roles: roles.map do |mac, role|
          {
            mac: mac,
            networkAccessRole: role || "None"
          }.compact
        end
      }
    end
  end
end
