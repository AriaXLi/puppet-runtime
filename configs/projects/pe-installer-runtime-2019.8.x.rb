project 'pe-installer-runtime-2019.8.x' do |proj|
  # Used in component configurations to conditionally include dependencies
  proj.setting(:runtime_project, 'pe-installer')
  proj.setting(:ruby_version, '2.5.9')
  proj.setting(:openssl_version, '1.1.1')
  proj.setting(:augeas_version, '1.11.0')
  platform = proj.get_platform

  proj.version_from_git
  proj.generate_archives true
  proj.generate_packages false

  proj.description "The PE Installer runtime contains third-party components needed for PE Installer standalone packaging"
  proj.license "See components"
  proj.vendor "Puppet, Inc.  <info@puppet.com>"
  proj.homepage "https://puppet.com"
  proj.identifier "com.puppetlabs"

  if platform.is_windows?
    proj.setting(:company_id, "PuppetLabs")
    proj.setting(:product_id, "PE Installer")
    if platform.architecture == "x64"
      proj.setting(:base_dir, "ProgramFiles64Folder")
    else
      proj.setting(:base_dir, "ProgramFilesFolder")
    end
    # We build for windows not in the final destination, but in the paths that correspond
    # to the directory ids expected by WIX. This will allow for a portable installation (ideally).
    proj.setting(:prefix, File.join("C:", proj.base_dir, proj.company_id, proj.product_id))
  else
    proj.setting(:prefix, "/opt/puppetlabs/installer")
  end

  proj.setting(:ruby_dir, proj.prefix)
  proj.setting(:bindir, File.join(proj.prefix, 'bin'))
  proj.setting(:ruby_bindir, proj.bindir)
  proj.setting(:libdir, File.join(proj.prefix, 'lib'))
  proj.setting(:includedir, File.join(proj.prefix, "include"))
  proj.setting(:datadir, File.join(proj.prefix, "share"))
  proj.setting(:mandir, File.join(proj.datadir, "man"))

  if platform.is_windows?
    proj.setting(:host_ruby, File.join(proj.ruby_bindir, "ruby.exe"))
    proj.setting(:host_gem, File.join(proj.ruby_bindir, "gem.bat"))

    # For windows, we need to ensure we are building for mingw not cygwin
    platform_triple = platform.platform_triple
    host = "--host #{platform_triple}"
  else
    proj.setting(:host_ruby, File.join(proj.ruby_bindir, "ruby"))
    proj.setting(:host_gem, File.join(proj.ruby_bindir, "gem"))
  end

  ruby_base_version = proj.ruby_version.gsub(/(\d+)\.(\d+)\.(\d+)/, '\1.\2.0')
  proj.setting(:gem_home, File.join(proj.libdir, 'ruby', 'gems', ruby_base_version))
  proj.setting(:gem_install, "#{proj.host_gem} install --no-rdoc --no-ri --local --bindir=#{proj.ruby_bindir}")

  proj.setting(:platform_triple, platform_triple)
  proj.setting(:host, host)

  proj.setting(:artifactory_url, "https://artifactory.delivery.puppetlabs.net/artifactory")
  proj.setting(:buildsources_url, "#{proj.artifactory_url}/generic/buildsources")

  # Define default CFLAGS and LDFLAGS for most platforms, and then
  # tweak or adjust them as needed.
  proj.setting(:cppflags, "-I#{proj.includedir} -I/opt/pl-build-tools/include")
  proj.setting(:cflags, "#{proj.cppflags}")
  proj.setting(:ldflags, "-L#{proj.libdir} -L/opt/pl-build-tools/lib -Wl,-rpath=#{proj.libdir}")

  # Platform specific overrides or settings, which may override the defaults
  if platform.is_windows?
    arch = platform.architecture == "x64" ? "64" : "32"
    proj.setting(:gcc_root, "C:/tools/mingw#{arch}")
    proj.setting(:gcc_bindir, "#{proj.gcc_root}/bin")
    proj.setting(:tools_root, "C:/tools/pl-build-tools")
    proj.setting(:cppflags, "-I#{proj.tools_root}/include -I#{proj.gcc_root}/include -I#{proj.includedir}")
    proj.setting(:cflags, "#{proj.cppflags}")
    proj.setting(:ldflags, "-L#{proj.tools_root}/lib -L#{proj.gcc_root}/lib -L#{proj.libdir} -Wl,--nxcompat -Wl,--dynamicbase")
    proj.setting(:cygwin, "nodosfilewarning winsymlinks:native")
  end

  if platform.is_macos?
    # For OS X, we should optimize for an older architecture than Apple
    # currently ships for; there's a lot of older xeon chips based on
    # that architecture still in use throughout the Mac ecosystem.
    # Additionally, OS X doesn't use RPATH for linking. We shouldn't
    # define it or try to force it in the linker, because this might
    # break gcc or clang if they try to use the RPATH values we forced.
    proj.setting(:cppflags, "-I#{proj.includedir}")
    proj.setting(:cflags, "-march=core2 -msse4 #{proj.cppflags}")
    proj.setting(:ldflags, "-L#{proj.libdir} ")
  end

  # These flags are applied in addition to the defaults in configs/component/openssl.rb.
  proj.setting(:openssl_extra_configure_flags, [
    'no-dtls',
    'no-dtls1',
    'no-idea',
    'no-seed',
    'no-weak-ssl-ciphers',
    '-DOPENSSL_NO_HEARTBEATS',
  ])

  # What to build?
  # --------------
  #
  if platform.name =~ /^redhatfips-.*/
    # Link against the system openssl instead of our vendored version.
    # This is also used by components within this vanagon project (i.e. curl, ruby, ca-bundle)
    proj.setting(:system_openssl, true)
  else
    proj.component "openssl-#{proj.openssl_version}"
  end

  # Ruby and deps
  proj.component "runtime-pe-installer"
  proj.component "puppet-ca-bundle"
  proj.component "ruby-#{proj.ruby_version}"

  # Puppet dependencies
  proj.component 'rubygem-deep_merge'
  proj.component 'rubygem-text'
  proj.component 'rubygem-locale'
  proj.component 'rubygem-gettext'
  proj.component 'rubygem-fast_gettext'
  proj.component 'rubygem-semantic_puppet'

  # R10k dependencies
  proj.component 'rubygem-gettext-setup'

  # Core dependencies
  proj.component 'rubygem-ffi'
  proj.component 'rubygem-minitar'
  proj.component 'rubygem-multi_json'

  proj.setting(:rubygem_net_ssh_version, '5.2.0')
  proj.component 'rubygem-net-ssh'

  # net-ssh dependencies for el8's OpenSSH default key format
  # since we do not need these for Windows (`puppet infra run` does not work for Windows platforms),
  #   and building these can finicky, don't install for Windows
  unless platform.is_windows?
    proj.component 'rubygem-bcrypt_pbkdf'
    proj.component 'rubygem-ed25519'
  end

  # Core Windows dependencies
  proj.component 'rubygem-win32-dir'
  proj.component 'rubygem-win32-process'
  proj.component 'rubygem-win32-security'
  proj.component 'rubygem-win32-service'

  # Components from puppet-runtime included to support apply on localhost
  # Only bundle SELinux gem for RHEL,Centos,Fedora
  if platform.is_el? || platform.is_fedora?
    proj.component 'ruby-selinux'
  end

  # Non-windows specific components
  unless platform.is_windows?
    # C Augeas + deps
    proj.component 'augeas'
    proj.component 'libxml2'
    proj.component 'libxslt'
    # Ruby Augeas and shadow
    proj.component 'ruby-augeas'
    proj.component 'ruby-shadow'
  end

  # What to include in package?
  proj.directory proj.prefix

  # Export the settings for the current project and platform as yaml during builds
  proj.publish_yaml_settings

  proj.timeout 7200 if platform.is_windows?
end
