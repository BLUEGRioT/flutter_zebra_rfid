#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_zebra_rfid.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_zebra_rfid'
  s.version          = '0.0.1'
  s.summary          = 'A wrapper plugin for the iOS SDK of Zebra RFID reader'
  s.description      = <<-DESC
  A wrapper plugin for the iOS SDK of Zebra RFID reader
                       DESC
  s.homepage         = 'https://bluegriot.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'BLUEGRioT' => 'frobin@bluegriot.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.static_framework = true 
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.frameworks = 'CoreBluetooth', 'ExternalAccessory'
  s.subspec 'symbolrfid-sdk' do |symbolrfid|
    symbolrfid.preserve_paths = 'libraries/symbolrfid-sdk/include/*.h'
    symbolrfid.source_files = 'libraries/symbolrfid-sdk/include/*'
    symbolrfid.vendored_libraries = 'libraries/symbolrfid-sdk/libsymbolrfid-sdk.a'
    symbolrfid.xcconfig = { 'HEADER_SEARCH_PATHS' => "${PODS_ROOT}/../.symlinks/plugins/#{s.name}/ios/libraries/symbolrfid-sdk/include/**" }
  end

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
