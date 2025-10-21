# frozen_string_literal: true

require_relative "foreman_liudesk_cmdb/version"
require_relative "foreman_liudesk_cmdb/engine"

module ForemanLiudeskCMDB
  class Error < StandardError; end

  # Asset object was lost, likely removed by external part
  class AssetLostError < Error; end
  # Hardware object was lost, likely removed by external part
  class HardwareLostError < Error; end
end
