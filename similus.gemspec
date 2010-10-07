# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{similus}
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Horaci Cuevas"]
  s.date = %q{2010-10-07}
  s.description = %q{A ruby library to find similar objects and make recommendations based on activity of objects}
  s.email = %q{horaci @@ gmail.com}
  s.extra_rdoc_files = ["LICENSES", "README.rdoc", "lib/similus.rb", "lib/similus/config.rb", "lib/similus/core.rb", "lib/similus/redis.rb"]
  s.files = ["LICENSES", "README.rdoc", "Rakefile", "benchmarks/benchmark1.rb", "benchmarks/benchmark2.rb", "benchmarks/custom_benchmark.rb", "benchmarks/redis.conf", "init.rb", "lib/similus.rb", "lib/similus/config.rb", "lib/similus/core.rb", "lib/similus/redis.rb", "test/add_activity_spec.rb", "test/recommended_spec.rb", "test/similar_spec.rb", "Manifest", "similus.gemspec"]
  s.homepage = %q{http://github.com/horaci/similus}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Similus", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{similus}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{A ruby library to find similar objects and make recommendations based on activity of objects.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<redis>, [">= 0"])
    else
      s.add_dependency(%q<redis>, [">= 0"])
    end
  else
    s.add_dependency(%q<redis>, [">= 0"])
  end
end
