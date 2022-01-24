import UIKit
import CoreData
import os
import CoreBluetooth
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
    @IBOutlet weak var calibrateButton: UIButton!

    @IBOutlet weak var sensorIndicator: SensorIndicator!

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

    /// calibrator to be used for calibration, value will depend on transmitter type
    private var calibrator: Calibrator?

    /// BgReadingsAccessor instance
    private let bgReadingsAccessor = BgReadingsAccessor()

    /// CalibrationsAccessor instance
    private let calibrationsAccessor = CalibrationsAccessor()

    /// NightScoutUploadManager instance
    private var nightScoutUploadManager: NightScoutUploadManager?

    /// LoopManager instance
    private let loopManager = LoopManager()

    /// SoundPlayer instance
    private var soundPlayer: SoundPlayer?

    /// dexcomShareUploadManager instance
    private var dexcomShareUploadManager: DexcomShareUploadManager?

    /// healthkit manager instance
    private let healthKitManager = HealthKitManager()

    /// reference to activeSensor
    private var activeSensor: Sensor?

    /// reference to bgReadingSpeaker
    private let bgReadingSpeaker = BGReadingSpeaker()

    /// manages bluetoothPeripherals that this app knows
    private var bluetoothPeripheralManager: BluetoothPeripheralManager?

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

        // viewWillAppear when user switches eg from Settings Tab to Home Tab - latest reading value needs to be shown on the view, and also update minutes ago etc.
        updateLabelsAndChart(overrideApplicationState: true)

        // display the sensor countdown graphics if applicable
        updateSensorCountdown()

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

        // enable or disable the buttons 'sensor' and 'calibrate' on top, depending on master or follower
        changeButtonsStatusTo(enabled: UserDefaults.standard.isMaster)

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
            self?.updateSensorCountdown()
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

        // setup nightscout synchronizer
        nightScoutUploadManager = NightScoutUploadManager { (title: String, message: String) in
            let alert = PopupDialog(title: title,
                    message: message,
                    actionTitle: R.string.common.common_Ok(),
                    actionHandler: nil)
            self.present(alert, animated: true, completion: nil)
        }

        // setup dexcomShareUploadManager
        dexcomShareUploadManager = DexcomShareUploadManager { (title: String, message: String) in
            let alert = PopupDialog(title: title,
                    message: message,
                    actionTitle: R.string.common.common_Ok(),
                    actionHandler: nil)
            self.present(alert, animated: true, completion: nil)
        }

        // setup bluetoothPeripheralManager
        bluetoothPeripheralManager = BluetoothPeripheralManager(cgmTransmitterDelegate: self)

        // to initialize UserDefaults.standard.transmitterTypeAsString
        cgmTransmitterInfoDidChange()

        // initialize statisticsManager
        statisticsManager = StatisticsManager()

        presenter.setup(bluetoothPeripheralManager: bluetoothPeripheralManager!)
    }

    /// process new glucose data received from transmitter.
    /// - parameters:
    ///     - glucoseData : array with new readings
    ///     - sensorTimeInMinutes : should be present only if it's the first reading(s) being processed for a specific sensor and is needed if it's a transmitterType that returns true to the function canDetectNewSensor
    private func processNewGlucoseData(glucoseData: inout [GlucoseData], sensorAge: TimeInterval?) {
        let performanceTrace = Performance.startTrace(name: Events.processNewGlucoseData)

        defer {
            performanceTrace?.stop()
        }

        // unwrap calibrationsAccessor and coreDataManager and cgmTransmitter
        guard let cgmTransmitter = bluetoothPeripheralManager?.getCGMTransmitter() else {
            RootViewController.log.e("in processNewGlucoseData, calibrationsAccessor or coreDataManager or cgmTransmitter is nil")
            return
        }

        if activeSensor == nil {
            if let sensorAge = sensorAge, cgmTransmitter.cgmTransmitterType().canDetectNewSensor() {
                // no need to send to transmitter, because we received processNewGlucoseData, so transmitter knows the sensor already
                startSensor(cgmTransmitter: cgmTransmitter,
                        sensorStartDate: Date(timeIntervalSinceNow: -sensorAge),
                        sensorCode: nil,
                        sendToTransmitter: false)
            }
        }

        guard glucoseData.count > 0 else {
            trace("glucoseData.count = 0", log: log, category: ConstantsLog.categoryRootView, type: .info)
            return
        }

        // also for cases where calibration is not needed, we go through this code
        if let activeSensor = activeSensor, let calibrator = calibrator {

            RootViewController.log.i("calibrator: \(calibrator.description())")

            // initialize help variables
            var lastCalibrationsForActiveSensorInLastXDays = calibrationsAccessor.getLatestCalibrations(howManyDays: 4, forSensor: activeSensor)
            let firstCalibrationForActiveSensor = calibrationsAccessor.firstCalibrationForActiveSensor(withActiveSensor: activeSensor)
            let lastCalibrationForActiveSensor = calibrationsAccessor.lastCalibrationForActiveSensor(withActivesensor: activeSensor)


            // next is only if smoothing is enabled, and if there's at least 11 minutes of readings in the glucoseData array, which will normally only be the case for Libre with MM/Bubble
            // if that's the case then delete following existing BgReading's
            //  - younger than 11 minutes : why, because some of the Libre transmitters return readings of the last 15 minutes for every minute, we don't go further than 11 minutes because these readings are not so well smoothed
            //  - younger than the latest calibration : becuase if recalibration is used, then it might be difficult if there's been a recent calibration, to delete and recreate a reading with an earlier timestamp
            //  - younger or equal in age than the oldest reading in the GlucoseData array
            // why :
            //    - in case of Libre, using transmitters like Bubble, MM, .. the 16 most recent readings in GlucoseData are smoothed (done in LibreDataParser if smoothing is enabled)
            //    - specifically the reading at position 5, 6, 7....10 are well smoothed (because they are based on per minute readings of the last 15 minutes, inclusive 5 minutes before and 5 minutes after) we'll use
            //
            //  we will remove the BgReading's and then re-add them using smoothed values
            // so we'll define the timestamp as of when readings should be deleted
            // younger than 11 minutes

            // start defining timeStampToDelete as of when existing BgReading's will be deleted
            // this value is also used to verify that glucoseData Array has enough readings
            var timeStampToDelete = Date(timeIntervalSinceNow: -60.0 * (Double)(ConstantsLibreSmoothing.readingsToDeleteInMinutes))

            trace("timeStampToDelete =  %{public}@", log: log, category: ConstantsLog.categoryRootView, type: .debug, timeStampToDelete.toString(timeStyle: .long, dateStyle: .none))

            // now check if we'll delete readings
            // there must be a glucoseData.last, here assigning lastGlucoseData just to unwrap it
            // checking lastGlucoseData.timeStamp < timeStampToDelete guarantees the oldest reading is older than the one we'll delete, so we're sur we have enough readings in glucoseData to refill the BgReadings
            if let lastGlucoseData = glucoseData.last, lastGlucoseData.timeStamp < timeStampToDelete, UserDefaults.standard.smoothBgReadings {

                trace("lastGlucoseData =  %{public}@", log: log, category: ConstantsLog.categoryRootView, type: .debug, lastGlucoseData.timeStamp.toString(timeStyle: .long, dateStyle: .none))

                // older than the timestamp of the latest reading
                if let last = glucoseData.last {
                    timeStampToDelete = max(timeStampToDelete, last.timeStamp)
                }

                // older than the timestamp of the latest calibration (would only be applicable if recalibration is used)
                if let lastCalibrationForActiveSensor = lastCalibrationForActiveSensor {
                    timeStampToDelete = max(timeStampToDelete, lastCalibrationForActiveSensor.timeStamp)
                }

                // there should be one reading per minute for the period that we want to delete readings, otherwise we may not be able to fill up a gap that is created by deleting readings, because the next readings are per 15 minutes. This will typically happen the first time the app runs (or reruns), the first range of readings is only 16 readings not enough to fill up a gap of more than 20 minutes
                // we calculate the number of minutes between timeStampToDelete and now, use the result as index in glucoseData, the timestamp of that element is a number of minutes away from now, that number should be equal to index (as we expect one reading per minute)
                // if that's not the case add 1 minute to timeStampToDelete
                // repeat this until reached
                let checkTimeStampToDelete = { (glucoseData: [GlucoseData]) -> Bool in
                    // just to avoid infinite loop
                    if timeStampToDelete > Date() {
                        return true
                    }

                    let minutes = Int(abs(timeStampToDelete.timeIntervalSince(Date()) / 60.0))

                    if minutes < glucoseData.count {
                        if abs(glucoseData[minutes].timeStamp.timeIntervalSince(timeStampToDelete)) > 1.0 {
                            // increase timeStampToDelete with 5 minutes, this is in the assumption that ConstantsSmoothing.readingsToDeleteInMinutes is not more than 21, by reducing to 16 we should never have a gap because there's always minimum 16 values per minute
                            timeStampToDelete = timeStampToDelete.addingTimeInterval(1.0 * 60)

                            return false
                        }
                        return true

                    } else {
                        // should never come here
                        // increase timeStampToDelete with 5 minutes
                        timeStampToDelete = timeStampToDelete.addingTimeInterval(1.0 * 60)
                        return false
                    }
                }

                // repeat the function checkTimeStampToDelete until timeStampToDelete is high enough so that we delete only bgReading's without creating a gap that can't be filled in
                while !checkTimeStampToDelete(glucoseData) {
                }

                // get the readings to be deleted - delete also non-calibrated readings
                let lastBgReadings = bgReadingsAccessor.getLatestBgReadings(limit: nil, fromDate: timeStampToDelete, forSensor: activeSensor, ignoreRawData: false, ignoreCalculatedValue: true)

                // delete them
                for reading in lastBgReadings {
                    trace("reading being deleted with timestamp =  %{public}@", log: log, category: ConstantsLog.categoryRootView, type: .debug, reading.timeStamp.toString(timeStyle: .long, dateStyle: .none))

                    CoreDataManager.shared.mainManagedObjectContext.delete(reading)

                    CoreDataManager.shared.saveChanges()
                }

                // as we're deleting readings, glucoseChartPoints need to be updated, otherwise we keep seeing old values
                // this is the easiest way to achieve it
//                glucoseChartManager?.cleanUpMemory()
            }

            // was a new reading created or not ?
            var newReadingCreated = false

            // assign value of timeStampLastBgReading
            var timeStampLastBgReading = Date(timeIntervalSince1970: 0)
            if let lastReading = bgReadingsAccessor.last(forSensor: nil) {
                timeStampLastBgReading = lastReading.timeStamp
            }

            // iterate through array, elements are ordered by timestamp, first is the youngest, we need to start with the oldest
            for (index, glucose) in glucoseData.enumerated().reversed() {

                // we only add new glucose values if 5 minutes - 10 seconds younger than latest already existing reading, or, if it's the latest, it needs to be just younger
                let checktimestamp = Date(timeInterval: 5.0 * 60.0 - 10.0, since: timeStampLastBgReading)

                // timestamp of glucose being processed must be higher (ie more recent) than checktimestamp except if it's the last one (ie the first in the array), because there we don't care if it's less than 5 minutes different with the last but one
                if glucose.timeStamp > checktimestamp || ((index == 0) && (glucose.timeStamp > timeStampLastBgReading)) {

                    // check on glucoseLevelRaw > 0 because I've had a case where a faulty sensor was giving negative values
                    if glucose.glucoseLevelRaw > 0 {

                        // get latest 15 BgReadings to make sure there is at least 15 mins readings to calculate slope
                        var latestBgReadings = bgReadingsAccessor.getLatestBgReadings(
                                limit: Constants.minsToCalculateSlope + 5,
                                howOld: nil,
                                forSensor: activeSensor,
                                ignoreRawData: false,
                                ignoreCalculatedValue: false
                        )

                        let newReading = calibrator.createNewBgReading(
                                rawData: glucose.glucoseLevelRaw,
                                timeStamp: glucose.timeStamp,
                                sensor: activeSensor,
                                lastReadings: &latestBgReadings,
                                lastCalibrationsForActiveSensorInLastXDays: &lastCalibrationsForActiveSensorInLastXDays,
                                firstCalibration: firstCalibrationForActiveSensor,
                                lastCalibration: lastCalibrationForActiveSensor,
                                deviceName: getCGMTransmitterDeviceName(for: cgmTransmitter),
                                nsManagedObjectContext: CoreDataManager.shared.mainManagedObjectContext
                        )

                        RootViewController.log.i("new reading created, timestamp: \(newReading.timeStamp), calculatedValue: \(newReading.calculatedValue)")

                        // save the newly created bgreading permenantly in coredata
                        CoreDataManager.shared.saveChanges()

                        // check whether the reading is not bigger than max bg
                        if newReading.calculatedValue < Constants.maxBgMgDl {
                            // a new reading was created
                            newReadingCreated = true

                            // set timeStampLastBgReading to new timestamp
                            timeStampLastBgReading = glucose.timeStamp

                        } else {
                            RootViewController.log.w("BgReading is bigger than max bg, ignore it. Reading: \(newReading.calculatedValue), max: \(Constants.maxBgMgDl)")
                        }

                    } else {
                        RootViewController.log.i("reading skipped, rawValue <= 0, looks like a faulty sensor")
                    }
                }
            }

            // if a new reading is created, create either initial calibration request or bgreading notification - upload to nightscout and check alerts
            if !newReadingCreated {
                return
            }

            // only if no webOOPEnabled : if no two calibration exist yet then create calibration request notification, otherwise a bgreading notification and update labels
            if firstCalibrationForActiveSensor == nil && lastCalibrationForActiveSensor == nil && !cgmTransmitter.isWebOOPEnabled() {

                // there must be at least 2 readings
                let latestReadings = bgReadingsAccessor.getLatestBgReadings(limit: 36, howOld: nil, forSensor: activeSensor, ignoreRawData: false, ignoreCalculatedValue: true)

                if latestReadings.count > 1 {
                    trace("calibration: two readings received, no calibrations exist yet and not weboopenabled, request calibation to user", log: log, category: ConstantsLog.categoryRootView, type: .info)

                    createInitialCalibrationRequest()
                }

            } else {
                // check alerts, create notification, set app badge
                checkAlertsCreateNotificationAndSetAppBadge()

                // update all text in  first screen
                updateLabelsAndChart(overrideApplicationState: false)

                // update statistics related outlets
                updateStatistics(animatePieChart: false)

                // update sensor countdown graphic
                updateSensorCountdown()
            }

            nightScoutUploadManager?.upload(lastConnectionStatusChangeTimeStamp: lastConnectionStatusChangeTimeStamp())

            healthKitManager.storeBgReadings()

            bgReadingSpeaker.speakNewReading(lastConnectionStatusChangeTimeStamp: lastConnectionStatusChangeTimeStamp())

            dexcomShareUploadManager?.upload(lastConnectionStatusChangeTimeStamp: lastConnectionStatusChangeTimeStamp())

            WatchManager.shared.processNewReading(lastConnectionStatusChangeTimeStamp: lastConnectionStatusChangeTimeStamp())

            loopManager.share()

            showNewBGReadingToast()

            // should check how offen the Transmitter get new reading
            if let cgmTransmitter = bluetoothPeripheralManager?.getCGMTransmitter(),
               let newReadingPeriodInSeconds = cgmTransmitter.newReadingPeriodInSeconds {
                newReadingCountDownView.reset(to: newReadingPeriodInSeconds)
                newReadingCountDownView.startCountDown()

            } else {
                newReadingCountDownView.stopCountCown()
            }
        }
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
            changeButtonsStatusTo(enabled: UserDefaults.standard.isMaster)

            guard let cgmTransmitter = bluetoothPeripheralManager?.getCGMTransmitter() else {
                break
            }

            // no sensor needed in follower mode, stop it
            stopSensor(cgmTransmitter: cgmTransmitter, sendToTransmitter: false)

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

        snoozeButton.onTap { [unowned self] _ in
            guard let snoozeAlarmsViewController = R.storyboard.main.snoozeAlarms() else {
                return
            }

            present(snoozeAlarmsViewController, animated: true)
        }

        calibrateButton.onTap { [unowned self] _ in
            if let cgmTransmitter = bluetoothPeripheralManager?.getCGMTransmitter(), cgmTransmitter.isWebOOPEnabled() {
                let dialog = PopupDialog(title: R.string.common.warning(),
                        message: R.string.homeView.calibrationNotNecessary(),
                        actionHandler: nil)
                present(dialog, animated: true)

            } else {
                RootViewController.log.i("calibration : user clicked the calibrate button")
                requestCalibration(userRequested: true)
            }
        }

        sensorIndicator.addTarget(self, action: #selector(sensorIndicatorDidClick(_:)), for: .touchUpInside)

        glucoseChart.chartHours = selectedChartHours
        glucoseChart.isLongPressSupported = true
        glucoseChart.delegate = self
    }

    @objc private func sensorIndicatorDidClick(_ sender: SensorIndicator) {
        showBluetoothPeripheral()
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

    /// opens an alert, that requests user to enter a calibration value, and calibrates
    /// - parameters:
    ///     - userRequested : if true, it's a requestCalibration initiated by user clicking on the calibrate button in the homescreen
    private func requestCalibration(userRequested: Bool) {

        // check that there's an active cgmTransmitter (not necessarily connected, just one that is created and configured with shouldconnect = true)
        guard let cgmTransmitter = bluetoothPeripheralManager?.getCGMTransmitter(), let bluetoothTransmitter = cgmTransmitter as? BluetoothTransmitter else {

            trace("in requestCalibration, calibrationsAccessor or cgmTransmitter is nil, no further processing", log: log, category: ConstantsLog.categoryRootView, type: .info)

            present(PopupDialog(title: Texts_HomeView.info,
                    message: Texts_HomeView.theresNoCGMTransmitterActive,
                    actionTitle: R.string.common.common_Ok(),
                    actionHandler: nil),
                    animated: true)

            return
        }

        // check if sensor active and if not don't continue
        guard let activeSensor = activeSensor else {

            trace("in requestCalibration, there is no active sensor, no further processing", log: log, category: ConstantsLog.categoryRootView, type: .info)

            present(PopupDialog(title: R.string.common.wait_a_moment(),
                    message: R.string.homeView.startSensorBeforeCalibration(),
                    actionTitle: R.string.common.common_Ok(),
                    actionHandler: nil),
                    animated: true)

            return
        }

        // if it's a user requested calibration, but there's no calibration yet, then give info and return - first calibration will be requested by app via notification
        if calibrationsAccessor.firstCalibrationForActiveSensor(withActiveSensor: activeSensor) == nil && userRequested {

            present(PopupDialog(title: Texts_HomeView.info,
                    message: Texts_HomeView.thereMustBeAreadingBeforeCalibration,
                    actionTitle: R.string.common.common_Ok(),
                    actionHandler: nil),
                    animated: true)

            return
        }

        // assign deviceName, needed in the closure when creating alert. As closures can create strong references (to bluetoothTransmitter in this case), I'm fetching the deviceName here
        let deviceName = bluetoothTransmitter.deviceName

        let dialog = PopupDialog(
                title: Texts_Calibrations.enterCalibrationValue,
                message: nil,
                keyboardType: UserDefaults.standard.bloodGlucoseUnitIsMgDl ? .numberPad : .decimalPad,
                text: nil,
                placeHolder: "..."
        ) {
            _, text in

            guard let valueAsDouble = text.toDouble() else {
                self.present(PopupDialog(title: Texts_Common.warning,
                        message: Texts_Common.invalidValue,
                        actionTitle: R.string.common.common_Ok(),
                        actionHandler: nil),
                        animated: true)
                return
            }

            // store the calibration value entered by the user into the log
            RootViewController.log.d("calibration: value \"\(text.description)\" entered by user")

            let valueAsDoubleConvertedToMgDl = valueAsDouble.mmolToMgdl(mgdl: UserDefaults.standard.bloodGlucoseUnitIsMgDl)

            var latestReadings = self.bgReadingsAccessor.getLatestBgReadings(limit: 36, howOld: nil, forSensor: activeSensor, ignoreRawData: false, ignoreCalculatedValue: true)

            var latestCalibrations = self.calibrationsAccessor.getLatestCalibrations(howManyDays: 4, forSensor: activeSensor)

            if let calibrator = self.calibrator {
                if latestCalibrations.count == 0 {
                    RootViewController.log.i("calibration: initial calibration, creating two calibrations")

                    // calling initialCalibration will create two calibrations, they are returned also but we don't need them
                    let (calibration, _) = calibrator.initialCalibration(firstCalibrationBgValue: valueAsDoubleConvertedToMgDl, firstCalibrationTimeStamp: Date(timeInterval: -(5 * 60), since: Date()), secondCalibrationBgValue: valueAsDoubleConvertedToMgDl, sensor: activeSensor, lastBgReadingsWithCalculatedValue0AndForSensor: &latestReadings, deviceName: deviceName, nsManagedObjectContext: CoreDataManager.shared.mainManagedObjectContext)

                    // send calibration to transmitter (only used for Dexcom, if firefly flow is used)
                    if let calibration = calibration {
                        cgmTransmitter.calibrate(calibration: calibration)

                        // presnooze fastrise and fastdrop alert
                        AlertManager.shared.snooze(alertKind: .fastdrop, snoozePeriodInMinutes: 9, response: nil)
                        AlertManager.shared.snooze(alertKind: .fastrise, snoozePeriodInMinutes: 9, response: nil)
                    }

                } else {
                    // it's not the first calibration
                    if let firstCalibrationForActiveSensor = self.calibrationsAccessor.firstCalibrationForActiveSensor(withActiveSensor: activeSensor) {
                        RootViewController.log.i("calibration: creating calibrations")

                        // create new calibration
                        let calibration = calibrator.createNewCalibration(bgValue: valueAsDoubleConvertedToMgDl, lastBgReading: latestReadings[0], sensor: activeSensor, lastCalibrationsForActiveSensorInLastXDays: &latestCalibrations, firstCalibration: firstCalibrationForActiveSensor, deviceName: deviceName, nsManagedObjectContext: CoreDataManager.shared.mainManagedObjectContext)

                        // send calibration to transmitter (only used for Dexcom, if firefly flow is used)
                        cgmTransmitter.calibrate(calibration: calibration)

                        // presnooze fastrise and fastdrop alert
                        AlertManager.shared.snooze(alertKind: .fastdrop, snoozePeriodInMinutes: 9, response: nil)
                        AlertManager.shared.snooze(alertKind: .fastrise, snoozePeriodInMinutes: 9, response: nil)
                    }
                }

                // this will store the newly created calibration(s) in coredata
                CoreDataManager.shared.saveChanges()

                // initiate upload to NightScout, if needed
                if let nightScoutUploadManager = self.nightScoutUploadManager {
                    nightScoutUploadManager.upload(lastConnectionStatusChangeTimeStamp: self.lastConnectionStatusChangeTimeStamp())
                }

                // initiate upload to Dexcom Share, if needed
                if let dexcomShareUploadManager = self.dexcomShareUploadManager {
                    dexcomShareUploadManager.upload(lastConnectionStatusChangeTimeStamp: self.lastConnectionStatusChangeTimeStamp())
                }

                // update labels
                self.updateLabelsAndChart(overrideApplicationState: false)

                // watchManager should process new reading
                WatchManager.shared.processNewReading(lastConnectionStatusChangeTimeStamp: self.lastConnectionStatusChangeTimeStamp())

                // send also to loopmanager, not interesting for loop probably, but the data is also used for today widget
                self.loopManager.share()
            }
        }

        present(dialog, animated: true)
    }

    /// this is just some functionality which is used frequently
    private func getCalibrator(cgmTransmitter: CGMTransmitter) -> Calibrator {
        let cgmTransmitterType = cgmTransmitter.cgmTransmitterType()

        // initialize return value
        var calibrator: Calibrator = NoCalibrator()

        switch cgmTransmitterType {
        case .dexcom:
            if cgmTransmitter.isWebOOPEnabled() {
                // received values are already calibrated
                calibrator = NoCalibrator()

            } else if cgmTransmitter.isNonFixedSlopeEnabled() {
                // no oop web, fixed slope
                // should not occur, because Dexcom should have nonFixedSlopeEnabled false
                //  if true for dexcom, then someone has set this to true but didn't create a non-fixed slope calibrator
                fatalError("cgmTransmitter.isNonFixedSlopeEnabled returns true for dexcom but there's no NonFixedSlopeCalibrator for Dexcom")

            } else {
                // no oop web, no fixed slope
                calibrator = DexcomCalibrator()
            }

        case .miaomiao, .GNSentry, .Blucon, .Bubble, .Droplet1, .blueReader, .watlaa, .Libre2, .Atom:
            if cgmTransmitter.isWebOOPEnabled() {
                // received values are already calibrated
                calibrator = NoCalibrator()

            } else if cgmTransmitter.isNonFixedSlopeEnabled() {
                // no oop web, non-fixed slope
                return Libre1NonFixedSlopeCalibrator()

            } else {
                // no oop web, fixed slope
                calibrator = Libre1Calibrator()
            }
        }

        RootViewController.log.d("calibrator: \(calibrator.description())")

        return calibrator
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

    /// creates initial calibration request notification
    private func createInitialCalibrationRequest() {

        // first remove existing notification if any
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [ConstantsNotifications.NotificationIdentifiersForCalibration.initialCalibrationRequest])

        createNotification(title: Texts_Calibrations.calibrationNotificationRequestTitle, body: Texts_Calibrations.calibrationNotificationRequestBody, identifier: ConstantsNotifications.NotificationIdentifiersForCalibration.initialCalibrationRequest, sound: UNNotificationSound(named: UNNotificationSoundName("")))

        // we will not just count on it that the user will click the notification to open the app (assuming the app is in the background, if the app is in the foreground, then we come in another flow)
        // whenever app comes from-back to foreground, requestCalibration needs to be called
        ApplicationManager.shared.addClosureToRunWhenAppWillEnterForeground(key: appManagerKeyInitialCalibration) {

            // first of all reremove from application key manager
            ApplicationManager.shared.removeClosureToRunWhenAppWillEnterForeground(key: self.appManagerKeyInitialCalibration)

            // remove existing notification if any
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [ConstantsNotifications.NotificationIdentifiersForCalibration.initialCalibrationRequest])

            // request the calibration
            self.requestCalibration(userRequested: false)
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
        if UserDefaults.standard.showReadingInNotification && !overrideShowReadingInNotification && (abs(timeStampLastBGNotification.timeIntervalSince(Date())) > Double(UserDefaults.standard.notificationInterval) * 60.0 || lastConnectionStatusChangeTimeStamp().timeIntervalSince(timeStampLastBGNotification) > 0) {

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

    private func showBluetoothPeripheral() {
        guard let bluetoothPeripheralManager = bluetoothPeripheralManager,
              let bluetoothPeripheralViewController = R.storyboard.main.bluetoothPeripheral()
                else {
            return
        }

        if let bluetoothPeripheral = bluetoothPeripheralManager.bluetoothPeripheral {
            // show current peripheral
            bluetoothPeripheralViewController.configure(
                    bluetoothPeripheral: bluetoothPeripheral,
                    bluetoothPeripheralManager: bluetoothPeripheralManager,
                    expectedBluetoothPeripheralType: bluetoothPeripheral.bluetoothPeripheralType()
            )
            navigationController?.pushViewController(bluetoothPeripheralViewController, animated: true)

        } else {
            // the category has only CGM currently
            // to add a peripheral

            let data = BluetoothPeripheralCategory.listOfBluetoothPeripheralTypes(
                    withCategory: .CGM,
                    isFullFeatureMode: UserDefaults.standard.isFullFeatureMode
            )

            let pickerViewData = PickerViewDataBuilder(
                    data: data,
                    actionHandler: {
                        (_ typeIndex: Int, _) in

                        let typeRawValue = BluetoothPeripheralCategory.listOfBluetoothPeripheralTypes(
                                withCategory: .CGM,
                                isFullFeatureMode: UserDefaults.standard.isFullFeatureMode
                        )[typeIndex]

                        // get the selected BluetoothPeripheralType
                        if let type = BluetoothPeripheralType(rawValue: typeRawValue) {
                            bluetoothPeripheralViewController.configure(bluetoothPeripheral: nil,
                                    bluetoothPeripheralManager: bluetoothPeripheralManager,
                                    expectedBluetoothPeripheralType: type)
                            self.navigationController?.pushViewController(bluetoothPeripheralViewController, animated: true)
                        }
                    })
                    .title(Texts_BluetoothPeripheralsView.selectType)
                    .build()

            _ = BottomSheetPickerViewController.show(in: self, pickerViewData: pickerViewData)
        }
    }

    /// - creates a new sensor and assigns it to activeSensor
    /// - if sendToTransmitter is true then sends startSensor command to transmitter (ony useful for Firefly)
    /// - saves to coredata
    private func startSensor(cgmTransmitter: CGMTransmitter, sensorStartDate: Date, sensorCode: String?, sendToTransmitter: Bool) {
        RootViewController.log.d("==> startSensor")

        EasyTracker.logEvent(Events.prefixStartSensor + cgmTransmitter.cgmTransmitterType().rawValue)

        // create active sensor
        let newSensor = Sensor(startDate: sensorStartDate,
                nsManagedObjectContext: CoreDataManager.shared.mainManagedObjectContext)

        // save the newly created Sensor permanently in coredata
        CoreDataManager.shared.saveChanges()

        // send to transmitter
        if sendToTransmitter {
            cgmTransmitter.startSensor(sensorCode: sensorCode, startDate: sensorStartDate)
        }

        // assign activeSensor to newSensor
        activeSensor = newSensor
    }

    private func stopSensor(cgmTransmitter: CGMTransmitter, sendToTransmitter: Bool) {
        RootViewController.log.d("==> stopSensor")

        EasyTracker.logEvent(Events.prefixStopSensor + cgmTransmitter.cgmTransmitterType().rawValue)

        // create stopDate
        let stopDate = Date()

        // send stop sensor command to transmitter, don't check if there's an activeSensor in coredata or not, never know that there's a desync between coredata and transmitter
        if sendToTransmitter {
            cgmTransmitter.stopSensor(stopDate: stopDate)
        }

        // no need to further continue if activeSensor = nil, and at the same time, unwrap coredataManager
        guard let activeSensor = activeSensor else {
            return
        }

        // set endDate of activeSensor to stopDate
        activeSensor.endDate = stopDate

        // save changes to coreData
        CoreDataManager.shared.saveChanges()

        // assign nil to activeSensor
        self.activeSensor = nil

        // now that the activeSensor object has been destroyed, update (hide) the sensor countdown graphic
        updateSensorCountdown()
    }

    private func getCGMTransmitterDeviceName(for cgmTransmitter: CGMTransmitter) -> String? {
        if let bluetoothTransmitter = cgmTransmitter as? BluetoothTransmitter {
            return bluetoothTransmitter.deviceName
        }
        return nil
    }

    /// enables or disables the buttons on top of the screen
    private func changeButtonsStatusTo(enabled: Bool) {
        if enabled {
            sensorIndicator.isHidden = false
            calibrateButton.isHidden = false

        } else {
            sensorIndicator.isHidden = true
            calibrateButton.isHidden = true
        }
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

    // a long function just to get the timestamp of the last disconnect or reconnect. If not known then returns 1 1 1970
    private func lastConnectionStatusChangeTimeStamp() -> Date {

        // this is actually unwrapping of optionals, goal is to get date of last disconnect/reconnect - all optionals should exist so it doesn't matter what is returned true or false
        guard let cgmTransmitter = bluetoothPeripheralManager?.getCGMTransmitter(),
              let bluetoothTransmitter = cgmTransmitter as? BluetoothTransmitter,
              let bluetoothPeripheral = bluetoothPeripheralManager?.getBluetoothPeripheral(for: bluetoothTransmitter),
              let lastConnectionStatusChangeTimeStamp = bluetoothPeripheral.blePeripheral.lastConnectionStatusChangeTimeStamp else {
            return Date(timeIntervalSince1970: 0)
        }

        return lastConnectionStatusChangeTimeStamp
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

    /// this function will check if the user is using a time-sensitive sensor (such as a 14 day Libre, calculate the days remaining and then update the imageUI with the relevant svg image from the project assets.
    private func updateSensorCountdown() {
        // if there's no active sensor, there's nothing to do or show
        guard let activeSensor = activeSensor else {
            RootViewController.log.i("ActiveSensor is nil, do not show SensorCountdown")
            sensorCountdown.isHidden = true
            return
        }

        // check if there is a transmitter connected (needed as Dexcom will only connect briefly every 5 minutes)
        // if there is a transmitter connected, pull the current maxSensorAgeInSeconds and store in in UserDefaults
        if let cgmTransmitter = bluetoothPeripheralManager?.getCGMTransmitter(), let maxSeconds = cgmTransmitter.maxSensorAgeInSeconds() {
            RootViewController.log.i("Get maxSensorAge, \(Double(maxSeconds)/Date.dayInSeconds) days")
            UserDefaults.standard.maxSensorAgeInSeconds = maxSeconds
        }

        // check if the sensor type has a hard coded maximum sensor life previously stored.
        if let maxSensorAgeInSeconds = UserDefaults.standard.maxSensorAgeInSeconds as Int?, maxSensorAgeInSeconds > 0 {
            sensorCountdown.show(maxSensorAgeInSeconds: Double(maxSensorAgeInSeconds), sensorStartDate: activeSensor.startDate)
            sensorCountdown.isHidden = false

        } else {
            RootViewController.log.d("No maxSensorAge, do not show SensorCountdown")
            // this must be a sensor without a maxSensorAge , so just make sure to hide the sensor countdown image and do nothing
            sensorCountdown.isHidden = true
        }
    }
}


// MARK: - conform to CGMTransmitter protocol

/// conform to CGMTransmitterDelegate
extension RootViewController: CGMTransmitterDelegate {

    func sensorStopDetected() {
        RootViewController.log.d("==> sensorStopDetected")

        // unwrap cgmTransmitter
        guard let cgmTransmitter = bluetoothPeripheralManager?.getCGMTransmitter() else {
            return
        }

        stopSensor(cgmTransmitter: cgmTransmitter, sendToTransmitter: false)
    }

    func newSensorDetected(sensorStartDate: Date?) {
        RootViewController.log.d("==> newSensorDetected")

        // unwrap cgmTransmitter
        guard let cgmTransmitter = bluetoothPeripheralManager?.getCGMTransmitter() else {
            return
        }

        stopSensor(cgmTransmitter: cgmTransmitter, sendToTransmitter: false)

        // if sensorStartDate is given, then startSensor
        if let sensorStartDate = sensorStartDate {

            // use sensorCode nil, in the end there will be no start sensor command sent to the transmitter because we just received the sensorStartTime from the transmitter, so it's already started
            startSensor(cgmTransmitter: cgmTransmitter,
                    sensorStartDate: sensorStartDate,
                    sensorCode: nil,
                    sendToTransmitter: false)
        }

        EasyTracker.logEvent(Events.prefixNewSensor + cgmTransmitter.cgmTransmitterType().rawValue)
    }

    func sensorNotDetected() {
        RootViewController.log.d("==> sensorNotDetected")

        createNotification(title: Texts_Common.warning,
                body: Texts_HomeView.sensorNotDetected,
                identifier: ConstantsNotifications.NotificationIdentifierForSensorNotDetected.sensorNotDetected,
                sound: nil)
    }

    func cgmTransmitterInfoReceived(glucoseData: inout [GlucoseData], transmitterBatteryInfo: TransmitterBatteryInfo?, sensorAge: TimeInterval?) {
        RootViewController.log.d("transmitterBatteryInfo: \(transmitterBatteryInfo?.description ?? "not received")")
        RootViewController.log.d("sensorAge: \(sensorAge?.description ?? "not received")")
        RootViewController.log.d("glucoseData size: \(glucoseData.count.description)")

        // if received transmitterBatteryInfo not nil, then store it
        if let transmitterBatteryInfo = transmitterBatteryInfo {
            UserDefaults.standard.transmitterBatteryInfo = transmitterBatteryInfo
        }

//        // list readings
//        for (index, glucose) in glucoseData.enumerated() {
//            RootViewController.log.i("glucoseData[\(index)], value: \(glucose.glucoseLevelRaw), timestamp: \(glucose.timeStamp.toString(timeStyle: .long, dateStyle: .none))")
//        }

        // process new readings
        processNewGlucoseData(glucoseData: &glucoseData, sensorAge: sensorAge)
    }

    func cgmTransmitterInfoDidChange() {
        RootViewController.log.d("==> cgmTransmitterInfoDidChange")

        // if cgmTransmitter not nil then reassign calibrator and set UserDefaults.standard.transmitterTypeAsString
        if let cgmTransmitter = bluetoothPeripheralManager?.getCGMTransmitter() {

            // reassign calibrator, even if the type of calibrator would not change
            calibrator = getCalibrator(cgmTransmitter: cgmTransmitter)

            // check if webOOPEnabled changed and if yes stop the sensor
            if let webOOPEnabled = webOOPEnabled, webOOPEnabled != cgmTransmitter.isWebOOPEnabled() {

                trace("in cgmTransmitterInfoChanged, webOOPEnabled value changed to %{public}@, will stop the sensor", log: log, category: ConstantsLog.categoryRootView, type: .info, cgmTransmitter.isWebOOPEnabled().description)

                stopSensor(cgmTransmitter: cgmTransmitter, sendToTransmitter: false)
            }

            // check if nonFixedSlopeEnabled changed and if yes stop the sensor
            if let nonFixedSlopeEnabled = nonFixedSlopeEnabled, nonFixedSlopeEnabled != cgmTransmitter.isNonFixedSlopeEnabled() {

                trace("in cgmTransmitterInfoChanged, nonFixedSlopeEnabled value changed to %{public}@, will stop the sensor", log: log, category: ConstantsLog.categoryRootView, type: .info, cgmTransmitter.isNonFixedSlopeEnabled().description)

                stopSensor(cgmTransmitter: cgmTransmitter, sendToTransmitter: false)
            }

            // check if the type of sensor supported by the cgmTransmitterType  has changed, if yes stop the sensor
            if let currentTransmitterType = UserDefaults.standard.cgmTransmitterType, currentTransmitterType.sensorType() != cgmTransmitter.cgmTransmitterType().sensorType() {

                trace("in cgmTransmitterInfoChanged, sensorType value changed to %{public}@, will stop the sensor", log: log, category: ConstantsLog.categoryRootView, type: .info, cgmTransmitter.cgmTransmitterType().sensorType().rawValue)

                stopSensor(cgmTransmitter: cgmTransmitter, sendToTransmitter: false)
            }

            // assign the new value of webOOPEnabled
            webOOPEnabled = cgmTransmitter.isWebOOPEnabled()

            // assign the new value of nonFixedSlopeEnabled
            nonFixedSlopeEnabled = cgmTransmitter.isNonFixedSlopeEnabled()

            // change value of UserDefaults.standard.transmitterTypeAsString
            UserDefaults.standard.cgmTransmitterTypeAsString = cgmTransmitter.cgmTransmitterType().rawValue

            // for testing only - for testing make sure there's a transmitter connected,
            // eg a bubble or mm, not necessarily (better not) installed on a sensor
            // CGMMiaoMiaoTransmitter.testRange(cGMTransmitterDelegate: self)
        }
    }

    func errorOccurred(xDripError: XdripError) {
        if xDripError.priority == .HIGH {
            createNotification(title: Texts_Common.warning, body: xDripError.errorDescription, identifier: ConstantsNotifications.notificationIdentifierForxCGMTransmitterDelegatexDripError, sound: nil)
        }
    }

    func cgmTransmitterPairingTooLate() {
        let alert = PopupDialog(title: Texts_Common.warning,
                message: Texts_HomeView.transmitterPairingTooLate,
                actionTitle: R.string.common.common_Ok(),
                actionHandler: nil)

        present(alert, animated: true, completion: nil)
    }

    func cgmTransmitterPairingDidSucceed() {
        let alert = PopupDialog(title: Texts_HomeView.info,
                message: Texts_HomeView.transmitterPairingSuccessful,
                actionTitle: R.string.common.common_Ok(),
                actionHandler: nil)

        present(alert, animated: true, completion: nil)
    }

    func cgmTransmitterPairingDidTimeOut() {
        let alert = PopupDialog(title: Texts_Common.warning,
                message: "time out",
                actionTitle: R.string.common.common_Ok(),
                actionHandler: nil)

        present(alert, animated: true, completion: nil)
    }
}

// MARK: - conform to UNUserNotificationCenterDelegate protocol

/// conform to UNUserNotificationCenterDelegate, for notifications
extension RootViewController: UNUserNotificationCenterDelegate {

    // called when notification created while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        if notification.request.identifier == ConstantsNotifications.NotificationIdentifiersForCalibration.initialCalibrationRequest {

            // request calibration
            requestCalibration(userRequested: false)

            /// remove applicationManagerKeyInitialCalibration from application key manager - there's no need to initiate the calibration via this closure
            ApplicationManager.shared.removeClosureToRunWhenAppWillEnterForeground(key: appManagerKeyInitialCalibration)

            // call completionhandler to avoid that notification is shown to the user
            completionHandler([])

        } else if notification.request.identifier == ConstantsNotifications.NotificationIdentifierForSensorNotDetected.sensorNotDetected {

            // call completionhandler to show the notification even though the app is in the foreground, without sound
            completionHandler([.alert])

        } else if notification.request.identifier == ConstantsNotifications.NotificationIdentifierForTransmitterNeedsPairing.transmitterNeedsPairing {

            // so actually the app was in the foreground, at the  moment the Transmitter Class called the cgmTransmitterNeedsPairing function, there's no need to show the notification, we can immediately call back the cgmTransmitter initiatePairing function
            completionHandler([])
            bluetoothPeripheralManager?.initiatePairing()

            // this will verify if it concerns an alert notification, if not pickerviewData will be nil
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

        // update sensor countdown
        updateSensorCountdown()

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
