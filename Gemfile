source 'https://rubygems.org'

ruby '2.6.3'

gem 'dotenv-rails'
gem 'rails', '~> 5.2.5'
gem 'pg', '>= 0.18', '< 2.0'

# REVIEW
# gem 'postgres_ext', '~> 3.0.1'

gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.2.0'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.5'

# REVIEW
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc
gem 'autoprefixer-rails'
gem 'kaminari'   # pagination
gem 'bootstrap-sass'

gem 'puma', '~> 3.11'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'pundit'
gem 'simple_form'
gem 'slim-rails'
gem 'jquery-rails', '~> 4.3.3'
gem 'lodash-rails', '~> 4.17.10'
gem 'sorcery', '~> 0.12.0'

# REVIEW
gem 'virtus', require: false
gem 'whiny_validation'
gem 'validates_email_format_of', '~> 1.6.3'

gem 'stripe', '~> 3.17.0'
gem 'sparkpost_rails', '~> 1.5.1'

group :development, :test do
  # REVIEW
  gem 'database_cleaner'
  gem 'faker'

  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'factory_bot_rails'
  gem 'rspec-rails', '~> 3.7'

  # gem 'guard', '~> 2.13.0', require: false
  # gem 'guard-livereload', require: false
  # gem 'rack-livereload'
  # gem 'rb-fsevent', require: false
  gem 'guard-rails', require: false
  gem 'guard-rspec', require: false
end

group :development do
  # REVIEW
  # gem 'better_errors'
  # gem 'binding_of_caller'
  # gem 'capistrano', '~> 3.4.0'
  # gem 'capistrano-bundler', '~>1.1.4'
  # gem 'capistrano-rails', '~> 1.1.5'
  # gem 'capistrano-rbenv', '~> 2.0.3'
  # gem 'pry-rails'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  # REVIEW
  gem 'spring-commands-rspec'
end

group :test do
  # REVIEW
  gem 'shoulda-matchers', '~> 3.0.0.rc1', require: false
  gem 'vcr', '~> 3.0.0'
  gem 'webmock', '~> 1.22.3'
  gem 'rails-controller-testing'
end

group :production do
  gem 'rails_12factor'
end
