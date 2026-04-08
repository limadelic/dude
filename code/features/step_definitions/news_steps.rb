require_relative '../../lib/cuke/dude'
require_relative '../../lib/cuke/news'
require_relative '../../lib/cuke/activity_server'

World(Cuke::Dude)
World(Cuke::News)

Before('@wip') do
  Cuke::ActivityServer.start
end

After('@wip') do
  ENV.delete('DUDE_NEWS_MOCK')
  ENV.delete('CC_VERSION')
end

Given('CC is installed at {string}') do |version|
  setup_installed_version(version)
end

Given('latest CC release is {string}') do |version|
  setup_latest_version(version)
end

Given('GHA workflow conclusion is {string}') do |conclusion|
  setup_workflow_conclusion(conclusion)
end


Then('news shows {string}') do |text|
  pending("kenny: implement dude news")
  output = dude('news').strip
  raise "Expected '#{text}' in output, got: #{output}" unless output.include?(text)
end

Then('news starts with {string}') do |text|
  pending("kenny: implement dude news")
  output = dude('news').strip
  first_line = output.split("\n").first
  raise "Expected '#{text}' at start, got: #{first_line}" unless first_line&.include?(text)
end

Then('news lists {int} releases') do |count|
  pending("kenny: implement dude news")
  output = dude('news').strip
  releases = (1..count).map { |i| "v2.1.#{96 - i}" }
  releases.each do |release|
    raise "Expected release #{release} in output, got: #{output}" unless output.include?(release)
  end
end
