# frozen_string_literal: true

FactoryBot.define do
  factory :liudesk_cmdb_hostgroup_facet, class: "ForemanLiudeskCMDB::LiudeskCMDBHostgroupFacet" do
    hostgroup
    asset_type { "server_v1" }
  end
end
