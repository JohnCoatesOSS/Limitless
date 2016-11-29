class Configuration

  # precedence: $device > @defaultDevice > @configurationDevice
  def initialize(
    defaultDevice:nil,
    defaultAppToTerminate:nil,
    defaultAppToLaunch: nil,
    defaultShouldInstallOnDevice:false,
    defaultShouldBuildPackage:true,
    defaultBuildFolder:nil,
    defaultBuildConfiguration:nil,
    defaultTarget:nil,
    defaultProjectDirectory:nil
    )
    # The device to use if one isn't in $device, and isn't passed in
    # @configurationDevice = {name: '📱 iPhone 5s Black', ip:'192.168.1.161'}
    # @configurationDevice = {name: '📱 iPad Mini', ip:'192.168.1.158'}
    # @configurationDevice = {name: '📱 iPhone 6+', ip:'192.168.1.163'}
    @configurationDevice = {name: '📱 iPhone 5', ip:'192.168.1.153'}

    @configurationAppToTerminate = nil
    @configurationAppToLaunch = nil
    @configurationShouldInstallOnDevice = false
    @configruationShouldBuildPackage = true
    @configurationBuildFolder = "#{$monolithBuildDirectory}/defaultBuild}"
    @configurationBuildConfiguration = "Release"
    @configurationTarget = ""
    @configurationProjectDirectory = $monolithProjectDirectory

    # defaults
    @defaultDevice = defaultDevice
    @defaultAppToTerminate = defaultAppToTerminate
    @defaultAppToLaunch = defaultAppToLaunch
    @defaultShouldInstallOnDevice = defaultShouldInstallOnDevice
    @defaultShouldBuildPackage = defaultShouldBuildPackage
    @defaultBuildFolder = defaultBuildFolder
    @defaultBuildConfiguration = defaultBuildConfiguration
    @defaultTarget = defaultTarget
    @defaultProjectDirectory = defaultProjectDirectory
  end # initialize

  def device()
    if $device
      return $device
    end

    if @defaultDevice
      return @defaultDevice
    end

    return @configurationDevice
  end

  def appToTerminate()
    if $appToTerminate
      return $appToTerminate
    end

    if @defaultAppToTerminate
      return @defaultAppToTerminate
    end

    return @configurationAppToTerminate
  end

  def appToLaunch()
    if $appToLaunch
      return $appToLaunch
    end

    if @defaultAppToLaunch
      return @defaultAppToLaunch
    end

    return @configurationAppToLaunch
  end

  def shouldInstallOnDevice()
    if defined?($shouldInstallOnDevice) != nil
      return $shouldInstallOnDevice
    end

    if defined?(@defaultShouldInstallOnDevice) != nil
      return @defaultShouldInstallOnDevice
    end

    return @configurationShouldInstallOnDevice
  end

  def shouldBuildPackage()
    if defined?($shouldBuildPackage) != nil
      return $shouldBuildPackage
    end

    if defined?(@defaultShouldBuildPackage) != nil
      return @defaultShouldBuildPackage
    end

    return @configurationShouldBuildPackage
  end

  def buildFolder()
    if $buildFolder
      return $buildFolder
    end

    if @defaultBuildFolder
      return @defaultBuildFolder
    end

    return @configurationBuildFolder
  end

  def buildConfiguration()
    if $buildConfiguration
      return $buildConfiguration
    end

    if @defaultBuildConfiguration
      return @defaultBuildConfiguration
    end

    return @configurationBuildConfiguration
  end

  def target()
    if $target
      return $target
    end

    if @defaultTarget
      return @defaultTarget
    end

    return @configurationTarget
  end

  def projectDirectory()
    if $projectDirectory
      return $projectDirectory
    end

    if @defaultProjectDirectory
      return @defaultProjectDirectory
    end

    return @configurationProjectDirectory
  end
end # Configuration
