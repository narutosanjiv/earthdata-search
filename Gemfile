source 'https://rubygems.org'

gem 'rails', '~> 5.0.0'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'faraday'
gem 'faraday_middleware'
gem 'multi_xml'
gem 'toastr-rails'
gem 'unicorn', '>= 4.9.0'
gem 'whenever', :require => false

gem 'obfuscate_id', git: 'https://github.com/namick/obfuscate_id.git', ref: 'a89da600f389c53c88362ce5133d8d3945776464'

group :test do
  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'factory_girl_rails', '>= 4.5.0'
  gem 'capybara', '>= 2.2.0'
  # This is a revision which disables screenshots, one behind the disable-screenshots
  #  branch, which also tries (and fails) to avoid problems with concurrent test runs.
  gem 'capybara-webkit', git: 'https://github.com/bilts/capybara-webkit.git', branch: 'disable-screenshots'
  gem 'poltergeist', '>= 1.5.1'
  gem 'capybara-screenshot', '>= 0.3.20'
  gem 'rspec_junit_formatter'
  gem 'fuubar'
  gem "rack_session_access", ">= 0.2.0"
  gem 'headless'
end

group :development do
  gem 'quiet_assets', '>= 1.0.3'

  # For dumping additional metadata stored in DatasetExtras and similar
  gem 'seed_dump'
end

group :production do
  gem 'pg'
end

# Gems that are mostly used for testing but useful to have available via CLI
group :development, :test do
  gem 'thin', '>= 1.6.2'
  gem 'rspec-rails', '>= 2.99.0'
  gem 'colored'
  gem 'vcr'
  gem 'sqlite3'
  gem 'knapsack'

  gem 'jasmine', '>= 2.1.0'
  gem 'jasmine_junitxml_formatter', '>= 0.2.0'

  gem 'therubyracer', :require => 'v8'
  gem 'libv8', '~> 3.11.8.3'

end

group :assets, :development, :test do
  gem 'execcsslint' # CSS Lint
  gem 'deadweight' # Finds unused styles
end

# Gems used only for assets and not required
# in production environments by default.
group :assets, :test do
  gem 'sass-rails', '~> 5.0.5'
  gem 'coffee-script', :require => 'coffee_script'
  gem 'coffee-rails', '~> 4.1.1'

  gem 'uglifier', '>= 1.3.0'
end

gem 'jquery-rails', '>= 4.0.1'
gem 'bourbon'
gem 'knockoutjs-rails', '>= 3.4.0.1'
gem 'figaro', '>= 1.0.0'

gem 'delayed_job_active_record'
gem 'daemons'

gem 'nokogiri'

# Eventually we'll need these, but there's version conflict when installing
#gem 'crossroadsjs-rails'
#gem 'jssignals-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'
