#
# Be sure to run `pod lib lint CXDownload.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'CXDownload'
    s.version          = '2.0.1'
    s.summary          = 'Realization of breakpoint transmission download with Swift, support Objective-C.'
    
    # This description is used to generate tags and improve search results.
    #   * Think: What does it do? Why did you write it? What is the focus?
    #   * Try to keep it short, snappy and to the point.
    #   * Write the description between the DESC delimiters below.
    #   * Finally, don't worry about the indent, CocoaPods strips it!
    
    s.description      = <<-DESC
    Realization of breakpoint transmission download with Swift, support Objective-C. Including large file download, background download, killing the process, continuing to download when restarting, setting the number of concurrent downloads, monitoring network changes and so on.
    DESC
    
    s.homepage         = 'https://github.com/chenxing640/CXDownload'
    # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Teng Fei' => 'hansen981@126.com' }
    s.source           = { :git => 'https://github.com/chenxing640/CXDownload.git', :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
    
    s.swift_versions = ['4.2', '5.0']
    s.ios.deployment_target = '11.0'
    s.osx.deployment_target = '11.0'
    #s.tvos.deployment_target = '11.0' #ERROR | [tvOS] unknown: Encountered an unknown error (The platform of the target `App` (tvOS 11.0) is not compatible with `FMDB (2.7.9)`, which does not support `tvOS`.) during validation.
    s.watchos.deployment_target = "7.0"
    
    s.default_subspecs = 'Core', 'Extension'
    s.requires_arc = true
    
    s.subspec "Base" do |base|
        base.source_files = 'CXDownload/Classes/Base/*.{swift}'
        base.requires_arc = true
    end
    
    s.subspec "Core" do |core|
        core.source_files = 'CXDownload/Classes/Core/*.{swift}'
        core.dependency 'CXDownload/Base'
        core.dependency 'FMDB'
    end
    
    s.subspec "Extension" do |ex|
        ex.source_files = 'CXDownload/Classes/Extension/*.{swift}'
        ex.dependency 'CXDownload/Core'
    end
    
    # s.resource_bundles = {
    #   'CXDownload' => ['CXDownload/Assets/*.png']
    # }
    
    # s.public_header_files = 'Pod/Classes/**/*.h'
    # s.frameworks = 'UIKit', 'MapKit'
    # s.dependency 'AFNetworking', '~> 2.3'
    
end
