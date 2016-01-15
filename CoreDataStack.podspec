#
#  Be sure to run `pod spec lint CoreDataStack.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "CoreDataStack"
  s.version      = "0.0.1"
  s.summary      = "CoreDataStack concurrency implementation"
  s.description  = <<-DESC
                        CoreDataStack concurrency implementation
                   DESC
  s.homepage     = "https://github.com/crekby/CoreDataStack-Swift"
  s.license      = "MIT"
  s.author       = { "Aliaksandr Skulin" => "aliaksandr.skulin@instinctools.ru" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/crekby/CoreDataStack-Swift.git", :tag => s.version.to_s }
  s.source_files  = "Classes/**/*.{swift}", "CoreDataStack.h"
  s.framework  = "CoreData"


end
