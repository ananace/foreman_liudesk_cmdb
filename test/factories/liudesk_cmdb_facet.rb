# frozen_string_literal: true

FactoryBot.define do
  factory :liudesk_cmdb_facet, class: "ForemanLiudeskCMDB::LiudeskCMDBFacet" do
    host
    sync_at { Time.zone.now }
    hardware_id { "example_hardware_id" }
    asset_id { "hostname.localhost.localdomain" }
    asset_type { "server_v1" }

    trait :with_device_raw_data do
      raw_data do
        JSON.parse(File.read(File.join(File.dirname(__dir__), "fixtures", "liudesk_cmdb_device_raw_data.json")))
      end
    end
  end
end
