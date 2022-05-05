#!/usr/bin/env bundle exec ruby

require 'plist'
require 'fileutils'
require 'tmpdir'
require 'digest'
require 'nokogiri'

require 'pp'

# Monkey-patch the plist gem to never indent, since it screws up embedded
# strings.  We'll reformat it later, using nokogiri.  This is terrible,
# but the plist gem seems to be abandoned.
module Plist::Emit
  class IndentedString
    def initialize(str = "")
      @indent_string = str
      @contents = ''
      @indent_level = 0
    end
  end
end

FILES = [
  {
    filename: "HomeDirReaper.sh",
    destination: "/usr/local/bin",
    executable: true,
    mode: "750"
  },
  {
    filename: "LI10.UserHomeDirManagement",
    destination: "/private/etc/hooks",
    executable: true,
    mode: "750"
  },
  {
    filename: "LO90.UserHomeDirManagement",
    destination: "/private/etc/hooks",
    executable: true,
    mode: "750"
  },
  {
    filename: "edu.umich.lsa.iss.HomeDirReaper.plist",
    destination: "/Library/LaunchAgents",
    executable: false,
    mode: "644"
  },
  {
    filename: "homedir.defaults",
    destination: "/private/etc",
    executable: false,
    mode: "644"
  }

]

VERSION=`git describe --always`.chomp.gsub(/^v/, '')
DMGNAME="UserHomeDirManagement-#{VERSION}.dmg"

Dir.mktmpdir { |tempdir|
  buildpath = File.join(tempdir, "build")
  dmgpath = File.join(tempdir, DMGNAME)

  FileUtils.mkpath(buildpath)

  FILES.each do |file|
    destination_path = File.join(buildpath, file[:filename])
    FileUtils.copy file[:filename], destination_path

    # Compute the md5 of the file after copying it
    file[:md5] = Digest::MD5.hexdigest(File.open(destination_path).read)
  end

  `hdiutil create -srcfolder #{buildpath} #{dmgpath}`

  FileUtils.copy dmgpath, Dir.getwd
}

# Construct the plist, mapping over the installs and copies arrays
plist = {
"autoremove" => false,
  "catalogs" => [ "testing" ],
  "installer_item_hash" => Digest::SHA256.hexdigest(File.open(DMGNAME).read),
  "installer_item_location" => "testing/#{DMGNAME}",
  "installer_item_size" => File.size(DMGNAME),
  "installer_type" => "copy_from_dmg",
  "installs" => FILES.map do |file|
    {
      md5checksum: file[:md5],
      path: File.join(file[:destination], file[:filename]),
      type: "file"
    }
  end,
  "items_to_copy" => FILES.map do |file|
    {
      destination_path: file[:destination],
      source_item: file[:filename],
      group: "wheel",
      mode: file[:mode]
    }
  end,
  "minimum_os_version" => "10.7.0",
  "name" => "UserHomeDirManagement",
  "preinstall_script" => File.read("preinstall.sh"),
  "uninstall_method" => "remove_copied_items",
  "uninstallable" => false,
  "version" => VERSION
}

# Use nokogiri to format it nicely
doc = ''
doc = Nokogiri::XML(plist.to_plist) { |x| x.noblanks }
doc = doc.to_xml(:indent => 1, :indent_text => "\t")

File.open("UserHomeDirManagement-#{VERSION}.plist", "w") do |file|
  file.puts doc
end
