Gem::Specification.new do |s|
  s.name        = 'dude'
  s.version     = '0.1.1'
  s.summary     = 'The Dude abides'
  s.authors     = ['maykel']
  s.files       = Dir['lib/**/*.rb', 'bin/*']
  s.executables = ['dude']
  s.bindir      = 'bin'
  s.required_ruby_version = '>= 3.0'
  s.add_dependency 'thor'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'cucumber'
  s.add_development_dependency 'rr'
end
