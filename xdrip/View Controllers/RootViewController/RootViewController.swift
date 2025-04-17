import UIKit
import CoreData
import os
import UserNotifications
import HealthKitUI
import AVFoundation
import PieCharts
import Charts
import PopupDialog
import FirebasePerformance

/// viewController for the home screen
final class RootViewController: UIViewController {

    private static let log = Log(type: RootViewController.self)

    // MARK: - Properties - Outlets and Actions for buttons and labels in home screen

    @IBOutlet weak var snoozeButton: UIButton!

    /// outlet for label that shows how many minutes ago and so on
    @IBOutlet weak var minutesLabelOutlet: UILabel!

    /// outlet for label that shows difference with previous reading
    @IBOutlet weak var diffLabelOutlet: UILabel!

    @IBOutlet weak var glucoseIndicator: GlucoseIndicator!

    /// outlet for chart
    @IBOutlet weak var glucoseChart: GlucoseChart!
    @IBOutlet weak var newReadingCountDownView: CountDownView!

    @IBOutlet weak var chartHoursSelection: SingleSelection!
    @IBOutlet weak var statisticsDaysSelection: SingleSelection!

    /// outlets for statistics view
    @IBOutlet weak var statisticsView: StatisticsView!

    @IBOutlet weak var sensorCountdown: SensorCountdown!

    @IBAction func showChartDetailsButtonClicked(_ sender: UIButton) {
        performSegue(withIdentifier: R.segue.rootViewController.chartDetails, sender: self)
    }

    // MARK: - Constants for ApplicationManager usage

    /// constant for key in ApplicationManager.shared.addClosureToRunWhenAppWillEnterForeground - create updateLabelsAndChartTimer
    private let appManagerKeyCreateupdateLabelsAndChartTimer = "rvc://CreateupdateLabelsAndChartTimer"

    /// constant for key in ApplicationManager.shared.addClosureToRunWhenAppDidEnterBackground
    private let appManagerKeyInvalidateupdateLabelsAndChartTimerAndCloseSnoozeViewController = "rvc://invalidateupdateLabelsAndChartTimerAndCloseSnoozeViewController"

    /// constant for key in ApplicationManager.shared.addClosureToRunWhenAppWillEnterForeground - initial calibration
    private let appManagerKeyInitialCalibration = "rvc://initialCalibration"

    /// constant for key in ApplicationManager.shared.addClosureToRunWhenAppDidEnterBackground -  isIdleTimerDisabled
    private let appManagerKeyIsIdleTimerDisabled = "rvc://isIdleTimerDisabled"

    /// constant for key in ApplicationManager.shared.addClosureToRunWhenAppDidEnterBackground - trace that app goes to background
    private let appManagerKeyTraceAppGoesToBackground = "rvc://traceAppGoesToBackground"

    /// constant for key in ApplicationManager.shared.addClosureToRunWhenAppDidEnterBackground - trace that app goes to background
    private let appManagerKeyReleaseMemoryAppGoesToBackground = "rvc://releaseMemoryAppGoesToBackground"

    /// constant for key in ApplicationManager.shared.addClosureToRunWhenAppWillEnterForeground - trace that app goes to background
    private let appManagerKeyTraceAppGoesToForeground = "rvc://traceAppGoesToForeground"

    /// constant for key in ApplicationManager.shared.addClosureToRunWhenAppWillTerminate - trace that app goes to background
    private let appManagerKeyTraceAppWillTerminate = "rvc://traceAppWillTerminate"

    /// constant for key in ApplicationManager.shared.addClosureToRunWhenAppWillEnterForeground - to initialize the glucoseChartManager and update labels and chart
    private let appManagerKeyUpdateLabelsAndChartAppGoesToForeground = "rvc://updateLabelsAndChart"

    /// constant for key in ApplicationManager.shared.addClosureToRunWhenAppWillEnterForeground - to dismiss screenLockAlertController
    private let appManagerKeyDismissScreenLockAlertController = "rvc://dismissScreenLockAlertController"

    // MARK: - Properties - other private properties

    /// for logging
    private var log = OSLog(subsystem: ConstantsLog.subSystem, category: ConstantsLog.categoryRootView)

    /// to solve problem that sometemes UserDefaults key value changes is triggered twice for just one change
    private let keyValueObserverTimeKeeper: KeyValueObserverTimeKeeper = KeyValueObserverTimeKeeper()

    /// BgReadingsAccessor instance
    private let bgReadingsAccessor = BgReadingsAccessor()

    /// CalibrationsAccessor instance
    private let calibrationsAccessor = CalibrationsAccessor()

    /// SoundPlayer instance
    private var soundPlayer: SoundPlayer?

    /// healthkit manager instance
    private let healthKitManager = HealthKitManager()

    /// reference to activeSensor
    private var activeSensor: Sensor?

    /// reference to bgReadingSpeaker
    private let bgReadingSpeaker = BGReadingSpeaker()

    /// statisticsManager instance
    private var statisticsManager: StatisticsManager?

    /// dateformatter for minutesLabelOutlet, when user is panning the chart
    private let dateTimeFormatterForMinutesLabelWhenPanning: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ConstantsGlucoseChart.dateFormatLatestChartPointWhenPanning

        return dateFormatter
    }()

    /// housekeeper instance
    private let houseKeeper = HouseKeeper()

    /// current value of webOPEnabled, if nil then it means no cgmTransmitter connected yet , false is used as value
    /// - used to detect changes in the value
    ///
    /// in fact it will never be used with a nil value, except when connecting to a cgm transmitter for the first time
    private var webOOPEnabled: Bool?

    /// current value of nonFixedSlopeEnabled, if nil then it means no cgmTransmitter connected yet , false is used as value
    /// - used to detect changes in the value
    ///
    /// in fact it will never be used with a nil value, except when connecting to a cgm transmitter for the first time
    private var nonFixedSlopeEnabled: Bool?

    /// when was the last notification created with bgreading, setting to 1 1 1970 initially to avoid having to unwrap it
    private var timeStampLastBGNotification = Date(timeIntervalSince1970: 0)

    private var selectedChartHours = ChartHours(rawValue: UserDefaults.standard.chartWidthInHours) ?? ChartHours.h3

    private var alertSheet: SlideInSheet?

    private var presenter: RootP!

    // set the status bar content colour to light to match new darker theme
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.setNoBackground()

        activeSensor = SensorsAccessor().fetchActiveSensor()

        // viewWillAppear when user switches eg from Settings Tab to Home Tab - latest reading value needs to be shown on the view, and also update minutes ago etc.
        updateLabelsAndChart(overrideApplicationState: true)

        // update statistics related outlets
        updateStatistics(animatePieChart: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presenter.onViewDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        presenter.onViewWillDisappear()
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        instancePresenter()

        // chart hours
        var chartHoursItems = [SingleSelectionItem]()
        chartHoursItems.append(SingleSelectionItem(id: ChartHours.h1.rawValue, title: "1H"))
        chartHoursItems.append(SingleSelectionItem(id: ChartHours.h3.rawValue, title: "3H"))
        chartHoursItems.append(SingleSelectionItem(id: ChartHours.h6.rawValue, title: "6H"))
        chartHoursItems.append(SingleSelectionItem(id: ChartHours.h12.rawValue, title: "12H"))
        chartHoursItems.append(SingleSelectionItem(id: ChartHours.h24.rawValue, title: "24H"))
        chartHoursSelection.show(items: chartHoursItems)
        chartHoursSelection.delegate = self

        chartHoursSelection.select(id: selectedChartHours.rawValue, triggerCallback: false)

        // statistics time range
        var daysToUseStatisticsItems = [SingleSelectionItem]()
        daysToUseStatisticsItems.append(SingleSelectionItem(id: ChartDays.today.rawValue,
                title: R.string.common.today()))
        daysToUseStatisticsItems.append(SingleSelectionItem(id: ChartDays.day7.rawValue,
                title: "7D"))
        daysToUseStatisticsItems.append(SingleSelectionItem(id: ChartDays.day14.rawValue,
                title: "14D"))
        daysToUseStatisticsItems.append(SingleSelectionItem(id: ChartDays.day30.rawValue,
                title: "30D"))
        daysToUseStatisticsItems.append(SingleSelectionItem(id: ChartDays.day90.rawValue,
                title: "90D"))
        statisticsDaysSelection.show(items: daysToUseStatisticsItems)
        statisticsDaysSelection.delegate = self

        let statisticsDays = ChartDays(rawValue: UserDefaults.standard.daysToUseStatistics) ?? ChartDays.today
        statisticsDaysSelection.select(id: statisticsDays.rawValue, triggerCallback: false)

        // Setup Core Data Manager - setting up coreDataManager happens asynchronously
        // completion handler is called when finished. This gives the app time to already continue setup which is independent of coredata, like initializing the views
        setupApplicationData()

        // housekeeper should be non nil here, call housekeeper
        houseKeeper.doAppStartUpHouseKeeping()

        // create badge counter
        createBgReadingNotificationAndSetAppBadge(overrideShowReadingInNotification: true)

        // Setup View
        setupView()

        // observe setting changes
        // changing from follower to master or vice versa
        UserDefaults.standard.addObserver(self, forKeyPath: UserDefaults.Key.isMaster.rawValue, options: .new, context: nil)

        // bg reading notification and badge, and multiplication factor
        UserDefaults.standard.addObserver(self, forKeyPath: UserDefaults.Key.showReadingInNotification.rawValue, options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: UserDefaults.Key.showReadingInAppBadge.rawValue, options: .new, context: nil)
        // also update of unit requires update of badge
        UserDefaults.standard.addObserver(self, forKeyPath: UserDefaults.Key.bloodGlucoseUnitIsMgDl.rawValue, options: .new, context: nil)

        // setup delegate for UNUserNotificationCenter
        UNUserNotificationCenter.current().delegate = self

        // check if app is allowed to send local notification and if not ask it
        UNUserNotificationCenter.current().getNotificationSettings { (notificationSettings) in
            switch notificationSettings.authorizationStatus {
            case .notDetermined, .denied:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (success, error) in
                    if let error = error {
                        trace("Request Notification Authorization Failed : %{public}@", log: self.log, category: ConstantsLog.categoryRootView, type: .error, error.localizedDescription)
                    }
                }
            default:
                break
            }
        }

        // setup the timer logic for updating the view regularly
        setupUpdateLabelsAndChartTimer()

        // setup AVAudioSession
        setupAVAudioSession()

        // user may have activated the screen lock function so that the screen stays open, when going back to background, set isIdleTimerDisabled back to false and update the UI so that it's ready to come to foreground when required.
        ApplicationManager.shared.addClosureToRunWhenAppDidEnterBackground(key: appManagerKeyIsIdleTimerDisabled) {
            UIApplication.shared.isIdleTimerDisabled = false
        }

        // add tracing when app goes from foreground to background
        ApplicationManager.shared.addClosureToRunWhenAppDidEnterBackground(key: appManagerKeyTraceAppGoesToBackground) {
            trace("Application did enter background", log: self.log, category: ConstantsLog.categoryRootView, type: .info)
        }

        ApplicationManager.shared.addClosureToRunWhenAppDidEnterBackground(key: appManagerKeyReleaseMemoryAppGoesToBackground) {
            [weak self] in

            self?.glucoseChart.cleanUpMemory()
        }

        // add tracing when app comes to foreground
        ApplicationManager.shared.addClosureToRunWhenAppWillEnterForeground(key: appManagerKeyTraceAppGoesToForeground) {
            trace("Application will enter foreground", log: self.log, category: ConstantsLog.categoryRootView, type: .info)
        }

        // add tracing when app will termination - this only works for non-suspended apps, probably (not tested) also works for apps that crash in the background
        ApplicationManager.shared.addClosureToRunWhenAppWillTerminate(key: appManagerKeyTraceAppWillTerminate) {
            trace("Application will terminate", log: self.log, category: ConstantsLog.categoryRootView, type: .info)
        }

        // reinitialise glucose chart and also to update labels and chart
        ApplicationManager.shared.addClosureToRunWhenAppWillEnterForeground(key: appManagerKeyUpdateLabelsAndChartAppGoesToForeground) {
            [weak self] in

            self?.updateLabelsAndChart(overrideApplicationState: true)
            // update statistics related outlets
            self?.updateStatistics(animatePieChart: false, doEvenAppNotActive: true)

            self?.presenter.loadChartReadings()
        }
    }

    private func instancePresenter() {
        presenter = RootPresenter(view: self)
    }

    /// sets AVAudioSession category to AVAudioSession.Category.playback with option mixWithOthers and
    /// AVAudioSession.sharedInstance().setActive(true)
    private func setupAVAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)

        } catch let error {
            trace("in init, could not set AVAudioSession category to playback and mixwithOthers, error = %{public}@", log: log, category: ConstantsLog.categoryRootView, type: .error, error.localizedDescription)
        }
    }

    private func setupApplicationData() {

        // get currently active sensor
        activeSensor = SensorsAccessor().fetchActiveSensor()
        if let activeSensor = activeSensor {
            RootViewController.log.d("Got activeSensor: \(activeSensor.log(indentation: "ActiveSensor"))")
        }

//        SensorsAccessor().listSensors(on: CoreDataManager.shared.mainManagedObjectContext)

        // initialize statisticsManager
        statisticsManager = StatisticsManager()

    }

    /// closes the SnoozeViewController if it is being presented now
    private func closeSnoozeViewController() {
        if let presentedViewController = presentedViewController,
           let snoozeViewController = presentedViewController as? SnoozeViewController {
            snoozeViewController.dismiss(animated: true, completion: nil)
        }
    }

    /// used by observevalue for UserDefaults.Key
    private func evaluateUserDefaultsChange(keyPathEnum: UserDefaults.Key) {

        // first check keyValueObserverTimeKeeper
        switch keyPathEnum {

        case UserDefaults.Key.isMaster,
             UserDefaults.Key.showReadingInAppBadge,
             UserDefaults.Key.bloodGlucoseUnitIsMgDl:

            // transmittertype change triggered by user, should not be done within 200 ms
            if !keyValueObserverTimeKeeper.verifyKey(forKey: keyPathEnum.rawValue, withMinimumDelayMilliSeconds: 200) {
                return
            }

        default:
            break

        }

        switch keyPathEnum {

        case UserDefaults.Key.isMaster:
			break

        case UserDefaults.Key.showReadingInNotification:
            if !UserDefaults.standard.showReadingInNotification {
                // remove existing notification if any
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [ConstantsNotifications.NotificationIdentifierForBgReading.bgReadingNotificationRequest])

            }

        case UserDefaults.Key.showReadingInAppBadge, UserDefaults.Key.bloodGlucoseUnitIsMgDl:

            // if showReadingInAppBadge = false, means user set it from true to false
            // set applicationIconBadgeNumber to 0. This will cause removal of the badge counter, but als removal of any existing notification on the screen
            if !UserDefaults.standard.showReadingInAppBadge {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }

            // this will trigger update of app badge, will also create notification, but as app is most likely in foreground, this won't show up
            createBgReadingNotificationAndSetAppBadge(overrideShowReadingInNotification: true)

        default:
            break

        }
    }

    // MARK:- observe function

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {

        guard let keyPath = keyPath else {
            return
        }

        if let keyPathEnum = UserDefaults.Key(rawValue: keyPath) {
            evaluateUserDefaultsChange(keyPathEnum: keyPathEnum)
        }
    }

    // MARK: - View Methods

    /// Configure View, only stuff that is independent of coredata
    private func setupView() {
        // set texts for buttons on top

        snoozeButton.on(.touchUpInside) { [unowned self] _ in
            guard let snoozeAlarmsViewController = R.storyboard.main.snoozeAlarms() else {
                return
            }

            present(snoozeAlarmsViewController, animated: true)
        }

        glucoseChart.chartHours = selectedChartHours
        glucoseChart.isLongPressSupported = true
        glucoseChart.delegate = self
    }

    // MARK: - private helper functions

    /// creates notification
    private func createNotification(title: String?, body: String?, identifier: String, sound: UNNotificationSound?) {

        // Create Notification Content
        let notificationContent = UNMutableNotificationContent()

        // Configure NotificationContent title
        if let title = title {
            notificationContent.title = title
        }

        // Configure NotificationContent body
        if let body = body {
            notificationContent.body = body
        }

        // configure sound
        if let sound = sound {
            notificationContent.sound = sound
        }

        // Create Notification Request
        let notificationRequest = UNNotificationRequest(identifier: identifier, content: notificationContent, trigger: nil)

        // Add Request to User Notification Center
        UNUserNotificationCenter.current().add(notificationRequest) { (error) in
            if let error = error {
                trace("Unable to create notification %{public}@", log: self.log, category: ConstantsLog.categoryRootView, type: .error, error.localizedDescription)
            }
        }
    }

    /// launches timer that will do regular screen updates - and adds closure to ApplicationManager : when going to background, stop the timer, when coming to foreground, restart the timer
    ///
    /// should be called only once immediately after app start, ie in viewdidload
    private func setupUpdateLabelsAndChartTimer() {

        // set timeStampAppLaunch to now
        UserDefaults.standard.timeStampAppLaunch = Date()

        // this is the actual timer
        var updateLabelsAndChartTimer: Timer?

        // create closure to invalide the timer, if it exists
        let invalidateUpdateLabelsAndChartTimer = {
            if let updateLabelsAndChartTimer = updateLabelsAndChartTimer {
                updateLabelsAndChartTimer.invalidate()
            }
            updateLabelsAndChartTimer = nil
        }

        // create closure that launches the timer to update the first view every x seconds, and returns the created timer
        let createAndScheduleUpdateLabelsAndChartTimer: () -> Timer = {
            // check if timer already exists, if so invalidate it
            invalidateUpdateLabelsAndChartTimer()
            // now recreate, schedule and return
            return Timer.scheduledTimer(timeInterval: Constants.updateHomeViewIntervalInSeconds, target: self, selector: #selector(self.updateLabelsAndChart), userInfo: nil, repeats: true)
        }

        // call scheduleUpdateLabelsAndChartTimer function now - as the function setupUpdateLabelsAndChartTimer is called from viewdidload, it will be called immediately after app launch
        updateLabelsAndChartTimer = createAndScheduleUpdateLabelsAndChartTimer()

        // updateLabelsAndChartTimer needs to be created when app comes back from background to foreground
        ApplicationManager.shared.addClosureToRunWhenAppWillEnterForeground(key: appManagerKeyCreateupdateLabelsAndChartTimer) {
            updateLabelsAndChartTimer = createAndScheduleUpdateLabelsAndChartTimer()
        }

        // when app goes to background
        ApplicationManager.shared.addClosureToRunWhenAppDidEnterBackground(key: appManagerKeyInvalidateupdateLabelsAndChartTimerAndCloseSnoozeViewController) {

            // this is for the case that the snoozeViewController is shown. If not removed, then if user opens alert notification, the alert snooze wouldn't be shown
            // that's why, close the snoozeViewController
            self.closeSnoozeViewController()

            // updateLabelsAndChartTimer needs to be invalidated when app goes to background
            invalidateUpdateLabelsAndChartTimer()
        }
    }

    /// for debug purposes
    private func logAllBgReadings() {
        let readings = bgReadingsAccessor.getLatestBgReadings(limit: nil, howOld: nil, forSensor: nil, ignoreRawData: false, ignoreCalculatedValue: true)

        for (index, reading) in readings.enumerated() {
            if reading.sensor?.id == activeSensor?.id {
                RootViewController.log.i("readings[\(index)], timestamp: \(reading.timeStamp.description), calculatedValue: \(reading.calculatedValue)")
            }
        }
    }

    /// creates bgreading notification, and set app badge to value of reading
    /// - parameters:
    ///     - if overrideShowReadingInNotification then badge counter will be set (if enabled off course) with function UIApplication.shared.applicationIconBadgeNumber. To be used if badge counter is  to be set eg when UserDefaults.standard.showReadingInAppBadge is changed
    private func createBgReadingNotificationAndSetAppBadge(overrideShowReadingInNotification: Bool) {
        // get lastReading, with a calculatedValue - no check on activeSensor because in follower mode there is no active sensor
        let lastReading = bgReadingsAccessor.get2LatestBgReadings(minimumTimeIntervalInMinutes: 4.0)

        // if there's no reading for active sensor with calculated value , then no reason to continue
        if lastReading.count == 0 {
            RootViewController.log.i("in createBgReadingNotificationAndSetAppBadge, lastReading.count: 0")

            // remove the application badge number. Possibly an old reading is still shown.
            UIApplication.shared.applicationIconBadgeNumber = 0

            return
        }

        // if reading is older than 4.5 minutes, then also no reason to continue - this may happen eg in case of follower mode
        if Date().timeIntervalSince(lastReading[0].timeStamp) > 4.5 * 60 {

            RootViewController.log.i("in createBgReadingNotificationAndSetAppBadge, timestamp of last reading > 4.5 * 60")

            // remove the application badge number. Possibly the previous value is still shown
            UIApplication.shared.applicationIconBadgeNumber = 0

            return
        }

        // remove existing notification if any
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [ConstantsNotifications.NotificationIdentifierForBgReading.bgReadingNotificationRequest])

        // also remove the sensor not detected notification, if any
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [ConstantsNotifications.NotificationIdentifierForSensorNotDetected.sensorNotDetected])

        // prepare value for badge
        var readingValueForBadge = lastReading[0].calculatedValue
        // values lower dan 12 are special values, don't show anything
        guard readingValueForBadge > 12 else {
            return
        }

        // high limit to 400
        readingValueForBadge = min(readingValueForBadge, 400.0)

        // low limit ti 40
        readingValueForBadge = max(readingValueForBadge, 40.0)

        let isMg = UserDefaults.standard.bloodGlucoseUnitIsMgDl

        // check if notification on home screen is enabled in the settings
        // and also if last notification was long enough ago (longer than UserDefaults.standard.notificationInterval), except if there would have been a disconnect since previous notification (simply because I like getting a new reading with a notification by disabling/reenabling bluetooth
        if UserDefaults.standard.showReadingInNotification && !overrideShowReadingInNotification && (abs(timeStampLastBGNotification.timeIntervalSince(Date())) > Double(UserDefaults.standard.notificationInterval) * 60.0) {

            // Create Notification Content
            let notificationContent = UNMutableNotificationContent()

            // set value in badge if required
            if UserDefaults.standard.showReadingInAppBadge {
                // rescale of unit is mmol
                readingValueForBadge = readingValueForBadge.mgdlToMmol(mgdl: isMg)

                // if unit is mmol and if value needs to be multiplied by 10, then multiply by 10
                if !isMg {
                    readingValueForBadge = readingValueForBadge * 10.0
                }

                notificationContent.badge = NSNumber(value: Int(round(readingValueForBadge)))
            }

            var notificationTitle = BgReading.unitizedString(calculatedValue: lastReading[0].calculatedValue,
                    unitIsMgDl: isMg)
            var notificationBody = " "

            if !lastReading[0].hideSlope {
                notificationTitle += " " + lastReading[0].slopeArrow()
                notificationBody += lastReading[0].unitizedDeltaStringPerMin(withSlope: lastReading[0].calculatedValueSlope, showUnit: true, mgdl: isMg)
            }

            notificationContent.title = notificationTitle
            notificationContent.body = notificationBody

            // Create Notification Request
            let notificationRequest = UNNotificationRequest(identifier: ConstantsNotifications.NotificationIdentifierForBgReading.bgReadingNotificationRequest, content: notificationContent, trigger: nil)

            // Add Request to User Notification Center
            UNUserNotificationCenter.current().add(notificationRequest) { (error) in
                if let error = error {
                    trace("Unable to Add bg reading Notification Request %{public}@", log: self.log, category: ConstantsLog.categoryRootView, type: .error, error.localizedDescription)
                }
            }

            // set timeStampLastBGNotification to now
            timeStampLastBGNotification = Date()

        } else {
            // notification shouldn't be shown, but maybe the badge counter. Here the badge value needs to be shown in another way
            if UserDefaults.standard.showReadingInAppBadge {

                // rescale of unit is mmol
                readingValueForBadge = readingValueForBadge.mgdlToMmol(mgdl: isMg)

                // if unit is mmol and if value needs to be multiplied by 10, then multiply by 10
                if !isMg {
                    readingValueForBadge = readingValueForBadge * 10.0
                }

                UIApplication.shared.applicationIconBadgeNumber = Int(round(readingValueForBadge))
            }
        }
    }

    /// - updates the labels and the chart,
    /// - if app is in foreground
    /// - and if overrideApplicationState = false
    /// - parameters:
    ///     - overrideApplicationState : if true, then update will be done even if state is not .active
    @objc private func updateLabelsAndChart(overrideApplicationState: Bool = false) {
        guard UIApplication.shared.applicationState == .active || overrideApplicationState else {
            return
        }

        // set minutesLabelOutlet.textColor to white, might still be red due to panning back in time
        minutesLabelOutlet.textColor = UIColor.white

        presenter.loadChartReadings()

        // get latest readings, doesn't matter if it's for an active sensor or not, but it needs to have calculatedValue > 0 / which means, if user would have started a new sensor, but didn't calibrate yet, and a reading is received, then there's not going to be a latestReading
        // minus 20 secoonds for the readings may not be exactly 60 seconds per reading
        let latestReadings = bgReadingsAccessor.get2LatestBgReadings(minimumTimeIntervalInSeconds: Double(Constants.minsToCalculateSlope) * Date.minuteInSeconds - 20)

        // if there's no readings, then give empty fields and make sure the text isn't styled with strikethrough
        guard latestReadings.count > 0 else {
            diffLabelOutlet.text = ""

            glucoseIndicator.reading = nil
            minutesLabelOutlet.text = "--:--"

            return
        }

        // assign last reading
        let lastReading = latestReadings[0]

        let isMgDl = UserDefaults.standard.bloodGlucoseUnitIsMgDl

        var isReadingTooOld = false
        // if latestReading is older than 11 minutes, then it should be strikethrough
        if lastReading.timeStamp < Date(timeIntervalSinceNow: -Date.minuteInSeconds * 11) {
            isReadingTooOld = true
        }

        glucoseIndicator.reading = (
                valueInMgDl: lastReading.calculatedValue,
                showAsMgDl: isMgDl,
                slopeArrow: (isReadingTooOld || lastReading.hideSlope) ? nil : lastReading.slopArrow
        )

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm"
        minutesLabelOutlet.text = dateFormatter.string(from: lastReading.timeStamp)

        // assign last but one reading
        let lastButOneReading = latestReadings.count > 1 ? latestReadings[1] : nil

        // create delta text
        diffLabelOutlet.text = lastReading.unitizedDeltaStringPerMin(previousBgReading: lastButOneReading,
                showUnit: true,
                mgdl: UserDefaults.standard.bloodGlucoseUnitIsMgDl)
    }

    /// call alertManager.checkAlerts, and calls createBgReadingNotificationAndSetAppBadge with overrideShowReadingInNotification true or false, depending if immediate notification was created or not
    private func checkAlertsCreateNotificationAndSetAppBadge() {
        // unwrap alerts and check alerts
        // check if an immediate alert went off that shows the current reading
        if AlertManager.shared.checkAlerts(maxAgeOfLastBgReadingInSeconds: ConstantsFollower.maximumBgReadingAgeForAlertsInSeconds) {

            // an immediate alert went off that shows the current reading

            // possibily the app is in the foreground now
            // if user would have opened SnoozeViewController now, then close it, otherwise the alarm picker view will not be shown
            closeSnoozeViewController()

            // only update badge is required, (if enabled offcourse)
            createBgReadingNotificationAndSetAppBadge(overrideShowReadingInNotification: true)

        } else {
            // update notification and app badge
            createBgReadingNotificationAndSetAppBadge(overrideShowReadingInNotification: false)
        }
    }

    // helper function to calculate the statistics and update the pie chart and label outlets
    private func updateStatistics(animatePieChart: Bool = false, doEvenAppNotActive: Bool = false) {
        // don't calculate status if app is not running in the foreground
        guard UIApplication.shared.applicationState == .active || doEvenAppNotActive else {
            RootViewController.log.d("Skip updateStatistics, for app is NOT active")
            return
        }

        // get the maximum number of calculation days requested by the user
        let daysToUseStatistics = UserDefaults.standard.daysToUseStatistics
        var fromDate: Date

        // if the user has selected 0 (to chose "today") then set the fromDate to the previous midnight
        if daysToUseStatistics == 0 {
            fromDate = Calendar(identifier: .gregorian).startOfDay(for: Date())

        } else {
            fromDate = Date(timeIntervalSinceNow: -Date.dayInSeconds * Double(daysToUseStatistics))
        }

        // statisticsManager will calculate the statistics in background thread and call the callback function in the main thread
        statisticsManager?.calculateStatistics(fromDate: fromDate, toDate: nil) { statistics in
            self.statisticsView.show(statistics: statistics,
                    daysToUseStatistics: daysToUseStatistics,
                    animatePieChart: animatePieChart)
        }
    }
}

// MARK: - conform to UNUserNotificationCenterDelegate protocol

/// conform to UNUserNotificationCenterDelegate, for notifications
extension RootViewController: UNUserNotificationCenterDelegate {

    // called when notification created while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

		if notification.request.identifier == ConstantsNotifications.NotificationIdentifierForSensorNotDetected.sensorNotDetected {

            // call completionhandler to show the notification even though the app is in the foreground, without sound
            completionHandler([.alert])

        } else if let pickerViewData = AlertManager.shared.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler) {

            if let alertSheet = alertSheet {
                alertSheet.dismissView {
                    self.alertSheet = BottomSheetPickerViewController.show(in: self, pickerViewData: pickerViewData)
                }

            } else {
                alertSheet = BottomSheetPickerViewController.show(in: self, pickerViewData: pickerViewData)
            }

        } else if notification.request.identifier == ConstantsNotifications.notificationIdentifierForVolumeTest {
            // user is testing iOS Sound volume in the settings. Only the sound should be played, the alert itself will not be shown
            completionHandler([.sound])

        } else if notification.request.identifier == ConstantsNotifications.notificationIdentifierForxCGMTransmitterDelegatexDripError {

            // call completionhandler to show the notification even though the app is in the foreground, without sound
            completionHandler([.alert])

        }
    }

    // called when user clicks a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        trace("userNotificationCenter didReceive", log: log, category: ConstantsLog.categoryRootView, type: .info)

        // call completionHandler when exiting function
        defer {
            // call completionhandler
            completionHandler()
        }

        if response.notification.request.identifier == ConstantsNotifications.NotificationIdentifiersForCalibration.initialCalibrationRequest {

            // nothing required, the requestCalibration function will be called as it's been added to ApplicationManager
            trace("     userNotificationCenter didReceive, user pressed calibration notification to open the app, requestCalibration should be called because closure is added in ApplicationManager.shared", log: log, category: ConstantsLog.categoryRootView, type: .info)

        } else if response.notification.request.identifier == ConstantsNotifications.NotificationIdentifierForSensorNotDetected.sensorNotDetected {

            // if user clicks notification "sensor not detected", then show uialert with title and body
            let alert = PopupDialog(title: Texts_Common.warning,
                    message: Texts_HomeView.sensorNotDetected,
                    actionTitle: R.string.common.common_Ok(),
                    actionHandler: nil)

            present(alert, animated: true, completion: nil)

        } else if response.notification.request.identifier == ConstantsNotifications.NotificationIdentifierForTransmitterNeedsPairing.transmitterNeedsPairing {

            // nothing required, the pairing function will be called as it's been added to ApplicationManager in function cgmTransmitterNeedsPairing

        } else {
            // it's not an initial calibration request notification that the user clicked, by calling alertManager?.userNotificationCenter, we check if it was an alert notification that was clicked and if yes pickerViewData will have the list of alert snooze values
            if let pickerViewData = AlertManager.shared.userNotificationCenter(center, didReceive: response) {
                RootViewController.log.i("userNotificationCenter didReceive, user pressed an alert notification to open the app")

                if let alertSheet = alertSheet {
                    alertSheet.dismissView {
                        self.alertSheet = BottomSheetPickerViewController.show(in: self, pickerViewData: pickerViewData)
                    }

                } else {
                    alertSheet = BottomSheetPickerViewController.show(in: self, pickerViewData: pickerViewData)
                }

            } else {
                // it as also not an alert notification that the user clicked, there might come in other types of notifications in the future
            }
        }
    }

    private func showNewBGReadingToast() {
        tabBarController?.view.makeToast(R.string.homeView.toast_new_bg_reading(), duration: 2, position: .bottom)
    }
}

extension RootViewController: RootV {

    func showNewFollowerReading() {
        // update all text in first screen
        updateLabelsAndChart(overrideApplicationState: false)

        // update statistics related outlets
        updateStatistics(animatePieChart: false)

        // check alerts, create notification, set app badge
        checkAlertsCreateNotificationAndSetAppBadge()

        showNewBGReadingToast()
    }

    func show(chartReadings: [BgReading]?, from fromDate: Date, to toDate: Date) {
        glucoseChart.show(readings: chartReadings, from: fromDate, to: toDate, aheadSeconds: Date.minuteInSeconds * 10)
        glucoseChart.moveXAxisToTrailing()
    }

    func showSnoozeAlertsStatus(hasSnoozedAlerts: Bool) {
        let image = hasSnoozedAlerts ? R.image.ic_alarm_snoozed() : R.image.ic_alarm()
        snoozeButton.setImage(image, for: .normal)
    }
}

extension RootViewController: SingleSelectionDelegate {

    func singleSelectionItemWillSelect(_ singleSelection: SingleSelection, item: SingleSelectionItem) -> Bool {
        true
    }

    func singleSelectionItemDidSelect(_ singleSelection: SingleSelection, item: SingleSelectionItem) {
        if singleSelection == chartHoursSelection {
            selectedChartHours = ChartHours(rawValue: item.id) ?? ChartHours.h3
            UserDefaults.standard.chartWidthInHours = selectedChartHours.rawValue
            glucoseChart.chartHours = selectedChartHours

        } else if singleSelection == statisticsDaysSelection {
            UserDefaults.standard.daysToUseStatistics = item.id
            updateStatistics(animatePieChart: false)
        }
    }
}

extension RootViewController: GlucoseChartDelegate {

    func chartDidLongPressed(_ glucoseChart: GlucoseChart) {
        performSegue(withIdentifier: R.segue.rootViewController.chartDetails, sender: self)
    }
}

fileprivate class HourAxisValueFormatter: IAxisValueFormatter {

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date = Date(timeIntervalSince1970: value)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH"
        return dateFormatter.string(from: date)
    }
}
