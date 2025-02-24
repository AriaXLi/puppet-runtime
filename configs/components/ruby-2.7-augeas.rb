component 'ruby-2.7-augeas' do |pkg, settings, platform|
  expected_ruby_version = '2.7.5'

  unless settings[:ruby_version] == expected_ruby_version
    unless settings.key?(:additional_rubies) && settings[:additional_rubies].key?(expected_ruby_version)
      raise "No config found for Ruby #{expected_ruby_version} in settings[:additional_rubies]"
    end

    ruby_settings = settings[:additional_rubies][expected_ruby_version]

    ruby_version = ruby_settings[:ruby_version]
    host_ruby = ruby_settings[:host_ruby]
    ruby_dir = ruby_settings[:ruby_dir]
    ruby_bindir = ruby_settings[:ruby_bindir]
  end

  instance_eval File.read('configs/components/_base-ruby-augeas.rb')
end
