# frozen_string_literal: true

require "test_plugin_helper"

class CreateAssetTest < ActiveSupport::TestCase
  subject do
    ForemanLiudeskCMDB::SyncAsset::Create.call(
      host: host,
      cmdb_params: host.liudesk_cmdb_facet.asset_parameters,
      asset: asset
    )
  end

  let(:hostname) { "host.dev.example.com" }
  let(:asset_type) { "server" }
  let(:network_role) { nil }
  let(:asset_id) { nil }
  let(:asset) { nil }
  let(:hardware_id) { "c1de1e3d-5a3f-45b8-9dde-26e4f38872c0" }
  let(:host) do
    FactoryBot.build_stubbed(:host, hostname: hostname).tap do |host|
      host.stubs(:facts).returns({ "serialnumber" => "abc123" })

      facet = host.build_liudesk_cmdb_facet
      facet.asset_type = asset_type
      facet.hardware_id = hardware_id
      facet.asset_id = asset_id
    end
  end

  setup do
    setup_default_cmdb_settings
  end

  context "when asset is not assigned to the facet" do
    let(:asset_id) { nil }

    it "creates an asset" do
      stub_post = stub_request(:post, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Server").with(
        body: {
          hostName: hostname,
          hardwareID: hardware_id,
          operatingSystemType: "N/A",
          operatingSystem: "N/A",
          managementSystem: "ITI-Foreman",
          managementSystemId: "#{SETTINGS[:fqdn]}/#{host.id}",
          foremanLink: "https://#{SETTINGS[:fqdn]}/hosts/#{host.name}"
        }
      ).to_return(
        status: 201,
        body: {
          hardwareID: hardware_id,
          hostName: hostname
        }.to_json
      )

      assert subject.success?
      assert_equal hostname, subject.asset.identifier
      assert_requested stub_post
    end

    it "handles errors correctly" do
      stub_post = stub_request(:post, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Server").to_return(
        status: 400,
        body: {}.to_json
      )

      refute subject.success?
      refute subject.asset
      assert_requested stub_post
    end

    context "when asset is attached to the context" do
      let(:asset) { OpenStruct.new identifier: hostname }

      it "does not create an asset" do
        assert subject.success?
        assert subject._called.empty?
        refute_requested stub_request(:post, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Server")
      end
    end
  end

  context "when asset is already assigned to the facet" do
    let(:asset_id) { hostname }

    it "does not create an asset" do
      assert subject.success?
      refute subject.asset
      refute_requested stub_request(:post, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Server")
    end
  end
end
