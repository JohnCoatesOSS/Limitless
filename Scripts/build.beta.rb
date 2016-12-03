#!/usr/bin/ruby

## project settings

releaseConfiguration = FALSE

# in case we want to turn off .deb building quickly
shouldBuildPackage = TRUE
shouldInstallOnDevice = TRUE
showDebPackageInFinder = FALSE
terminateProcess = "Limitless"
waitForDebugger = FALSE
launchApp = FALSE
attachXcode = FALSE
clean = TRUE

# replace this with your device
device = {name: '📱 iPhone 5s', ip:'192.168.254.4'}

# show output ASAP
STDOUT.sync = true

require 'fileutils'
require 'pp'
# require build tools
scriptsDirectory = __dir__
projectDirectory = File.expand_path(File.join(scriptsDirectory, ".."))
buildToolsPath = File.join(scriptsDirectory, "Classes/All")
require buildToolsPath

bundleIdentifier = "com.shade.Limitless.release"
appToLaunch = nil
if launchApp
  terminateProcess = "Limitless"
  appToLaunch = "com.shade.Limitless.release"

  if waitForDebugger
    attachXcode = TRUE
  end
end
buildConfiguration = "Release"

if !releaseConfiguration
  # Debug mode so variables are readable
  buildConfiguration = "Debug"
end

configuration = Configuration.new(
                defaultDevice: device,
                defaultBuildFolder: File.join(projectDirectory, "Release"),
                defaultBuildConfiguration: buildConfiguration,
                defaultTarget: "Limitless",
                defaultProjectDirectory: projectDirectory,
                defaultShouldInstallOnDevice: shouldInstallOnDevice,
                defaultShouldBuildPackage: shouldBuildPackage,
                defaultAppToTerminate: terminateProcess,
                defaultAppToLaunch: appToLaunch
                )

preprocessorDefinitions = "RELEASE_BUILD=1 "
if waitForDebugger
  preprocessorDefinitions += " WAIT_FOR_DEBUGGER=1"
end
appBuild = XcodeBuild.new(
           projectDirectory: configuration.projectDirectory,
           target: configuration.target,
           configuration: configuration.buildConfiguration,
           sdk: "iphoneos",
           buildFolder: File.join(configuration.buildFolder, "Device"),
           workspace: nil,
           bundleIdentifier: bundleIdentifier,
           preprocessorDefinitions: preprocessorDefinitions,
           clean: clean
           )
if appBuild.build == false
  exit 1
end

runAsSuperuserBuild = XcodeBuild.new(
           projectDirectory: configuration.projectDirectory,
           target: "runAsSuperuser",
           configuration: configuration.buildConfiguration,
           sdk: "iphoneos",
           buildFolder: File.join(configuration.buildFolder, "Device"),
           clean: clean
           )
if runAsSuperuserBuild.build == false
  exit 1
end

plistFilePath = appBuild.buildSetting 'INFOPLIST_FILE'
plistFilePath = projectDirectory + "/#{plistFilePath}"

plist = XcodePlist.new plistFilePath
shortVersion = plist.property "CFBundleShortVersionString"
betaBuild = plist.property "CFBundleVersion"
version = "#{shortVersion}~Beta#{betaBuild}"

appExecutableFolderPath = appBuild.buildSetting 'EXECUTABLE_FOLDER_PATH'

if launchApp && attachXcode
  attachScript = File.join(scriptsDirectory, "attach")
  system("nohup \"#{attachScript}\" &")
end

Dir.chdir(configuration.buildFolder) do
  stagingDirectory = File.expand_path("#{configuration.buildFolder}/_")
  packaging = Packaging.new(stagingDirectory:stagingDirectory, installationDevice:configuration.device)

  # clear staging folder
  packaging.clearStaging

  # add entilements
  entilementsPath = File.join(projectDirectory, "Resources/Legacy/entitlements.xml")
  appBuild.signExecutableOutput(entilementsPath)

  # copy app to staging
  appInstallationPath = "/Applications"
	packaging.createStagingDirectoryIfDoesntExist appInstallationPath
  deviceAppDirectory = File.join(appBuild.buildFolder, appExecutableFolderPath)
  appStagingDirectory = File.join(stagingDirectory, appInstallationPath)

  puts "Copying app to staging: #{deviceAppDirectory} -> #{appStagingDirectory}"

  FileUtils.cp_r(deviceAppDirectory, appStagingDirectory)

  # copy runAsSuperuser to staging
  runAsSuperuserDestination = "/Applications/Limitless.app/runAsSuperuser"
  runAsSuperuserStagingDestination = File.join(stagingDirectory, runAsSuperuserDestination)
  runAsSuperuserExecutable = runAsSuperuserBuild.executableOutputPath()

  puts "Copying runAsSuperuser to staging: #{runAsSuperuserExecutable} -> #{runAsSuperuserStagingDestination}"
  FileUtils.copy(runAsSuperuserExecutable, runAsSuperuserStagingDestination)

  # copy over layout contents
  packaging.copyLayoutFolderContents File.join(projectDirectory, "layout")

  # update control file
  packaging.setControlVersion(version)
  packaging.setControlPackage("limitless.beta")
  packaging.setControlReplaces("limitless")

  if configuration.shouldBuildPackage
    filename = "Limitless_#{version}.deb"

    packaging.buildPackage filename
    packagePath = File.expand_path(filename)
    if showDebPackageInFinder
      system "open -R \"#{packagePath}\""
    end

    if configuration.shouldInstallOnDevice

			packaging.installOnDevice

			if configuration.appToTerminate
				packaging.terminateApp configuration.appToTerminate
			end # app to terminate

			if configuration.appToLaunch
				packaging.launchApp configuration.appToLaunch
			end # app to launch

    end # device install
  end # build package
end # build folder

puts "Finished building at: " + Time.now.inspect
