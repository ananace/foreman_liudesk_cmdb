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
        asset: asset_params,
        hardware: hardware_params
      }
    end

    private

    attr_accessor :host

    def asset_params
      host.liudesk_cmdb_facet.asset_parameter_keys.map { |param| send("find_asset_#{param}") }.inject({}, :merge)
    end

    def hardware_params
      host.liudesk_cmdb_facet.hardware_parameter_keys.map { |param| send("find_hardware_#{param}") }.inject({}, :merge)
    end

    def find_asset_hostname
      { hostname: host.name }
    end

    def find_asset_network_access_role
      { network_access_role: host.liudesk_cmdb_facet.asset? ? nil : "None" }.compact
    end

    def find_asset_operating_system
      { operating_system: host.os&.title || "N/A" }
    end

    def find_asset_operating_system_type
      { operating_system: host.os&.name || "N/A" }
    end

    def find_asset_operating_install_date
      { operating_system: host.installed_at&.round }.compact
    end

    def find_asset_management_system
      { management_system: host.managed? ? "ITI-Foreman" : nil }.compact
    end

    def find_asset_management_system_id
      { management_system_id: host.managed? ? "#{SETTINGS[:fqdn]}/#{id}" : nil }.compact
    end

    def find_asset_foreman_url
      { foreman_link: host.managed? ? "https://#{SETTINGS[:fqdn]}/hosts/#{fqdn}" : nil }.compact
    end

    def find_asset_certificate_information
      { certificate_information: host.certname }
    end

    def find_asset_network_certificate_ca
      { network_certificate_ca: "PUPPETCA" }
    end

    def find_hardware_make
      { make: host.facts["dmi::manufacturer"] || host.facts["manufacturer"] || "N/A" }
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
      {
        mac_and_network_access_roles: host.interfaces.map do |iface|
          next unless iface.mac

          {
            mac: iface.mac&.upcase,
            networkAccessRole: host.liudesk_cmdb_facet&.asset? ? nil : "None"
          }.compact
        end
      }
    end
  end
end
