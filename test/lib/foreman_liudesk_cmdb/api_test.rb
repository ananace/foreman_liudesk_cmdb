# frozen_string_literal: true

require "test_plugin_helper"

class CMDBAPITest < ActiveSupport::TestCase
  setup do
    setup_default_cmdb_settings
  end

  context "when reading network roles" do
    it "generates a valid cache key" do
      key = ForemanLiudeskCMDB::Api.send :cache_key

      assert key

      Setting[:liudesk_cmdb_token] += "2"

      refute_equal key, ForemanLiudeskCMDB::Api.send(:cache_key)
    end

    it "caches the result" do
      stub_get = stub_request(:get, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/networkaccessroles").to_return(
        status: 200,
        body: %w[
          None
          Guest
        ].to_json
      )

      roles = ForemanLiudeskCMDB::Api.network_access_roles

      assert_equal %w[Guest None], roles.sort

      remove_request_stub(stub_get)

      assert_equal roles, ForemanLiudeskCMDB::Api.network_access_roles
      assert_equal roles, ForemanLiudeskCMDB::Api.network_access_roles
    end

    it "handles errors" do
      stub_request(:get, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/networkaccessroles").to_return(
        status: 400,
        body: {}.to_json
      ).times(2)

      assert_equal %w[None], ForemanLiudeskCMDB::Api.network_access_roles
      assert_equal %w[None], ForemanLiudeskCMDB::Api.network_access_roles
    end
  end
end
