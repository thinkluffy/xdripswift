import UIKit
import CoreData
import OSLog

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - Properties
    
    var window: UIWindow?
    
    private static let log = Log(type: AppDelegate.self)

    // MARK: - Application Life Cycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Log.setup(level: UserDefaults.standard.OSLogEnabled ? .verbose : .warning)

        AppDelegate.log.i("==> didFinishLaunchingWithOptions")
        		
        WatchCommunicator.register()
        
        setupUIComponents()

        if UserDefaults.standard.firstOpenTime == nil {
            onFreshInstall()
        }
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }
    
    private func onFreshInstall() {
        AppDelegate.log.i("==> onFreshInstall")
        UserDefaults.standard.firstOpenTime = Date()
    }
}

extension AppDelegate {
    
    private func setupUIComponents() {
        // Toast
        var style = ToastStyle()
        style.backgroundColor = .white
        style.verticalMargin = 80
        style.verticalPadding = 10
        style.horizontalPadding = 20
        style.slideInAndOut = true
        style.titleColor = .hex(0xff1f2033)
        style.messageColor = .hex(0xff1f2033)
        ToastManager.shared.style = style
    }
}

