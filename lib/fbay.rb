require "mongo_mapper"
require "fbay/version"
require "fbay/utils/set_state"
require "fbay/core"
require "fbay/auction"
require "fbay/participant"
require "fbay/item"
require "fbay/bid"

module Fbay
end

# setup MongoMapper connection to local mongo
MongoMapper.setup({'test' => {'uri' => 'mongodb://localhost:27017/fbay_test'}}, 'test')
