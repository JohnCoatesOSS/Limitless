#!/usr/bin/env ruby
STDOUT.sync = true
require 'pp'
require 'fileutils'

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
  puts "macOS SDK Path: #{sdkPath}"
  return sdkPath
end

def getSimulatorSDKPath()
    sdkPath = `xcodebuild -sdk iphonesimulator -version Path`.strip
  # make sure path exists
  if File.exist?(sdkPath) == false
    raise "SDK path does not exist: #{sdkPath}"
  end
  # check and see if a non specific path exists
  sdkGenericPath = File.expand_path(File.join(sdkPath, "../MacOSX.sdk"))
  if File.exist?(sdkGenericPath)
    sdkPath = sdkGenericPath
  end
  puts "iOS Simulator SDK Path: #{sdkPath}"
  return sdkPath
end

def createFrameworkLinks(headersDirectory: nil, sdkFrameworksDirectory: nil)
  frameworkDirectories = {
    AE: "CoreServices.framework/Frameworks/AE.framework/Headers",
    ApplicationServices: "ApplicationServices.framework/Headers",
    CarbonCore: "CoreServices.framework/Frameworks/CarbonCore.framework/Headers",
    CoreServices: "CoreServices.framework/Headers",
    DictionaryServices: "CoreServices.framework/Frameworks/DictionaryServices.framework/Headers",
    FSEvents: "CoreServices.framework/Frameworks/FSEvents.framework/Headers",
    IOKit: "IOKit.framework/Headers",
    IOSurface: "IOSurface.framework/Headers",
    JavaScriptCore: "JavaScriptCore.framework/Headers",
    LaunchServices: "CoreServices.framework/Frameworks/LaunchServices.framework/Headers",
    Metadata: "CoreServices.framework/Frameworks/Metadata.framework/Headers",
    OSServices: "CoreServices.framework/Frameworks/OSServices.framework/Headers",
    SearchKit: "CoreServices.framework/Frameworks/SearchKit.framework/Headers",
    SharedFileList: "CoreServices.framework/Frameworks/SharedFileList.framework/Headers",
    WebKit: "WebKit.framework/Headers"
  }

  frameworkDirectories.each_pair do |directoryName, target|
    directory = File.join(headersDirectory, directoryName.to_s)
    directory = File.expand_path(directory)
    targetPath = File.join(sdkFrameworksDirectory, target)
    targetPath = File.expand_path(targetPath)

    ensureSymlink(atPath: directory, targetPath: targetPath, targetIsADirectory: true)
  end
end

def createSingleHeaderLinks(singleHeadersDirectory: nil, sdkFrameworksDirectory: nil)
  if !File.exist?(singleHeadersDirectory)
    puts "Creating singleHeadersDirectory: #{singleHeadersDirectory}"
    FileUtils.mkdir_p(singleHeadersDirectory)
  end

  headers = {
    NSTask: "Foundation.framework/Headers/NSTask.h"
  }

  headers.each_pair do |headerName, target|
    atPath = File.join(singleHeadersDirectory, headerName.to_s + ".h")
    atPath = File.expand_path(atPath)
    targetPath = File.join(sdkFrameworksDirectory, target)
    ensureSymlink(atPath: atPath, targetPath: targetPath, targetIsADirectory: false)
  end
end

def createLinksToSimulatorDirectories(headersDirectory: nil, simulatorSDKRoot: nil)
  directories = {
    libkern: "usr/include/libkern",
    "sys/reboot.h" => "usr/include/sys/reboot.h"
  }

  directories.each_pair do |directoryName, target|
    directory = File.join(headersDirectory, directoryName.to_s)
    directory = File.expand_path(directory)
    targetPath = File.join(simulatorSDKRoot, target)
    targetPath = File.expand_path(targetPath)

    extension = File.extname(directory)
    
    isDirectory = true
    if !extension.empty?
      containingDirectory = File.dirname(directory)
       if !File.exist?(containingDirectory)
        puts "Creating directory: #{containingDirectory}"
        FileUtils.mkdir_p(containingDirectory)
      end
    end
    
    ensureSymlink(atPath: directory, targetPath: targetPath, targetIsADirectory: isDirectory)
  end

end

def ensureSymlink(atPath: nil, targetPath: nil, targetIsADirectory: false)
  if !File.exists?(targetPath)
    raise "error: Error, couldn't find symlink destination: #{targetPath}"
  end

  if File.symlink?(atPath)
    currentTarget = File.readlink(atPath)
    if currentTarget == targetPath
      return
    end
    puts "Header symlink points to #{currentTarget}, but should point to #{targetPath}. Updating."
    File.unlink(atPath)
  elsif File.exist?(atPath)
    if targetIsADirectory
      puts "Expected #{directory} to be a symlink, but it's not. This might cause issues."

      if !File.directory?(directory)
        puts "Expected #{directory} to be a directory, deleting."
        File.unlink(directory)
      elsif targetIsADirectory # supposed to be a directory and is
        return
      end
    end # targetIsADirectory

    if !targetIsADirectory
      if File.directory?(directory)
        puts "error: Expected #{atPath} to be a symlink, but found a directory."
        exit 1
      else
        puts "Expected #{atPath} to be a symlink, but found a file. Deleting."
        File.unlink(atPath)
      end
    end # !targetIsADirectory

  end # File.exist?(atPath)

  puts "Creating symlink to #{targetPath} at #{atPath}"
  File.symlink(targetPath, atPath)
end

sdkPath = macOSSDKPath()
sdkFrameworksDirectory = File.join(sdkPath, "System/Library/Frameworks")
simulatorSDKRoot = getSimulatorSDKPath()
scriptsDirectory = __dir__
projectDirectory = File.expand_path(File.join(scriptsDirectory, ".."))
headersDirectory = File.join(projectDirectory, "External/Headers/Linked")

createFrameworkLinks(headersDirectory: headersDirectory, sdkFrameworksDirectory: sdkFrameworksDirectory)
createLinksToSimulatorDirectories(headersDirectory: headersDirectory, simulatorSDKRoot: simulatorSDKRoot)

singleHeadersDirectory = File.join(headersDirectory, "SingleHeaders")
createSingleHeaderLinks(singleHeadersDirectory: singleHeadersDirectory, sdkFrameworksDirectory: sdkFrameworksDirectory)
