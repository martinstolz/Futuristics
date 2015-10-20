Pod::Spec.new do |s|
  s.name = 'Futuristics'
  s.version = '0.1.0-alpha'
  s.license = { :type => "MIT" }
  s.summary = 'Futures for Swift 2.0'
  s.homepage = 'https://github.com/AlexanderNey/PromiseME'
  s.social_media_url = 'http://twitter.com/Ajax64'
  s.authors = { 'Alexander Ney' => 'alexander.ney@me.com' }
  s.source = { :git => 'https://github.com/AlexanderNey/PromiseME.git', :branch => 'alpha'}
  s.requires_arc = true
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'

  s.source_files = 'Source/*.swift'

end