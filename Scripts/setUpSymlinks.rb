#!/usr/bin/env ruby
STDOUT.sync = true
require 'pp'

def macOSSDKPath()
  sdkPath = `xcodebuild -sdk macosx -version Path`.strip
  # make sure path exists
  if File.exist?(sdkPath) == false
    raise "SDK path does not exist: #{sdkPath}"
  end
  # check and see if a non specific path exists
  sdkGenericPath = File.expand_path(File.join(sdkPath, "../MacOSX.sdk"))
  if File.exist?(sdkGenericPath)
    sdkPath = sdkGenericPath
  end
  puts "SDK Path: #{sdkPath}"
  return sdkPath
end


sdkPath = macOSSDKPath()
sdkFrameworksDirectory = File.join(sdkPath, "System/Library/Frameworks")
scriptsDirectory = __dir__
projectDirectory = File.expand_path(File.join(scriptsDirectory, ".."))
headersDirectory = File.join(projectDirectory, "External/Headers")

frameworkDirectories = {
  AE: "CoreServices.framework/Frameworks/AE.framework/Headers",
  ApplicationServices: "ApplicationServices.framework/Headers",
  CarbonCore: "CoreServices.framework/Frameworks/CarbonCore.framework/Headers",
  CoreServices: "CoreServices.framework/Headers",
  DictionaryServices: "CoreServices.framework/Frameworks/DictionaryServices.framework/Headers",
  FSEvents: "CoreServices.framework/Frameworks/FSEvents.framework/Headers",
  IOKit: "IOKit.framework/Headers",
  IOSurface: "IOSurface.framework/Headers",
  LaunchServices: "CoreServices.framework/Frameworks/LaunchServices.framework/Headers",
  Metadata: "CoreServices.framework/Frameworks/Metadata.framework/Headers",
  OSServices: "CoreServices.framework/Frameworks/OSServices.framework/Headers",
  SearchKit: "CoreServices.framework/Frameworks/SearchKit.framework/Headers",
  SharedFileList: "CoreServices.framework/Frameworks/SharedFileList.framework/Headers"
}

frameworkDirectories.each_pair do |directoryName, targetPath|
  directory = File.join(headersDirectory, directoryName.to_s)
  directory = File.expand_path(directory)
  target = File.join(sdkFrameworksDirectory, targetPath)

  if !File.exists?(target)
    raise "error: Error, couldn't find symlink destination: #{target}"
  end

  if File.symlink?(directory)
    currentTarget = File.readlink(directory)
    if currentTarget == target
      next
    end
    puts "Header symlink points to #{currentTarget}, but should point to #{target}. Updating."
    File.unlink(directory)
  elsif File.exist?(directory)
    puts "Expected #{directory} to be a symlink, but it's not. This might cause issues."
    next
  end # File.symlink?(directory)
  puts "Creating symlink to #{target} at #{directory}"
  File.symlink(target, directory)
end
