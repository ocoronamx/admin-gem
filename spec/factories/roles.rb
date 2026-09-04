FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "Rol #{n}" }
    sequence(:key) { |n| "rol_#{n}" }
  end
end
