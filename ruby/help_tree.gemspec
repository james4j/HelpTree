Gem::Specification.new do |spec|
  spec.name          = 'help_tree'
  spec.version       = '0.1.0'
  spec.summary       = 'Introspective --help-tree for Thor-based CLIs'
  spec.description   = 'Adds --help-tree to Thor command-line interfaces with ANSI themes and JSON output'
  spec.authors       = ['HelpTree Contributors']
  spec.license       = 'MIT'
  spec.files         = Dir['lib/**/*.rb']
  spec.require_paths = ['lib']
end
