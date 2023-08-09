platform :ios, '13.0'

target 'xdrip' do

  use_frameworks!

  pod "ActionClosurable", :git => 'https://github.com/takasek/ActionClosurable.git'
  pod 'CryptoSwift', '1.4.0'
  pod 'PieCharts', '0.0.7'
  pod 'R.swift', '5.4.0'
  pod 'SnapKit', '5.0.1'
  pod 'CocoaLumberjack/Swift', '3.7.0'
  pod 'SwiftyJSON', '4.3.0'
  pod 'Charts', :tag => 'v3.6.5-th', :git => 'https://github.com/thinkluffy/Charts.git'
  pod 'FSCalendar', '2.8.2'
  pod 'PopupDialog', :tag => '1.1.1-th', :git => 'https://github.com/thinkluffy/PopupDialog.git'
  pod 'SwiftEventBus', :tag => '5.0.1', :git => 'https://github.com/cesarferreira/SwiftEventBus.git'
  pod 'Alamofire', '5.5.0'

  pod 'Firebase', '8.13.0', :subspecs => ['Analytics', 'Crashlytics', 'Performance']

  pod 'AppCenter'

end

post_install do |installer|
    installer.generated_projects.each do |project|
          project.targets.each do |target|
              target.build_configurations.each do |config|
                  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
               end
          end
   end
end
