ENV['RAILS_ENV'] ||= 'test'

require 'bundler/setup'

require 'simplecov'
SimpleCov.start do
  add_filter %r{^/spec/}
  minimum_coverage 86.70
end

require 'timeout'
require 'dotenv/load'
require 'faker'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'meilisearch-rails'
require 'rspec'
require 'rails/all'

require 'support/dummy_classes'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |file| require file }

RSpec.configure do |c|
  c.mock_with :rspec
  c.filter_run focus: true
  c.run_all_when_everything_filtered = true
  c.formatter = 'documentation'

  c.around do |example|
    Timeout.timeout(120) do
      example.run
    end
  end

  # Remove all indexes setup in this run in local or CI
  c.after(:suite) do
    MeiliSearch::Rails.configuration = {
      meilisearch_host: ENV.fetch('MEILISEARCH_HOST', 'http://127.0.0.1:7700'),
      meilisearch_api_key: ENV.fetch('MEILISEARCH_API_KEY', 'masterKey')
    }

    safe_index_list.each do |index|
      MeiliSearch::Rails.client.delete_index(index.uid)
    end
  end
end
