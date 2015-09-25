source 'https://rubygems.org'
ruby '2.2.3'

gem 'rails', '4.2.4'
gem 'pg'
gem 'postgres_ext'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'turbolinks'
gem 'jbuilder', '~> 2.0'

# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'autoprefixer-rails'
gem 'kaminari'   # pagination
gem 'puma'
gem 'pundit'
gem 'bootstrap-sass'
gem 'simple_form'
gem 'slim-rails'
gem 'sorcery', '~> 0.9.1'
gem 'virtus', require: false
gem 'whiny_validation'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  gem 'dotenv-rails'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'rspec-rails', '~> 3.3.3'
  gem 'guard', '~> 2.13.0', require: false
  gem 'guard-livereload', require: false
  gem 'guard-rspec', require: false
  gem 'rack-livereload'
  gem 'rb-fsevent', require: false
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'pry-rails'
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'
  gem 'spring'
  gem 'spring-commands-rspec'
end

group :test do
  gem 'shoulda-matchers', require: false
end
