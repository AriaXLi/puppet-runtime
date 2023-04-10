component 'rubygem-nokogiri' do |pkg, _settings, _platform|
  pkg.version '1.14.2'
  pkg.sha256sum 'd3ee00f26c151763da1691c7fc6871ddd03e532f74f85101f5acedc2d099e958'
  instance_eval File.read('configs/components/_base-rubygem.rb')

  pkg.build_requires 'rubygem-mini_portile2'

  gem_home = settings[:gem_home]
  pkg.environment "GEM_HOME", gem_home

  # When cross compiling nokogiri native extensions on macOS 11/12 ARM, there is a 94M tmp
  # directory that's not needed
  if platform.is_macos? && platform.architecture == 'arm64'
    install do
      "rm -r #{gem_home}/gems/nokogiri-#{pkg.get_version}/ext/nokogiri/tmp"
    end
  end
end
