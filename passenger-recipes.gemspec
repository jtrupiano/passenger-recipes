Gem::Specification.new do |s|
  s.name = "passenger-recipes"
  s.version = PKG_VERSION
  s.platform = Gem::Platform::RUBY
  s.author = "John Trupiano"
  s.email = "jtrupiano@gmail.com"
  s.description = %q(A set of capistrano recipes tailored for Phusion Passenger)
  s.summary = s.description # More details later??
  s.has_rdoc = false
  s.require_paths = ["lib"]
  
  s.files = Dir.glob("{lib}/**/*") + %w(README)
  
  s.add_dependency(%q<capistrano-extensions>, ["= 0.1.2"])
end
