Pod::Spec.new do |s|
  s.name         = "Mocktail"
  s.version      = "1.2.1"
  s.summary      = "A simple(r) way to stub out HTTP servers in your Objective-C app."
  s.homepage     = "http://github.com/square/objc-mocktail"
  s.license      = 'Apache'
  s.author       = { "Jim Puls" => "jim@nondifferentiable.com" }
  s.source       = { :git => "https://github.com/square/objc-mocktail.git", :tag => "1.2.1" }
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  s.source_files = 'Mocktail'
  s.public_header_files = 'Mocktail/Mocktail.h'
  s.framework  = 'Foundation'
  s.requires_arc = true
end
