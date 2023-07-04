# frozen_string_literal: true

module ForemanLiudeskCMDB
  class LiudeskCMDBHostgroupFacet < ApplicationRecord
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
