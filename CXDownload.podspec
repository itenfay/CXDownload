#
# Be sure to run `pod lib lint CXDownload.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'CXDownload'
    s.version          = '2.0.0'
    s.summary          = 'Realization of breakpoint transmission download with Swift, support Objective-C.'
    
    # This description is used to generate tags and improve search results.
    #   * Think: What does it do? Why did you write it? What is the focus?
    #   * Try to keep it short, snappy and to the point.
    #   * Write the description between the DESC delimiters below.
    #   * Finally, don't worry about the indent, CocoaPods strips it!
    
    s.description      = <<-DESC
    Realization of breakpoint transmission download with Swift, support Objective-C.
    DESC
    
    s.homepage         = 'https://github.com/chenxing640/CXDownload'
    # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'chenxing' => 'chenxing640@foxmail.com' }
    s.source           = { :git => 'https://github.com/chenxing640/CXDownload.git', :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
    
    s.swift_versions = ['4.2', '5.0']
    s.ios.deployment_target = '10.0'
    s.osx.deployment_target = '11.0'
    s.tvos.deployment_target = '10.0'
    s.watchos.deployment_target = "5.0"
    
    s.requires_arc = true
    
    s.subspec "Base" do |base|
        base.source_files = 'CXDownload/Classes/Base/*.{swift}'
        base.requires_arc = true
    end
    
    s.subspec "Core" do |core|
        core.source_files = 'CXDownload/Classes/Core/*.{swift}'
        core.dependency 'CXDownload/Base'
        core.dependency 'FMDB'
        core.requires_arc = true
    end
    
    s.subspec "Extension" do |ex|
        ex.source_files = 'CXDownload/Classes/Extension/*.{swift}'
        ex.dependency 'CXDownload/Core'
        ex.requires_arc = true
    end
    
    # s.resource_bundles = {
    #   'CXDownload' => ['CXDownload/Assets/*.png']
    # }
    
    # s.public_header_files = 'Pod/Classes/**/*.h'
    # s.frameworks = 'UIKit', 'MapKit'
    # s.dependency 'AFNetworking', '~> 2.3'
    
end
