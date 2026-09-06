FactoryBot.define do
  factory :role do
    name { Faker::Job.unique.title }
    key { name.parameterize.underscore }
  end
end
