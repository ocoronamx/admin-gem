FactoryBot.define do
  factory :user do
    email_address { Faker::Internet.unique.email }
    password { "contraseña-larga-123" }
    association :role
  end
end
