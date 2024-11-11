# frozen_string_literal: true

require "test_plugin_helper"

class RemoveOnTypeChangeAssetTest < ActiveSupport::TestCase
  subject do
    ForemanLiudeskCMDB::SyncAsset::RemoveOnTypeChange.call(
      host: host,
      asset: LiudeskCMDB::Models::LinuxClientV1.new(
        ForemanLiudeskCMDB::API.client,
        hostname
      ),
      cmdb_params: host.liudesk_cmdb_facet.asset_parameters
    )
  end

  let(:hostname) { "host.dev.example.com" }
  let(:asset_type) { "server" }
  let(:old_asset_type) { "linux_client_v1" }
  let(:raw_data) { { asset_type: old_asset_type } }
  let(:network_role) { nil }
  let(:asset_id) { hostname }
  let(:hardware_id) { "c1de1e3d-5a3f-45b8-9dde-26e4f38872c0" }
  let(:host) do
    FactoryBot.build_stubbed(:host, hostname: hostname).tap do |host|
      facet = host.build_liudesk_cmdb_facet
      facet.asset_type = asset_type
      facet.network_role = network_role
      facet.hardware_id = hardware_id
      facet.asset_id = asset_id
      facet.raw_data = raw_data
    end
  end

  setup do
    setup_default_cmdb_settings
  end

  context "when no cached data is available" do
    let(:raw_data) { nil }
    it "does not execute" do
      assert subject.success?
      assert subject._called.empty?
      assert subject.asset
    end
  end

  context "when cached data is available" do # rubocop:disable Metrics/BlockLength
    context "when asset type is the same" do
      let(:asset_type) { "client" }

      it "does not execute" do
        assert subject.success?
        assert subject._called.empty?
        assert subject.asset
      end
    end

    context "when asset type is different" do
      it "removes the old asset" do
        Time.stubs(:now).returns(Time.new(2020, 1, 1))
        stub_patch = stub_request(:patch, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Clients/linux/#{hostname}").with( # rubocop:disable Layout/LineLength
          body: {
            hostName: "c-#{Time.now.to_i.to_s(36)}-#{hostname}"
          }
        ).to_return(
          status: 201,
          body: {
            hostName: "modified-hostname"
          }.to_json
        )
        stub_delete = stub_request(:delete, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Clients/linux/modified-hostname").to_return( # rubocop:disable Layout/LineLength
          status: 200
        )

        assert subject.success?
        refute subject.asset
        refute host.liudesk_cmdb_facet.asset_id
        assert_requested stub_patch
        assert_requested stub_delete
      end

      it "handles errors correctly" do
        Time.stubs(:now).returns(Time.new(2020, 1, 1))
        stub_patch = stub_request(:patch, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Clients/linux/#{hostname}").to_return( # rubocop:disable Layout/LineLength
          status: 400,
          body: {}.to_json
        )

        refute subject.success?
        assert subject.asset
        assert host.liudesk_cmdb_facet.asset_id
        assert_requested stub_patch
      end
    end
  end
end
