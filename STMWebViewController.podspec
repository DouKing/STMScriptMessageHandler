#
# Be sure to run `pod lib lint STMWebViewController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'STMWebViewController'
  s.version          = '1.0.0'
  s.summary          = 'A web view controller that can communicate with js.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
    You can use this web view controller communicate with js.
                       DESC

  s.homepage         = 'https://github.com/douking/STMWebViewController'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'douking' => 'wyk1016@126.com' }
  s.source           = { :git => 'https://github.com/douking/STMWebViewController.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'STMWebViewController/Source/**/*'
  
  # s.resource_bundles = {
  #   'STMWebViewController' => ['STMWebViewController/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
