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

    include Facets::HostgroupFacet

    validates_lengths_from_database

    validates :hostgroup, presence: true, allow_blank: false
    validates :asset_type, presence: true

    class << self
      def attributes_to_inherit
        @attributes_to_inherit ||= attribute_names - %w[id hostgroup_id created_at updated_at]
      end
    end

    inherit_attributes(*%w[asset_type])
  end
end
