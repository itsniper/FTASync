#
# Be sure to run `pod spec lint FTASync.podspec' to ensure this is a
# valid spec.
#
# Remove all comments before submitting the spec. Optional attributes are commented.
#
# For details see: https://github.com/CocoaPods/CocoaPods/wiki/The-podspec-format
#
Pod::Spec.new do |s|
  s.name         = "FTASync"
  s.version      = "0.0.1"
  s.summary      = "Allows you to sync CoreData entities with a Parse backend."
  s.homepage     = "https://github.com/itsniper/FTASync"

  s.license      = { :type => 'Custom', :file => 'LICENSE.txt' }
  s.author       = { "Justin Bergen",  "Andy Bennett" => "andy@steamshift.net" }

  s.source       = { :git => "https://github.com/akbsteam/FTASync.git" }
  s.platform     = :ios

  s.source_files = 'Source', 'Source/*.{h,m}'
  s.dependency 'Parse', '>= 1.1.25'
end
