module Cuke
  module Paths
    GEM_ROOT = File.expand_path('../../..', __FILE__).freeze
    DUDE_BIN = File.join(GEM_ROOT, 'bin', 'dude').freeze
    DUDE_LIB = File.join(GEM_ROOT, 'lib').freeze
    DEV_NULL = { out: '/dev/null', err: '/dev/null' }
  end
end
