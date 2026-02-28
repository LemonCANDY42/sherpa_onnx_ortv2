#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint sherpa_onnx_ortv2_ios.podspec` to validate before publishing.
#
# See also
# https://github.com/google/webcrypto.dart/blob/2010361a106d7a872d90e3dfebfed250e2ede609/ios/webcrypto.podspec#L23-L28
# https://groups.google.com/g/dart-ffi/c/nUATMBy7r0c
Pod::Spec.new do |s|
  s.name             = 'sherpa_onnx_ortv2_ios'
  s.version          = '1.12.25-ortv2.0'
  s.summary          = 'Flutter FFI iOS plugin for sherpa_onnx_ortv2 runtime binaries.'
  s.description      = <<-DESC
Flutter FFI iOS plugin package for sherpa_onnx_ortv2.
                       DESC
  s.homepage         = 'https://github.com/LemonCANDY42/sherpa_onnx_ortv2'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Fangjun Kuang' => 'csukuangfj@gmail.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.preserve_paths = 'sherpa_onnx.xcframework/**/*'
  s.vendored_frameworks = 'sherpa_onnx.xcframework'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
    }
  s.swift_version = '5.0'
end

