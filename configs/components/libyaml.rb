component 'libyaml' do |pkg, settings, platform|
  pkg.version '0.2.5'
  pkg.md5sum 'bb15429d8fb787e7d3f1c83ae129a999'
  pkg.url "https://github.com/yaml/libyaml/releases/download/#{pkg.get_name}/yaml-#{pkg.get_version}-0.2.5.tar.gz"
  pkg.mirror "#{settings[:buildsources_url]}/yaml-#{pkg.get_version}.tar.gz"

  if platform.is_aix?
    pkg.environment "PATH", "/opt/pl-build-tools/bin:$(PATH)"
  elsif platform.is_cross_compiled_linux?
    pkg.environment "PATH", "/opt/pl-build-tools/bin:$(PATH):#{settings[:bindir]}"
    pkg.environment "CFLAGS", settings[:cflags]
    pkg.environment "LDFLAGS", settings[:ldflags]
  elsif platform.is_solaris?
    pkg.environment "PATH", "/opt/pl-build-tools/bin:$(PATH):/usr/local/bin:/usr/ccs/bin:/usr/sfw/bin:#{settings[:bindir]}"
    pkg.environment "CFLAGS", "#{settings[:cflags]} -std=c99"
    pkg.environment "LDFLAGS", settings[:ldflags]
  elsif platform.is_macos?
    pkg.environment "LDFLAGS", settings[:ldflags]
    pkg.environment "CFLAGS", settings[:cflags]
    if platform.is_cross_compiled?
      pkg.environment 'CC', 'clang -target arm64-apple-macos11' if platform.name =~ /osx-11/
      pkg.environment 'CC', 'clang -target arm64-apple-macos12' if platform.name =~ /osx-12/
    end
  else
    pkg.environment "LDFLAGS", settings[:ldflags]
    pkg.environment "CFLAGS", settings[:cflags]
  end

  pkg.build_requires "runtime-#{settings[:runtime_project]}"

  if platform.is_windows?
     # In Windows, libyaml is unable to find the C programs (like mingw) to configure and build so the path must be set first
    c_tools_path = 'export PATH="/cygdrive/c/tools/mingw64/bin:$(PATH)"'
  else
    c_tools_path = ""
  end

  pkg.configure do
    [
      "#{c_tools_path}",
      "./configure --prefix=#{settings[:prefix]} --sbindir=#{settings[:prefix]}/bin --libexecdir=#{settings[:prefix]}/lib/libyaml #{settings[:host]}"
    ]
  end

  pkg.build do
    [
      "#{c_tools_path}",
      "#{platform[:make]} VERBOSE=1 -j$(shell expr $(shell #{platform[:num_cores]}) + 1)"
    ]
  end

  pkg.install do
    [
      "#{c_tools_path}",
      "#{platform[:make]} VERBOSE=1 -j$(shell expr $(shell #{platform[:num_cores]}) + 1) install",
      "rm -rf #{settings[:datadir]}/doc/#{pkg.get_name}*"
    ]
  end
end
