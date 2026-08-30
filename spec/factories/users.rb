FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "contraseña-larga-123" }
    association :role
  end
end
