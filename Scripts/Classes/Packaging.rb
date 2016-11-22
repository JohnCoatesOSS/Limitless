class Packaging
  def initialize(stagingDirectory:nil, installationDevice:nil)
      if stagingDirectory == nil
        puts "Error: stagingDirectory not passed to Packaging"
        exit 1
      end

      @stagingDirectory = stagingDirectory

      if File.basename(@stagingDirectory) != "_"
        puts "Error: Staging directory named: #{@stagingDirectory}, must be named _"
        exit 1
      end

      createDirectoryIfDoesntExist @stagingDirectory

      @device = installationDevice
  end

  # clears out everything from the staging directory
  def clearStaging()
    FileUtils.rm_r @stagingDirectory
  end

  def createStagingDirectoryIfDoesntExist(directory)
    directory = File.expand_path("#{@stagingDirectory}/#{directory}")
    createDirectoryIfDoesntExist directory
  end

  def createDirectoryIfDoesntExist(directory)
    if File.exists?(directory) == false
      puts "Creating staging directory #{directory}"
      FileUtils.mkdir_p(directory)
    end

    if File.exists?(directory) == false
      puts "Error: Staging directory couldn't be created at #{directory}"
      exit 1
    end
  end

  # copies file to installation path within staging directory
  # returns path of staged file
  def copyFileToInstallationDirectory(filePath:nil, installationPath:nil)
    if filePath == nil || installationPath == nil
      puts "Error: copyFileToInstallationDirectory passed filePath: #{filePath}, installationPath: #{installationPath}"
      exit 1
    end

    if File.exists?(filePath) == false
      puts "Can't copy file to intallation directory, file is missing: #{filePath}"
      exit 1
    end

    stagingPath = File.expand_path("#{@stagingDirectory}/#{installationPath}")
    installationDirectory = File.dirname(stagingPath)

    createDirectoryIfDoesntExist installationDirectory
    if FileUtils.cp(source=filePath, destination=stagingPath) == false
      puts "Error: Copy from #{filePath} to #{stagingPath} failed!"
      exit 1
    end

    return stagingPath
  end # copyFileToInstallationDirectory

  def stagingPathForInstallationPath(installationPath)
    if !installationPath
      puts "Missing installationPath in call to stagingPathForInstallationPath"
      exit 1
    end

    stagingPath = File.expand_path("#{@stagingDirectory}/#{installationPath}")
    installationDirectory = File.dirname(stagingPath)
    createDirectoryIfDoesntExist installationDirectory

    return stagingPath
  end

  def lipo(inputFiles:nil, installationPath:nil)
    if !inputFiles
      puts "Lipo missing input files"
      exit 1
    end

    if !installationPath
      put "Lipo missing installation path"
      exit 1
    end

    command = "lipo"
    inputFiles.each { |inputFile|
      if File.exists?(inputFile) == false
        puts "Lipo input file doesn't exist: #{inputFile}"
        exit 1
      end

      command += " \"#{inputFile}\""
    }
    stagingPath = stagingPathForInstallationPath installationPath
    command += " -create -output \"#{stagingPath}\""

    puts "Running lipo with output #{stagingPath}"

    system command
    exitstatus = $?.exitstatus

    if exitstatus != 0
      puts "Error: Lipo command failed: #{command}"
      exit exitstatus
    end
  end

  def copyLayoutFolderContents(layoutFolder)
    if File.exists?(layoutFolder) == false
      puts "Layout folder missing from #{layoutFolder}"
      exit 1
    end
    puts "Copying layout folder #{layoutFolder}/ to staging directory #{@stagingDirectory}/"
    if FileUtils.cp_r(source="#{layoutFolder}/.", destination="#{@stagingDirectory}/", :preserve => true) == false
      puts "Failed to copy contents of layout folder"
      exit 1
    end

  end # copyLayoutFolderContents

  # Package Building & install

  def buildPackage(filename)
    if !filename
      puts "Error: buildPackage passed invalid filename"
      exit 1
    end

    puts "Building package #{filename}"
    if File.exists?(filename) == true
      puts "Removing existing package"
      FileUtils.rm(filename)
    end

    @packageFilename = filename

    # remove .DS_Store files
    puts "Removing .DS_Store files"
    system "find \"#{@stagingDirectory}/\" -name '*.DS_Store' -type f -delete"
    exitstatus = $?.exitstatus

    if exitstatus != 0
      puts "error: Failed to remove DS_Store files"
      exit exitstatus
    end

    # build package
    system "dpkg-deb", "-b", "-Zgzip", "_", filename

    if File.exists?(filename) == false
      puts "Error: Couldn't build package #{filename}"
      exit 1
    end

  end # buildPackage

  def installOnDevice()
    if !@device
      puts "Can't install package, missing @device"
      exit 1
    end

    if !@packageFilename
      puts "Can't install package, missing @packageFilename"
      exit 1
    end

    filename = @packageFilename
    device = @device

    # transfer deb
    puts "Transferring #{filename} to #{device[:name]} @ #{device[:ip]}"
    system "scp -P 22 #{filename} root@#{device[:ip]}:#{filename}"

    # install deb
    puts "Installing #{filename} on #{device[:name]} @ #{device[:ip]}"
    system "ssh -p 22 root@#{device[:ip]} \"dpkg -i #{filename}\""
  end

  def terminateApp(appToTerminate)
    if !@device
      puts "Can't terminate app, missing @device"
      exit 1
    end
    device = @device
    puts "Killing app #{appToTerminate} on #{device[:name]} @ #{device[:ip]}"
    system "ssh -p 22 root@#{device[:ip]} \"killall #{appToTerminate}\""
  end

  def launchApp(appToLaunch)
    if !@device
      puts "Can't launch app, missing @device"
      exit 1
    end
    device = @device
    puts "Launching app with bundle identifier #{appToLaunch} on #{device[:name]} @ #{device[:ip]}"
    system "ssh -p 22 root@#{device[:ip]} \"area #{appToLaunch}\""
  end

  def rebootDevice()
    if !@device
      puts "Can't reboot device, missing @device"
      exit 1
    end
    device = @device

    puts "Rebooting #{device[:name]} @ #{device[:ip]}"
    system "ssh -p 22 root@#{device[:ip]} \"reboot\""
  end

end # Packaging
