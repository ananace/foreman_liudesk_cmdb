# frozen_string_literal: true

FactoryBot.modify do
  factory :hostgroup do
    trait :with_liudesk_cmdb_facet do
      association :liudesk_cmdb_facet, factory: :liudesk_cmdb_hostgroup_facet, strategy: :build
    end
  end
end
