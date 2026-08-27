#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint bluetooth_print_plus.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'bluetooth_print_plus'
  s.version          = '2.4.5'
  s.summary          = 'A new Flutter project.'
  s.description      = <<-DESC
A new Flutter project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.static_framework = true
  s.dependency 'Flutter'

  # GSDK is vendored rather than pulled in as a pod dependency.
  #
  # GSDK 0.0.7's published podspec sources it from
  # https://gitee.com/besthandset/gsdk.git, and gitee now rejects anonymous
  # HTTPS clones of that repo ("reject by [gitee]"). Since `Pods/` is not
  # committed, every fresh `pod install` had to clone it, so git fell back to an
  # interactive credential prompt and the install hung on
  # "Username for 'https://gitee.com'".
  #
  # The framework below is GSDK 0.0.7 exactly as that pod installed it
  # (binary sha256 ce37a14a2084883dee1dc5fec07b7fbef212ffb34830ba96534d3c6c1ebd38fa,
  # from a checkout resolved against podspec checksum
  # 65d54603da7bece31b433c0f34f8a52c4431dd08). The pod was header-only source
  # plus this prebuilt static framework, so vendoring it loses nothing.
  #
  # `#import <GSDK/...>` in Classes/ keeps working: CocoaPods puts a vendored
  # framework's directory on FRAMEWORK_SEARCH_PATHS for this target.
  s.vendored_frameworks = 'Frameworks/GSDK.framework'
  s.platform = :ios, '11.0'
  s.static_framework = true

  # Flutter.framework does not contain a i386 slice.
  #
  # HEADER_SEARCH_PATHS points at the vendored framework's own Headers dir
  # because Classes/ imports GSDK headers two different ways: angled
  # (`<GSDK/BLEConnecter.h>`, resolved via FRAMEWORK_SEARCH_PATHS) and quoted
  # (`"CPCLCommand.h"` / `"EscCommand.h"` / `"TscCommand.h"`). The GSDK pod used
  # to publish all 11 headers into Pods/Headers/Public/GSDK, which put them on
  # the header search path and made both forms resolve. `vendored_frameworks`
  # contributes only framework search paths, so without this the quoted imports
  # fail with "'CPCLCommand.h' file not found". Both forms now resolve to the
  # same physical files, so nothing is declared twice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'HEADER_SEARCH_PATHS' => '$(inherited) "$(PODS_TARGET_SRCROOT)/Frameworks/GSDK.framework/Headers"',
  }
end
