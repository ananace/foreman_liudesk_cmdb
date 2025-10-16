# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
Foreman::Plugin.register :foreman_liudesk_cmdb do
  requires_foreman ">= 3.12"

  register_info_provider ForemanLiudeskCMDB::HostInfoProvider
  register_custom_status HostStatus::CMDBStatus

  register_facet ForemanLiudeskCMDB::LiudeskCMDBFacet, :liudesk_cmdb_facet do
    configure_host do
      set_dependent_action :destroy

      extend_model ForemanLiudeskCMDB::HostExtensions
    end

    configure_hostgroup ForemanLiudeskCMDB::LiudeskCMDBHostgroupFacet do
      set_dependent_action :destroy
    end
  end

  parameter_filter Host::Managed, liudesk_cmdb_facet_attributes: [
    :asset_type, :hardware_fallback_role, :hardware_network_roles, :network_role,
    { ephemeral_attributes: [{ asset: {} }, { hardware: {} }] }
  ]
  parameter_filter Hostgroup, liudesk_cmdb_facet_attributes: %i[
    asset_type hardware_fallback_role network_role
  ]
  parameter_filter(Nic::Interface) { |ctx| ctx.permit(:network_access_role) if ctx.nested? }

  settings do
    category(:liudesk_cmdb, N_("CMDB")) do
      setting "liudesk_cmdb_url",
              type: :string,
              default: "https://api.test.it.liu.se",
              full_name: N_("CMDB API URL"),
              description: N_("URL where the CMDB API is located")
      setting :liudesk_cmdb_token,
              type: :string,
              default: "-",
              full_name: N_("CMDB API Token"),
              description: N_("Access token for the CMDB API")
      setting :liudesk_cmdb_orchestration_enabled,
              type: :boolean,
              default: false,
              full_name: N_("CMDB Orchestration"),
              description: N_("Enable CMDB Orchestration")
    end
  end

  logger :sync, enabled: true

  extend_page("hosts/_form") do |ctx|
    ctx.add_pagelet(
      :main_tabs,
      id: :cmdb,
      name: _("CMDB"),
      partial: "hosts/form_liudesk_cmdb_tab",
      priority: 9001,
      onlyif: lambda do |host, _context|
        # Skip rendering tab
        host.liudesk_cmdb_facet && caller.none? { |call| call.include?("block in render_tab_header_for") }
      end
    )

    ctx.add_pagelet(
      :main_tab_fields,
      partial: "foreman_liudesk_cmdb/host_cmdb_options"
    )
  end
  extend_page("hostgroups/_form") do |ctx|
    ctx.add_pagelet(
      :main_tab_fields,
      partial: "foreman_liudesk_cmdb/host_cmdb_options"
    )
  end
  extend_page("hosts/show") do |ctx|
    ctx.add_pagelet(
      :main_tabs,
      name: _("CMDB"),
      partial: "foreman_liudesk_cmdb/liudesk_cmdb_facet",
      onlyif: proc { |h| h.liudesk_cmdb_facet } # rubocop:disable Style/SymbolProc -- Does not work with caller
    )
  end
end
# rubocop:enable Metrics/BlockLength
