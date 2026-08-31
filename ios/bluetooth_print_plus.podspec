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

  # GSDK is vendored as an xcframework rather than pulled in as a pod
  # dependency, for two independent reasons.
  #
  # 1. Its published podspec sources it from
  #    https://gitee.com/besthandset/gsdk.git, and gitee now rejects anonymous
  #    HTTPS clones ("reject by [gitee]"). Since `Pods/` is not committed, every
  #    fresh `pod install` had to clone it, so git fell back to an interactive
  #    prompt and hung on "Username for 'https://gitee.com'".
  #
  # 2. Every slice of the original library — arm64 included — is tagged
  #    LC_VERSION_MIN_IPHONEOS, i.e. iOS *device*. Xcode will not link a
  #    device-tagged arm64 slice into an arm64 simulator build, and Xcode 26
  #    ships only arm64-only simulator runtimes, so the old x86_64 escape hatch
  #    is gone. Consumers previously worked around this with
  #    EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64, which stopped working the
  #    moment no x86_64 simulator existed.
  #
  # The xcframework carries the real library for `ios-arm64` (device builds are
  # bit-for-bit unaffected) and a no-op stub for
  # `ios-arm64_x86_64-simulator`. Nothing is lost: GSDK drives a Bluetooth
  # printer and simulators have no Bluetooth, so that path was never usable
  # there. See tool/gsdk-simulator-stub/ for the stub source and the script that
  # regenerates this artifact.
  #
  # Classes/ imports GSDK exclusively as `<GSDK/Header.h>`, which resolves via
  # FRAMEWORK_SEARCH_PATHS against whichever slice is selected for the current
  # SDK. No HEADER_SEARCH_PATHS entry is needed.
  s.vendored_frameworks = 'Frameworks/GSDK.xcframework'
  s.platform = :ios, '11.0'
  s.static_framework = true

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
