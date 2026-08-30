FactoryBot.define do
  factory :permission do
    sequence(:key) { |n| "recurso_#{n}.view" }
  end
end
