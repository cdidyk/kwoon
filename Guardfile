guard 'rails' do
  watch('Gemfile.lock')
  watch(%r{^(config|lib)/.*})
end

guard :rspec, cmd: "bin/rspec" do
  # Feel free to open issues for suggestions and improvements
  require "guard/rspec/dsl"
  dsl = Guard::RSpec::Dsl.new(self)

  # RSpec files
  rspec = dsl.rspec
  watch(rspec.spec_helper) { rspec.spec_dir }
  watch(rspec.spec_support) { rspec.spec_dir }
  watch(rspec.spec_files)

  # Ruby files
  ruby = dsl.ruby
  dsl.watch_spec_files_for(ruby.lib_files)

  # Rails files
  rails = dsl.rails(view_extensions: %w(erb haml slim))
  dsl.watch_spec_files_for(rails.app_files)

  # watch(rails.controllers) do |m|
  #   rspec.spec.call("controllers/#{m[1]}_controller")
  # end

  # Rails config changes
  watch(rails.spec_helper)     { rspec.spec_dir }
  watch(rails.app_controller)  { "#{rspec.spec_dir}/controllers" }
end
