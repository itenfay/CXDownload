#
# Be sure to run `pod lib lint CXDownload.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'CXDownload'
    s.version          = '1.0.2'
    s.summary          = 'Implements Swift breakpoint continuation download for iOS.'
    
    # This description is used to generate tags and improve search results.
    #   * Think: What does it do? Why did you write it? What is the focus?
    #   * Try to keep it short, snappy and to the point.
    #   * Write the description between the DESC delimiters below.
    #   * Finally, don't worry about the indent, CocoaPods strips it!
    
    s.description      = <<-DESC
    Implements Swift breakpoint continuation download for iOS.
    DESC
    
    s.homepage         = 'https://github.com/chenxing640/CXDownload'
    # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'chenxing' => 'chenxing640@foxmail.com' }
    s.source           = { :git => 'https://github.com/chenxing640/CXDownload.git', :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
    
    s.swift_versions = ['4.2', '5.0']
    s.ios.deployment_target = '9.0'
    s.osx.deployment_target = '10.9'
    s.tvos.deployment_target = '9.0'
    s.watchos.deployment_target = "5.0"
    
    s.requires_arc = true
    
    s.subspec "Core" do |core|
        core.source_files = 'CXDownload/Classes/Core/*'
        core.requires_arc = true
    end
    
    s.subspec "Extension" do |ex|
        ex.source_files = 'CXDownload/Classes/Extension/*'
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
