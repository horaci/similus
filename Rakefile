require 'rubygems'
require 'rake'
require 'echoe'
require 'spec/rake/spectask'

desc 'Default: run all similus tests'
task :default => :test

desc "Run all tests"
Spec::Rake::SpecTask.new('test') do |t|
  t.spec_files = FileList['test/**/*.rb']
  t.spec_opts = ["--color"]
end

Echoe.new('similus', '0.1.2') do |p|
  p.description    = "A ruby library to find similar objects and make recommendations based on activity of objects"
  p.summary        = "A ruby library to find similar objects and make recommendations based on activity of objects."
  p.url            = "http://github.com/horaci/similus"
  p.author         = "Horaci Cuevas"
  p.email          = "horaci @@ gmail.com"
  p.ignore_pattern = ["tmp/*", "script/*"]
  p.runtime_dependencies = ["redis"]
  p.retain_gemspec = true
end
