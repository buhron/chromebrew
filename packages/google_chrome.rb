require 'package'

class Google_chrome < Package
  @update_channel = 'stable'
  description 'Google Chrome is a fast, easy to use, and secure web browser.'
  homepage 'https://www.google.com/chrome/'
  version '127.0.6533.119-1'
  license 'google-chrome'
  compatibility 'x86_64'
  min_glibc '2.25'
  source_url "https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-#{@update_channel}/google-chrome-#{@update_channel}_#{@version}_amd64.deb"
  source_sha256 '93daec10b02d38574b4a2d5d3935782ebec4d94bb9b11d7f18e2fd0560ea665e'

  depends_on 'nss'
  depends_on 'cairo'
  depends_on 'gtk3'
  depends_on 'expat'
  depends_on 'cras'

  no_compile_needed
  no_shrink

  def self.install
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/bin"

    FileUtils.mv 'usr/share', CREW_DEST_PREFIX
    FileUtils.mv 'opt/google/chrome', "#{CREW_DEST_PREFIX}/share"

    FileUtils.ln_s "#{CREW_PREFIX}/share/chrome/google-chrome", "#{CREW_DEST_PREFIX}/bin/google-chrome"
  end

  def self.postinstall
    ExitMessage.add "\nType 'google-chrome' to get started.\n"
  end
end