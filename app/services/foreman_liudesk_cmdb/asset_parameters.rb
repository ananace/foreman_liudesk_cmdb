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

    def asset_param_sources
      params = %i[hostname operating_system]
      params << :management_system if host.managed?
      params << :network_access if \
        !host.persisted? || !host.liudesk_cmdb_facet&.persisted? || host.liudesk_cmdb_facet&.client?
      params
    end

    def asset_params
      asset_param_sources.map { |param| send(param) }.inject({}, :merge)
    end

    def hardware_param_sources
      %i[manufacturer_and_model bios_info hardware_networking]
    end

    def hardware_params
      hardware_param_sources.map { |param| send(param) }.inject({}, :merge)
    end

    private

    attr_accessor :host

    def hostname
      {
        hostname: host.name
      }
    end

    def operating_system
      {
        operating_system: host.os&.title || "N/A",
        operating_system_type: host.os&.name || "N/A",
        operating_system_install_date: host.installed_at&.round
      }.compact
    end

    def management_system
      {
        management_system: "ITI-Foreman",
        management_system_id: "#{SETTINGS[:fqdn]}/#{id}",
        foreman_link: "https://#{SETTINGS[:fqdn]}/hosts/#{fqdn}"
      }
    end

    def network_access
      params = {
        network_access_role: host.liudesk_cmdb_facet&.asset? ? nil : "None"
      }
      return params.compact unless host.liudesk_cmdb_facet&.client?

      params[:certificate_information] = host.certname
      params[:network_certificate_ca] = "PUPPETCA"
      params.compact
    end

    def manufacturer_and_model
      make = host.facts["dmi::manufacturer"] || host.facts["manufacturer"] || "N/A"
      model = host.facts["dmi::product::name"] || host.facts["productname"]

      model = model&.sub(make, "")&.strip if model&.start_with? make
      model = "N/A" if model.nil? || model.empty?

      {
        make: make,
        model: model
      }
    end

    def bios_info
      {
        serial_number: host.facts["dmi::product::serial_number"] || host.facts["serialnumber"],
        bios_uuid: host.facts["dmi::product::uuid"] || host.facts["uuid"]
      }.compact
    end

    def hardware_networking
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
