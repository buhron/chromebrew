require 'buildsystems/meson'

class Util_linux < Meson
  description 'essential linux tools'
  homepage 'https://www.kernel.org/pub/linux/utils/util-linux/'
  version "2.40.2-#{CREW_PY_VER}"
  license 'GPL-2, LGPL-2.1, BSD-4, MIT and public-domain'
  compatibility 'all'
  source_url 'https://github.com/util-linux/util-linux.git'
  git_hashtag "v#{version.split('-').first}"
  binary_compression 'tar.zst'

  binary_sha256({
    aarch64: '337f5ada3bdab988e8e1a495975e2da53ace10525de389972f38e349e571c641',
     armv7l: '337f5ada3bdab988e8e1a495975e2da53ace10525de389972f38e349e571c641',
       i686: 'b5afb757ef741feecd52fc8b21cf04f32915334da633e1b8b571be87ed8e0dea',
     x86_64: 'c9a7f6086218a9bc1ecd436c5615bc3ce5b6b7926b6cdf3d91ea41c369f9a698'
  })

  depends_on 'bash_completion' # R
  depends_on 'bzip2' # R
  depends_on 'eudev' if ARCH == 'x86_64' # (for libudev.h)
  depends_on 'filecmd' # R
  depends_on 'gcc_lib' # R
  depends_on 'glibc' # R
  depends_on 'libcap_ng' # R
  depends_on 'libeconf' # R
  depends_on 'linux_pam' # R
  depends_on 'lzlib' # R
  depends_on 'ncurses' # R
  depends_on 'pcre2' => :build
  depends_on 'readline' # R
  depends_on 'ruby_asciidoctor' => :build
  depends_on 'sqlite' # R
  depends_on 'xzutils' # R
  depends_on 'zlib' # R
  depends_on 'zstd' # R

  conflicts_ok

  year2038 = ARCH == 'x86_64' ? '' : '-Dallow-32bit-time=true'
  # Avoid incompatibilities and conflicts with coreutils.
  disabled_builds = ARCH == 'i686' ? '-Dbuild-kill=disabled -Dbuild-blkzone=disabled -Dbuild-lsfd=disabled -Dprogram-tests=false' : '-Dbuild-kill=disabled'
  meson_options "#{year2038} #{disabled_builds}"

  def self.patch
    # Fix undefined reference to `pthread_atfork' build error
    # introduced by https://github.com/util-linux/util-linux/pull/3017
    # and mentioned in https://github.com/util-linux/util-linux/issues/3131 .
    system "sed -i \"1i thread_dep = dependency('threads')\" libuuid/meson.build"
    system "sed -i \"s/dependencies : \\\[socket_libs,/dependencies : \\\[socket_libs, thread_dep,/\" libuuid/meson.build"
  end

  def self.install
    system "DESTDIR=#{CREW_DEST_DIR} #{CREW_NINJA} -C builddir install"
    return if ARCH == 'i686'

    # Imagemagick wants a libuuid libtool file.
    @libname = 'libuuid'
    @libnames = Dir["#{CREW_DEST_LIB_PREFIX}/#{@libname}.so*"]
    @libnames = Dir["#{CREW_DEST_LIB_PREFIX}/#{@libname}-*.so*"] if @libnames.empty?
    @libnames.each do |s|
      s.gsub!("#{CREW_DEST_LIB_PREFIX}/", '')
    end
    @dlname = @libnames.grep(/.so./).first
    @dlname = @libnames.grep(/.so/).first if @dlname.nil?
    @libname = @dlname.gsub(/.so.\d+/, '')
    @longest_libname = @libnames.max_by(&:length)
    @libvars = @longest_libname.rpartition('.so.')[2].split('.')
    @libtool_file = <<~LIBTOOLEOF
      # #{@libname}.la - a libtool library file
      # Generated by libtool (GNU libtool) (Created by Chromebrew)
      #
      # Please DO NOT delete this file!
      # It is necessary for linking the library.

      # The name that we can dlopen(3).
      dlname='#{@dlname}'

      # Names of this library.
      library_names='#{@libnames.reverse.join(' ')}'

      # The name of the static archive.
      old_library='#{@libname}.a'

      # Linker flags that cannot go in dependency_libs.
      inherited_linker_flags=''

      # Libraries that this one depends upon.
      dependency_libs=''

      # Names of additional weak libraries provided by this library
      weak_library_names=''

      # Version information for #{name}.
      current=#{@libvars[1]}
      age=#{@libvars[1]}
      revision=#{@libvars[2]}

      # Is this an already installed library?
      installed=yes

      # Should we warn about portability when linking against -modules?
      shouldnotlink=no

      # Files to dlopen/dlpreopen
      dlopen=''
      dlpreopen=''

      # Directory that this library needs to be installed in:
      libdir='#{CREW_LIB_PREFIX}'
    LIBTOOLEOF
    File.write("#{CREW_DEST_LIB_PREFIX}/#{@libname}.la", @libtool_file)
  end
end
