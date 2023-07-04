# frozen_string_literal: true

module ForemanLiudeskCMDB
  # Main hostgroup facet
  #
  # Only tracks coarse asset type to ease configuration across hostgroups
  class LiudeskCMDBHostgroupFacet < ApplicationRecord
    # Allow the use of the configured asset type in jails
    class Jail < Safemode::Jail
      allow :asset_type
    end

    include Facets::Base

    belongs_to :liudesk_cmdb_server,
               class_name: "LiudeskCMDBServer",
               inverse_of: :liudesk_cmdb_hostgroup_facets

    validates_lengths_from_database

    validates :asset_type, presence: true
  end
end
