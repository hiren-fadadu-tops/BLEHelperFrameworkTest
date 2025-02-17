Pod::Spec.new do |spec|

  spec.name         = "BLEHelperFrameworkTest"
  spec.version      = "1.0.0"
  spec.summary      = "A helper BLE framework to reduce redudant code"
  spec.description  = "A helper BLE framework, Consists tasks like scan, connect, read and write value on characteristics"
  spec.homepage     = "https://github.com/hiren-fadadu-tops/BLEHelperFrameworkTest"
  spec.license      = "MIT"
  spec.author             = { "hiren-fadadu-tops" => "hirenfadadu@topsinfosolutions.com" }
  spec.platform     = :ios, "18.0"
  spec.source       = { :git => "https://github.com/hiren-fadadu-tops/BLEHelperFrameworkTest.git", :tag => "#{spec.version}" }
  spec.source_files  = "BLEHelperFrameworkTest/**/*.{swift}"
  spec.framework  = "CoreBluetooth"
  spec.swift_versions = "5.0"
  
end
