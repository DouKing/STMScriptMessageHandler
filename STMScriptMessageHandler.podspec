Pod::Spec.new do |s|
  s.name             = 'STMScriptMessageHandler'
  s.version          = '2.0.2'
  s.summary          = 'A script message handler that conform to the WKScriptMessageHandler protocol. It is used to communicate with js.'
  
  s.description      = <<-DESC
    You can use it to communicate with js.
                       DESC

  s.homepage         = 'https://github.com/douking/STMScriptMessageHandler'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'douking' => 'wyk1016@126.com' }
  s.source           = { :git => 'https://github.com/douking/STMScriptMessageHandler.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'STMScriptMessageHandler/Source/**/*'
end
