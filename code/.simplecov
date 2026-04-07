SimpleCov.start do
  command_name ENV['SIMPLECOV_COMMAND_NAME'] || 'rspec'
  enable_coverage :branch
end
