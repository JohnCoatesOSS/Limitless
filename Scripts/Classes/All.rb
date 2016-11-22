#!/usr/bin/ruby

require 'fileutils'
require 'open3'

$classesDirectory = File.expand_path(File.dirname(__FILE__))
$scriptsDirectory = File.expand_path($classesDirectory + "/../")
projectDirectory = File.expand_path($scriptsDirectory + "/../")

require "#{$classesDirectory}/Xcode"
require "#{$classesDirectory}/Packaging"
require "#{$classesDirectory}/Configuration"

def syscall(*cmd)
	begin
		# puts "Syscall: #{cmd}"
		stdout, stderr, status = Open3.capture3(*cmd)
		status.success? && stdout.slice!(0..-(1 + $/.size)) # strip trailing eol
	rescue
		puts "Error with command: #{cmd}"
	end
end

def signBinary(binaryPath, entitlementsPath = nil)
	puts "Signing binary @ #{binaryPath} with #{entitlementsPath}"

	system "codesign -s - --entitlements \"#{entitlementsPath}\" -f \"#{binaryPath}\""
	exitstatus = $?.exitstatus
	if exitstatus != 0
		puts "ERROR: Codesign failed! Stopping build";
		exit 1;
	end
	return true
end

class XcodePlist
	def initialize (plistPath)
		@plistPath = plistPath
	end

	def property(propertyName)
		command = "/usr/libexec/PlistBuddy -c \"Print #{propertyName}\" \"#{@plistPath}\""
		return syscall command
	end

	def setProperty(propertyName, propertyValue)
		command = "/usr/libexec/PlistBuddy -c \"Set :#{propertyName} #{propertyValue}\" \"#{@plistPath}\""
		return syscall command
	end

end

# check for dpkg-deb
# add path to homebrew directory
# in case our enviroment variables aren't set correctly
ENV['PATH'] = ENV['PATH'] ? ENV['PATH'] + ':/usr/local/bin/' : "/usr/local/bin/"

# taken from http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
def which(cmd)
	exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
	ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
		exts.each { |ext|
			exe = File.join(path, "#{cmd}#{ext}")
			return exe if File.executable?(exe) && !File.directory?(exe)
		}
	end
	return nil
end

# taken from http://stackoverflow.com/questions/1939333/how-to-make-a-ruby-string-safe-for-a-filesystem
def sanitizeFilename(filename)
	# Split the name when finding a period which is preceded by some
	# character, and is followed by some character other than a period,
	# if there is no following period that is followed by something
	# other than a period (yeah, confusing, I know)
	fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m

	# We now have one or two parts (depending on whether we could find
	# a suitable period). For each of these parts, replace any unwanted
	# sequence of characters with an underscore
	fn.map! { |s| s.gsub /[^a-z0-9\-]+/i, '_' }

	# Finally, join the parts with a period and return the result
	return fn.join '.'
end

def ensureDPKGInstalled()
	if which("dpkg-deb") == nil
		puts "dpkg not detected, install? y/n"

		# work-around fix for gets = nil error
		response = gets
		response ||= ''
		response.chomp!

		if response[0] == "y"
			if which("brew") == nil
				puts "installing prerequisite: homebrew package manager"
				system "ruby -e \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)\""
			end

			puts "installing dpkg with homebrew"
			system "brew install dpkg"

		elsif response[0] == "n"
			puts "install refused: cannot continue with build"
			exit;
		else
			puts "Expected y or n, received: "+response
			puts "cannot continue with build"
		end
	end
end

# open Xcode: macappstore://itunes.apple.com/app/id497799835
# https://itunes.apple.com/us/app/xcode/id497799835
# xcode-select --install
# https://developer.apple.com/services-account/download?path=/Developer_Tools/Xcode_7.2.1/Xcode_7.2.1.dmg
# https://developer.apple.com/devcenter/download.action?path=/Developer_Tools/Xcode_7.2.1/Xcode_7.2.1.dmg
