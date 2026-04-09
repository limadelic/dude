require 'rspec/mocks/standalone'
require_relative '../../lib/dude/helpers/gh'
require_relative '../../lib/dude/news/news'
require_relative '../../lib/dude/news/paperboy'
require_relative '../../lib/dude/news/sommelier'

World(RSpec::Mocks::ExampleMethods)

Before('@news') do
  @mocks = {}
end

After('@news') do
  ENV.delete('CC_VERSION')
end

When(/^! (.+)$/) do |cmd, *rest|
  table = rest.flatten.compact.first
  @mocks ||= {}
  if table
    values = table.raw.flatten.map(&:strip)
    @mocks[cmd] = values.size == 1 ? values.first : values.join("\n")
  end
end

When(/^> \/news(.*)$/) do |args, table|
  @mocks ||= {}

  @mocks.each do |cmd, val|
    ENV['CC_VERSION'] = val if cmd.include?('claude --version')
  end

  mocks = @mocks
  gh = instance_double(Dude::Helpers::Gh)
  allow(gh).to receive(:run) do |run_cmd|
    match = mocks.find do |pattern, _|
      key = pattern.sub(/^gh\s+/, '')
      key.split.all? { |word| run_cmd.include?(word) }
    end
    match ? match[1] : ''
  end

  limit_match = args&.match(/--limit\s+(\d+)/)
  limit = limit_match ? limit_match[1].to_i : 5

  paperboy = Dude::News::Paperboy.new(gh: gh)
  sommelier = Dude::News::Sommelier.new(gh: gh)

  output = capture_output do
    Dude::News::News.new(
      limit: limit,
      paperboy: paperboy,
      sommelier: sommelier
    ).run
  end

  table.raw.flatten.each do |expected|
    expected = expected.strip
    unless output.include?(expected)
      raise "Expected '#{expected}' in output:\n#{output}"
    end
  end
end

def capture_output
  out = $stdout = StringIO.new
  yield
  out.string
ensure
  $stdout = STDOUT
end
