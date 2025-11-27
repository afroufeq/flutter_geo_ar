#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_geo_ar.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_geo_ar'
  s.version          = '0.0.3'
  s.summary          = 'Geo-AR plugin for Flutter with Native Sensor Fusion, DEM support, and Visual Correction.'
  s.description      = <<-DESC
Geo-AR plugin for Flutter. Optimized v1.5 with Native Sensor Fusion, Isolate Offloading, DEM support, and Visual Correction.
Provides real-time augmented reality visualization of geographic points of interest with advanced sensor fusion and visual tracking.
                       DESC
  s.homepage         = 'https://github.com/afroufeq/flutter_geo_ar'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'TrackingSport SL' => 'https://github.com/afroufeq' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # Privacy manifest for required reason APIs (camera, sensors, location)
  s.resource_bundles = {'flutter_geo_ar_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
