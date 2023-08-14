# frozen_string_literal: true

FactoryBot.modify do
  factory :host do
    trait :with_liudesk_cmdb_facet do
      association :liudesk_cmdb_facet, factory: :liudesk_cmdb_facet, strategy: :build
    end

    trait :with_device_liudesk_cmdb_facet do
      association :liudesk_cmdb_facet, factory: %i[liudesk_cmdb_facet with_device_raw_data]
    end
  end
end
