Gem::Specification.new do |s|
  s.name = %q{passenger-recipes}
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Trupiano"]
  s.date = %q{2008-09-12}
  s.description = %q{An opinionated set of capistrano recipes built on top of capistrano-extensions tailored for Phusion Passenger}
  s.email = %q{jtrupiano@gmail.com}
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "passenger-recipes.gemspec", "lib/passenger-recipes.rb", "lib/passenger-recipes/passenger.rb", "lib/passenger-recipes/version.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/jtrupiano/passenger-recipes/tree/master}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{johntrupiano}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{An opinionated set of capistrano recipes built on top of capistrano-extensions tailored for Phusion Passenger}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<capistrano-extensions>, [">= 0.1.4"])
      s.add_development_dependency(%q<hoe>, [">= 1.7.0"])
    else
      s.add_dependency(%q<capistrano-extensions>, [">= 0.1.4"])
      s.add_dependency(%q<hoe>, [">= 1.7.0"])
    end
  else
    s.add_dependency(%q<capistrano-extensions>, [">= 0.1.4"])
    s.add_dependency(%q<hoe>, [">= 1.7.0"])
  end
end
