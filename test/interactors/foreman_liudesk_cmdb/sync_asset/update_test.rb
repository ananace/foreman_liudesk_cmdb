# frozen_string_literal: true

require "test_plugin_helper"

class UpdateAssetTest < ActiveSupport::TestCase
  subject do
    ForemanLiudeskCMDB::SyncAsset::Update.call(
      host: host,
      asset: asset,
      cmdb_params: host.liudesk_cmdb_facet.asset_parameters,
      cached_params: host.liudesk_cmdb_facet.cached_asset_parameters
    )
  end

  let(:hostname) { "host.dev.example.com" }
  let(:asset_type) { "server" }
  let(:network_role) { nil }
  let(:asset_id) { hostname }
  let(:hardware_id) { "c1de1e3d-5a3f-45b8-9dde-26e4f38872c0" }
  let(:wanted_asset_data) do
    {
      hostname: hostname,
      hardware_id: hardware_id,
      network_access_role: "Guest",
      operating_system: "Debian 10.0",
      operating_system_type: "Debian",
      operating_system_install_date: "2021-12-31T23:00:00.000Z",
      management_system: "ITI-Foreman",
      management_system_id: "#{SETTINGS[:fqdn]}/1",
      foreman_link: "https://#{SETTINGS[:fqdn]}/hosts/#{hostname}"
    }
  end
  let(:current_asset_data) do
    {
      hostname: "#{hostname}-old",
      hardware_id: hardware_id,
      network_access_role: "None",
      operating_system: "N/A",
      operating_system_type: "N/A"
    }
  end
  let(:raw_data) do
    {
      asset: wanted_asset_data,
      asset_type: "server_v1"
    }
  end
  let(:host) do
    FactoryBot.build_stubbed(:host, hostname: hostname).tap do |host|
      host.os = FactoryBot.build_stubbed(:operatingsystem, name: "Debian") do |os|
        os.major = "10"
        os.minor = "0"
        os.title = "Debian 10.0"
      end
      host.installed_at = Time.utc(2021, 12, 31, 23, 0, 0)
      host.managed = true
      host.id = 1

      facet = host.build_liudesk_cmdb_facet
      facet.asset_type = asset_type
      facet.network_role = network_role
      facet.hardware_id = hardware_id
      facet.asset_id = asset_id
      facet.raw_data = raw_data
    end
  end
  let(:asset) do
    LiudeskCMDB::Models::ServerV1.new(
      ForemanLiudeskCMDB::API.client,
      asset_id
    )
  end

  setup do
    setup_default_cmdb_settings
  end

  context "when asset is not assigned" do
    let(:asset) { nil }
    it "does not execute" do
      assert subject.success?
      assert subject._called.empty?
    end
  end

  context "when asset is unmodified" do
    it "does nothing" do
      assert subject.success?
      refute subject._called.empty?
      refute_requested stub_request(:patch, "#{Setting[:liudesk_cmdb_url]}/#{asset.api_url}")
    end
  end

  context "when asset is modified" do
    let(:asset_id) { "#{hostname}-old" }
    let(:raw_data) { { asset: current_asset_data } }

    it "updates asset" do
      host.liudesk_cmdb_facet.network_role = "Guest"
      updated = {
        hostName: hostname,
        networkAccessRole: "Guest",
        operatingSystemType: "Debian",
        operatingSystem: "Debian 10.0",
        operatingSystemInstallDate: "2021-12-31T23:00:00.000Z",
        managementSystem: "ITI-Foreman",
        managementSystemId: "#{SETTINGS[:fqdn]}/1",
        foremanLink: "https://#{SETTINGS[:fqdn]}/hosts/#{hostname}"
      }
      stub_patch = stub_request(:patch, "#{Setting[:liudesk_cmdb_url]}/#{asset.api_url}").with(
        body: updated.to_json
      ).to_return(
        status: 200,
        body: updated.merge(
          hardwareID: hardware_id
        ).to_json
      )

      assert subject.success?
      assert_requested(stub_patch)
    end
  end
end
