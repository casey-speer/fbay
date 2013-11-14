$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'fbay'

# kill the mongo test db before each spec
def kill_mongo
  MongoMapper.database.collections.select {|c| c.name !~ /system/ }.each(&:drop)
end

RSpec.configure do |config|
  config.before(:suite) do
    kill_mongo
  end
  config.after(:each) do
    kill_mongo
  end
end
