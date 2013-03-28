FactoryGirl.define do
  sequence(:email) {|n| "person-#{n}@example.com" }

  factory :admin, :class => :'Releaf::Admin' do
    email
    name                  'admin'
    surname               'admin'
    password              'password'
    password_confirmation 'password'
  end

  factory :role, :class => :'Releaf::Role' do
    sequence(:name) {|n| "role #{n}"}

    trait :admin do
      releaf_content_permission true
      releaf_translations_permission true
      releaf_admins_permission true
      releaf_roles_permission true
    end

    trait :default do
      default true
    end
  end

end