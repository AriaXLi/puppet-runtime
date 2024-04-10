component "virt-what" do |pkg, settings, platform|
  pkg.version "1.22"
  pkg.md5sum "0e9923de6a6c6f07bc0ddc3ec8fc1018"

  pkg.url "https://people.redhat.com/~rjones/virt-what/files/virt-what-#{pkg.get_version}.tar.gz"
  pkg.mirror "#{settings[:buildsources_url]}/virt-what-#{pkg.get_version}.tar.gz"

  pkg.replaces 'pe-virt-what'

  # Run-time requirements
  unless platform.is_deb?
    requires "util-linux"
  end

  if platform.is_rpm?
    pkg.build_requires "util-linux"
  end

  if platform.is_linux?
    if platform.architecture =~ /ppc64le$/
      host_opt = '--host powerpc64le-unknown-linux-gnu'
    elsif platform.architecture =~ /ppc64$/
      host_opt = '--host powerpc64-unknown-linux-gnu'
    end
  end

  if platform.is_cross_compiled_linux?
    host_opt = "--host #{settings[:platform_triple]}"

    pkg.environment "PATH" => "/opt/pl-build-tools/bin:$$PATH:#{settings[:bindir]}"
    pkg.environment "CFLAGS" => settings[:cflags]
    pkg.environment "LDFLAGS" => settings[:ldflags]
  end

  pkg.configure do
    ["./configure --prefix=#{settings[:prefix]} --sbindir=#{settings[:prefix]}/bin --libexecdir=#{settings[:prefix]}/lib/virt-what #{host_opt}"]
  end

  pkg.build do
    ["#{platform[:make]} -j$(shell expr $(shell #{platform[:num_cores]}) + 1)"]
  end

  pkg.install do
    ["#{platform[:make]} -j$(shell expr $(shell #{platform[:num_cores]}) + 1) install"]
  end
end
