platform :ios, '13.0'

target 'xdrip' do

  use_frameworks!

  pod "ActionClosurable", :git => 'https://github.com/takasek/ActionClosurable.git'
  pod 'CryptoSwift'
  pod 'PieCharts'
  pod 'R.swift'
  pod 'SnapKit'
  pod 'CocoaLumberjack/Swift'
  pod 'SwiftyJSON'
  pod 'Charts', :tag => 'v3.6.6-th', :git => 'https://github.com/thinkluffy/Charts.git'
  pod 'FSCalendar'
  pod 'PopupDialog', :tag => '1.1.1-th', :git => 'https://github.com/thinkluffy/PopupDialog.git'
  pod 'SwiftEventBus', :tag => '5.0.1', :git => 'https://github.com/cesarferreira/SwiftEventBus.git'
  pod 'Alamofire'

  pod 'Firebase', :subspecs => ['Analytics', 'Crashlytics', 'Performance']

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
