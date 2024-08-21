require 'package'

class Openssl < Package
  description 'The Open Source toolkit for Secure Sockets Layer and Transport Layer Security'
  homepage 'https://www.openssl.org'
  version '3.3.2-ed16083' # Do not use @_ver here, it will break the installer.
  license 'Apache-2.0'
  compatibility 'all'
  source_url 'https://github.com/openssl/openssl.git'
  git_hashtag 'ed16083728a0ab73b87cef58e23ea5490e6e73cc'
  binary_compression 'tar.zst'

  binary_sha256({
    aarch64: '2ccf77f60e73fd60a93838395ae9bc239448a8f155c3f7e2d79928663041db9c',
     armv7l: '2ccf77f60e73fd60a93838395ae9bc239448a8f155c3f7e2d79928663041db9c',
       i686: '111b9f963d8b23c27f1c1f5be123637f9fbfbe1b7652fdcacf835e532b32efbf',
     x86_64: 'b1d2926444a1091e9b41f119f1bfe189b91140743cf9db1c8539450d864978f0'
  })

  depends_on 'ccache' => :build
  depends_on 'glibc' # R

  case ARCH
  when 'aarch64', 'armv7l'
    @arch_c_flags = '-fPIC -march=armv7-a -mfloat-abi=hard -fuse-ld=mold'
    @arch_cxx_flags = '-fPIC -march=armv7-a -mfloat-abi=hard -fuse-ld=mold'
    @openssl_configure_target = 'linux-generic32'
  when 'i686'
    @arch_c_flags = '-fPIC -fuse-ld=mold'
    @arch_cxx_flags = '-fPIC -fuse-ld=mold'
    @openssl_configure_target = 'linux-x86'
  when 'x86_64'
    @arch_c_flags = '-fPIC -fuse-ld=mold'
    @arch_cxx_flags = '-fPIC -fuse-ld=mold'
    @openssl_configure_target = 'linux-x86_64'
  end
  @ARCH_LDFLAGS = '-flto'
  @ARCH_C_LTO_FLAGS = "#{@arch_c_flags} -flto=auto"
  @ARCH_CXX_LTO_FLAGS = "#{@arch_cxx_flags} -flto=auto"

  def self.build
    @no_tests_target = `openssl version | awk '{print $2}'`.chomp == version.to_s ? 'no-tests' : ''

    # This gives you the list of OpenSSL configure targets
    system './Configure LIST'
    system "PATH=#{CREW_LIB_PREFIX}/ccache/bin:#{CREW_PREFIX}/bin:/usr/bin:/bin \
      CFLAGS=\"#{@ARCH_C_LTO_FLAGS}\" CXXFLAGS=\"#{@ARCH_CXX_LTO_FLAGS}\" \
      LDFLAGS=\"#{@ARCH_LDFLAGS}\" \
      mold -run ./Configure --prefix=#{CREW_PREFIX} \
      --libdir=#{ARCH_LIB} \
      --openssldir=#{CREW_PREFIX}/etc/ssl \
      #{@openssl_configure_target} #{@no_tests_target}"
    system 'make'
  end

  def self.check
    # ecdsatest fails on i686
    # collect2: fatal error: ld terminated with signal 11 [Segmentation fault], core dumped
    # http_test fails on x86_64
    # collect2: error: ld returned 127 exit status
    return if ARCH == 'i686' || ARCH == 'x86_64'

    # Don't run tests if we are just rebuilding the same version of openssl.
    system 'make test' unless `openssl version | awk '{print $2}'`.chomp == version.to_s
  end

  def self.install
    system "make DESTDIR=#{CREW_DEST_DIR} install_sw install_ssldirs"
    # Extract OpenSSL 1.1.1 libraries for backwards compatibility purposes
    # from the openssl111 package.
    # Builds and rebuilds of packages against OpenSSL should automatically
    # build against OpenSSL 3.x and not against OpenSSL 1.1.1x.
    File.write 'openssl111_files', <<~EOF
      #{CREW_LIB_PREFIX[1..]}/libcrypto.so.1.1
      #{CREW_LIB_PREFIX[1..]}/libssl.so.1.1
    EOF
    @cur_dir = Dir.pwd
    @legacy_version = '1.1.1w'
    case ARCH
    when 'aarch64', 'armv7l'
      downloader "https://gitlab.com/api/v4/projects/26210301/packages/generic/openssl111/#{@legacy_version}_armv7l/openssl111-#{@legacy_version}-chromeos-armv7l.tar.zst",
                 '650209f527994f5c8bd57d1f2b5c42174d66472ca2a40116f66a043bd6e4c046', "openssl111-#{@legacy_version}-chromeos.tar.zst"
    when 'i686'
      downloader "https://gitlab.com/api/v4/projects/26210301/packages/generic/openssl111/#{@legacy_version}_i686/openssl111-#{@legacy_version}-chromeos-i686.tar.zst",
                 'a409ebebe5b5789e3ed739bc540d150faa66d9e33e6f19000b1b4e110a86d618', "openssl111-#{@legacy_version}-chromeos.tar.zst"
    when 'x86_64'
      downloader "https://gitlab.com/api/v4/projects/26210301/packages/generic/openssl111/#{@legacy_version}_x86_64/openssl111-#{@legacy_version}-chromeos-x86_64.tar.zst",
                 'e95e8cf456fc9168de148946c38cdda6a1e7482bdcbb4121766a178a32421917', "openssl111-#{@legacy_version}-chromeos.tar.zst"
    end
    Dir.chdir(CREW_DEST_DIR) do
      system "tar -Izstd -xv --files-from #{@cur_dir}/openssl111_files -f #{@cur_dir}/openssl111-#{@legacy_version}-chromeos.tar.zst"
    end
  end
end
