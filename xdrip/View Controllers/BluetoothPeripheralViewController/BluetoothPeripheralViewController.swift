import UIKit
import CoreBluetooth
import os
import PopupDialog

fileprivate let generalSettingSectionNumber = 0

/// - a case per attribute that can be set in BluetoothPeripheralViewController
/// - these are applicable to all types of bluetoothperipheral types (M5Stack ...)
fileprivate enum Setting: Int, CaseIterable {

    /// the name received from bluetoothTransmitter, ie the name hardcoded in the BluetoothPeripheral
    case name = 0

    /// timestamp when connection changed to connected or not connected
    case connectOrDisconnectTimeStamp = 1

    /// transmitterID, only for devices that need it
    case transmitterId = 2

    case webOOPEnabled = 3

    case nonFixedSlopeEnabled = 4

    /// the current connection status
    case connectionStatus = 5
}

/// base class for UIViewController's that allow to edit specific type of bluetooth transmitters to show 
class BluetoothPeripheralViewController: UIViewController {

    // MARK: - IBOutlet's and IBAction's

    /// action for connectButton, will also be used to disconnect, depending on the connection status
    @IBAction func connectButtonAction(_ sender: UIButton) {
        connectButtonHandler()
    }

    /// action for trashButton, to delete the BluetoothPeripheral
    @IBAction func trashButtonAction(_ sender: UIBarButtonItem) {
        trashButtonClicked()
    }

    /// outlet for connectButton, to set the text in the connectButton
    @IBOutlet weak var connectButtonOutlet: UIButton!

    /// outlet for trashButton, to enable or disable
    @IBOutlet weak var trashButtonOutlet: UIBarButtonItem!

    /// outlet for bluetoothPeripheralImageView, to show the image of the peripheral
    @IBOutlet weak var bluetoothPeripheralImageView: BluetoothPeripheralImageView!

    /// outlet for tableView
    @IBOutlet weak var tableView: UITableView!

    // MARK: - private properties

    /// the BluetoothPeripheral being edited
    private var bluetoothPeripheral: BluetoothPeripheral?

    /// a BluetoothPeripheralManager
    private weak var bluetoothPeripheralManager: BluetoothPeripheralManaging?

    /// needed to support the bluetooth peripheral type specific attributes
    private var bluetoothPeripheralViewModel: BluetoothPeripheralViewModel?

    /// BluetoothPeripheralType for which this viewController is created
    private var expectedBluetoothPeripheralType: BluetoothPeripheralType?

    /// temp storage of transmitterId value while user is creating the transmitter
    ///
    /// this value can only be set once by the user, ie it can change from nil to a value. As soon as a value is set by the user, and if transmitterStartsScanningAfterInit returns true, then a transmitter will be created and scanning will start. If transmitterStartsScanningAfterInit returns false, then the user needs to start the scanning (there are no transmitters for the moment that use transmitter id and that do have transmitterStartsScanningAfterInit = false)
    private var transmitterIdTempValue: String?

    /// if user clicks start scanning, then this variable will be set to true. Used to verify if scanning is ongoing or not,
    private var isScanning: Bool = false

    /// if true, webOOPSettingIsShown and nonFixedSettingIsShown was already calculated once.
    /// - this is to avoid that it jumps from true to false or vice versa when the user clicks disconnect or stops scanning, which deletes the transmitter, and then calculation of nonFixedSettingIsShown and webOOPSettingIsShown gets different values
    private var webOOpAndNonFixedSlopeSettingsAreShownIsKnown = false

    /// is the nonFixedSettingsSection currently shown or not
    private var nonFixedSettingIsShown = false

    /// is the webOOPSettingIsShown currently shown or not
    private var webOOPSettingIsShown = false

    /// when user starts scanning, info will be shown in UIAlertController. This will be
    private var infoAlertWhenScanningStarts: UIViewController?

    private static let log = Log(type: BluetoothPeripheralViewController.self)

    /// to keep track of scanning result
    private var previousScanningResult: BluetoothTransmitter.startScanningResult?

    // MARK:- public functions

    /// configure the viewController
    func configure(bluetoothPeripheral: BluetoothPeripheral?,
                   bluetoothPeripheralManager: BluetoothPeripheralManaging,
                   expectedBluetoothPeripheralType type: BluetoothPeripheralType) {
        self.bluetoothPeripheral = bluetoothPeripheral
        self.bluetoothPeripheralManager = bluetoothPeripheralManager
        expectedBluetoothPeripheralType = type
        transmitterIdTempValue = bluetoothPeripheral?.blePeripheral.transmitterId
    }

    /// - sets text in connect button (only applicable to BluetoothPeripheralViewController) and gets status text
    /// - used in BluetoothPeripheralsViewController and BluetoothPeripheralViewController. BluetoothPeripheralsViewController doen't have a connect button, so that outlet is optional
    static func setConnectButtonLabelTextAndGetStatusDetailedText(bluetoothPeripheral: BluetoothPeripheral?,
                                                                  isScanning: Bool,
                                                                  connectButtonOutlet: UIButton?,
                                                                  expectedBluetoothPeripheralType: BluetoothPeripheralType?,
                                                                  transmitterId: String?,
                                                                  bluetoothPeripheralManager: BluetoothPeripheralManager) -> String {

        // by default connectbutton is enabled
        connectButtonOutlet?.enable()

        // explanation see below in this file

        // if BluetoothPeripheral not nil
        if let bluetoothPeripheral = bluetoothPeripheral {
            // if connected then status = connected, button text = disconnect
            if bluetoothPeripheralIsConnected(bluetoothPeripheral: bluetoothPeripheral, bluetoothPeripheralManager: bluetoothPeripheralManager) {

                connectButtonOutlet?.setTitle(Texts_BluetoothPeripheralView.disconnect, for: .normal)
                connectButtonOutlet?.isHidden = true

                return Texts_BluetoothPeripheralView.connected
            }

            // if not connected, but shouldconnect = true, means the app is trying to connect
            // by clicking the button, app will stop trying to connect
            if bluetoothPeripheral.blePeripheral.shouldconnect {
                connectButtonOutlet?.setTitle(Texts_BluetoothPeripheralView.donotconnect, for: .normal)
                connectButtonOutlet?.isHidden = false

                return Texts_BluetoothPeripheralView.tryingToConnect
            }

            // not connected, shouldconnect = false
            connectButtonOutlet?.setTitle(Texts_BluetoothPeripheralView.connect, for: .normal)
            connectButtonOutlet?.isHidden = false

            return Texts_BluetoothPeripheralView.notTryingToConnect

        } else {
            // BluetoothPeripheral is nil

            // if needs transmitterId, but no transmitterId is given by user, then button allows to set transmitter id, row text = "needs transmitter id"
            if let expectedBluetoothPeripheralType = expectedBluetoothPeripheralType, expectedBluetoothPeripheralType.needsTransmitterId(), transmitterId == nil {

                connectButtonOutlet?.setTitle(Texts_SettingsView.labelTransmitterIdTextForButton, for: .normal)
                connectButtonOutlet?.isHidden = false

                return Texts_BluetoothPeripheralView.needsTransmitterId
            }

            // if transmitter id not needed or transmitter id needed and already given, but not yet scanning
            if let expectedBluetoothPeripheralType = expectedBluetoothPeripheralType {

                if (!expectedBluetoothPeripheralType.needsTransmitterId() || (expectedBluetoothPeripheralType.needsTransmitterId() && transmitterId != nil)) && !isScanning {

                    connectButtonOutlet?.setTitle(Texts_BluetoothPeripheralView.scan, for: .normal)
                    connectButtonOutlet?.isHidden = false

                    return Texts_BluetoothPeripheralView.readyToScan
                }
            }

            // getting here, means it should be scanning
            if isScanning {
                // disable, while scanning there's no need to click that button
                connectButtonOutlet?.disable()
                connectButtonOutlet?.setTitle(Texts_BluetoothPeripheralView.scanning, for: .normal)
                connectButtonOutlet?.isHidden = true

                return Texts_BluetoothPeripheralView.scanning
            }

            // we're here, looks like an error, let's write that in the status field
            connectButtonOutlet?.setTitle("error", for: .normal)
            connectButtonOutlet?.isHidden = false

            return "error"
        }
    }

    /// sets shouldconnect for bluetoothPeripheral to false, and disconnect
    func setShouldConnectToFalse(for bluetoothPeripheral: BluetoothPeripheral) {

        guard let bluetoothPeripheralManager = bluetoothPeripheralManager else {
            return
        }

        let dialog = PopupDialog(
                title: R.string.common.pleaseConfirm(),
                message: R.string.bluetoothPeripheralView.confirmDisconnectMessage(),
                actionTitle: R.string.bluetoothPeripheralView.disconnect(),
                actionHandler: {
                    // device should not automaticaly connect in future, which means, each time the app restarts, it will not try to connect to this bluetoothPeripheral
                    bluetoothPeripheral.blePeripheral.shouldconnect = false

                    // save in coredata
                    CoreDataManager.shared.saveChanges()

                    // connect button label text needs to change because shouldconnect value has changed
                    _ = BluetoothPeripheralViewController.setConnectButtonLabelTextAndGetStatusDetailedText(bluetoothPeripheral: bluetoothPeripheral, isScanning: self.isScanning, connectButtonOutlet: self.connectButtonOutlet, expectedBluetoothPeripheralType: self.expectedBluetoothPeripheralType, transmitterId: self.transmitterIdTempValue, bluetoothPeripheralManager: bluetoothPeripheralManager as! BluetoothPeripheralManager)

                    // this will set bluetoothTransmitter to nil which will result in disconnecting also
                    bluetoothPeripheralManager.setBluetoothTransmitterToNil(forBluetoothPeripheral: bluetoothPeripheral)

                    // as transmitter is now set to nil, call again configure. Maybe not necessary, but it can't hurt
                    self.bluetoothPeripheralViewModel?.configure(bluetoothPeripheral: bluetoothPeripheral, bluetoothPeripheralManager: bluetoothPeripheralManager, tableView: self.tableView, bluetoothPeripheralViewController: self)

                    // delegate doesn't work here anymore, because the delegate is set to zero, so reset the row with the connection status by calling reloadRows
                    self.tableView.reloadRows(at: [IndexPath(row: Setting.connectionStatus.rawValue, section: 0)], with: .none)
                },
                cancelTitle: R.string.common.common_cancel()
        )

        present(dialog, animated: true)
    }

    func numberOfGeneralSections() -> Int {
        1
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let bluetoothPeripheralManager = bluetoothPeripheralManager else {
            fatalError("in BluetoothPeripheralViewController viewDidLoad, bluetoothPeripheralManager is nil")
        }

        // here the tableView is not nil, we can safely call bluetoothPeripheralViewModel.configure, this one requires a non-nil tableView

        // get a viewModel instance for the expectedBluetoothPeripheralType
        bluetoothPeripheralViewModel = expectedBluetoothPeripheralType?.viewModel()

        // configure the bluetoothPeripheralViewModel
        bluetoothPeripheralViewModel?.configure(bluetoothPeripheral: bluetoothPeripheral, bluetoothPeripheralManager: bluetoothPeripheralManager, tableView: tableView, bluetoothPeripheralViewController: self)

        // assign the self delegate in the transmitter object
        if let bluetoothPeripheral = bluetoothPeripheral, let bluetoothTransmitter = bluetoothPeripheralManager.getBluetoothTransmitter(for: bluetoothPeripheral, createANewOneIfNecessary: false) {
            bluetoothTransmitter.bluetoothTransmitterDelegate = self
        }

        navigationController?.navigationBar.tintColor = .white

        setupView()
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)

        // willMove is called when BluetoothPeripheralViewController is added and when BluetoothPeripheralViewController is removed.
        // It has no added value in the adding phase
        // It doe shave an added value when being removed. bluetoothPeripheralViewModel must be assigned to nil. bluetoothPeripheralViewModel deinit will be called which should reassign the delegate to BluetoothPeripheralManager. Also here the bluetoothtransmitter delegate will be reassigned to BluetoothPeripheralManager
        // and finally stopScanningForNewDevice will be called, for the case where scanning would still be ongoing

        // save any changes that are made
        CoreDataManager.shared.saveChanges()

        // set bluetoothPeripheralViewModel to nil. The bluetoothPeripheralViewModel's deinit will be called, which will set the delegate in the model to BluetoothPeripheralManager

        bluetoothPeripheralViewModel = nil

        // reassign delegate in BluetoothTransmitter to bluetoothPeripheralManager
        reassignBluetoothTransmitterDelegateToBluetoothPeripheralManager()

        // just in case scanning for a new device is still ongoing, call stopscanning
        bluetoothPeripheralManager?.stopScanningForNewDevice()
    }

    // MARK: - View Methods

    private func setupView() {
        // set label of connect button, according to current status
        _ = BluetoothPeripheralViewController.setConnectButtonLabelTextAndGetStatusDetailedText(bluetoothPeripheral: bluetoothPeripheral,
                isScanning: isScanning,
                connectButtonOutlet: connectButtonOutlet,
                expectedBluetoothPeripheralType: expectedBluetoothPeripheralType,
                transmitterId: transmitterIdTempValue,
                bluetoothPeripheralManager: bluetoothPeripheralManager as! BluetoothPeripheralManager)

        if bluetoothPeripheral == nil {
            // should be disabled, as there's nothing to delete yet
            trashButtonOutlet.disable()

            // if transmitterId is needed then connect button should be disabled, until transmitter id is set
            if let expectedBluetoothPeripheralType = expectedBluetoothPeripheralType, expectedBluetoothPeripheralType.needsTransmitterId() {
                connectButtonOutlet.disable()
            }

            // unwrap expectedBluetoothPeripheralType
            guard let expectedBluetoothPeripheralType = expectedBluetoothPeripheralType else {
                return
            }

            // if transmitterId needed, request for it now and set button text
            if expectedBluetoothPeripheralType.needsTransmitterId() {
                requestTransmitterId()
            }
        }

        // set title
        title = bluetoothPeripheralViewModel?.screenTitle()

        bluetoothPeripheralImageView.bluetoothPeripheralType = expectedBluetoothPeripheralType

        setupTableView()
    }

    // MARK: - private functions

    private func setupTableView() {
        if let tableView = tableView {
            tableView.dataSource = self
            tableView.delegate = self
            tableView.showsVerticalScrollIndicator = false
        }
    }

    private func scanForBluetoothPeripheral(type: BluetoothPeripheralType) {

        // if bluetoothPeripheral is not nil, then there's already a BluetoothPeripheral for which scanning has started or which is already known from a previous scan (either connected or not connected) (bluetoothPeripheral should be nil because if it is not, the scanbutton should not even be enabled, anyway let's check).
        guard bluetoothPeripheral == nil else {
            return
        }

        guard let bluetoothPeripheralManager = bluetoothPeripheralManager else {
            fatalError("in BluetoothPeripheralViewController scanForBluetoothPeripheral, bluetoothPeripheralManager is nil")
        }

        // if bluetoothPeripheralType needs transmitterId, then check that transmitterId is present
        if type.needsTransmitterId() && transmitterIdTempValue == nil {
            return
        }

        // initialize previousScanningResult to nil
        previousScanningResult = nil

        bluetoothPeripheralManager.startScanningForNewDevice(type: type, transmitterId: transmitterIdTempValue, bluetoothTransmitterDelegate: self, callBackForScanningResult: handleScanningResult(startScanningResult:), callback: { (bluetoothPeripheral) in

            BluetoothPeripheralViewController.log.d("BluetoothPeripheral address: \(bluetoothPeripheral.blePeripheral.address), name: \(bluetoothPeripheral.blePeripheral.name)")

            // remove info alert screen which may still be there
            self.dismissInfoAlertWhenScanningStarts()

            // set isScanning true
            self.isScanning = false

            // enable screen lock
            UIApplication.shared.isIdleTimerDisabled = false

            // assign internal bluetoothPeripheral to new bluetoothPeripheral
            self.bluetoothPeripheral = bluetoothPeripheral

            // assign transmitterId, if it's a new one then the value is nil
            bluetoothPeripheral.blePeripheral.transmitterId = self.transmitterIdTempValue

            // recall configure in bluetoothPeripheralViewModel
            self.bluetoothPeripheralViewModel?.configure(bluetoothPeripheral: self.bluetoothPeripheral, bluetoothPeripheralManager: bluetoothPeripheralManager, tableView: self.tableView, bluetoothPeripheralViewController: self)

            // enable the connect button
            self.connectButtonOutlet.enable()

            // set right text for connect button
            _ = BluetoothPeripheralViewController.setConnectButtonLabelTextAndGetStatusDetailedText(bluetoothPeripheral: bluetoothPeripheral,
                    isScanning: self.isScanning,
                    connectButtonOutlet: self.connectButtonOutlet,
                    expectedBluetoothPeripheralType: self.expectedBluetoothPeripheralType,
                    transmitterId: self.transmitterIdTempValue,
                    bluetoothPeripheralManager: bluetoothPeripheralManager as! BluetoothPeripheralManager)

            // enable the trashButton
            self.trashButtonOutlet.enable()

            // set self as delegate in the bluetoothTransmitter
            if let bluetoothTransmitter = bluetoothPeripheralManager.getBluetoothTransmitter(for: bluetoothPeripheral, createANewOneIfNecessary: false) {
                bluetoothTransmitter.bluetoothTransmitterDelegate = self
            }

            // reload the full screen , all rows in all sections in the tableView
            self.tableView.reloadData()

            // dismiss alert screen that shows info after clicking start scanning button
            if let infoAlertWhenScanningStarts = self.infoAlertWhenScanningStarts {
                infoAlertWhenScanningStarts.dismiss(animated: true, completion: nil)
                self.infoAlertWhenScanningStarts = nil
            }
        })
    }

    private func handleScanningResult(startScanningResult: BluetoothTransmitter.startScanningResult) {

        // if we already processed the same scanning result, then return
        guard startScanningResult != previousScanningResult else {
            return
        }

        previousScanningResult = startScanningResult

        // dismiss info alert screen, in case it's still there
        dismissInfoAlertWhenScanningStarts()

        // check startScanningResult
        switch startScanningResult {

        case .success:

            // unknown is the initial status returned, although it will actually start scanning

            // set isScanning true
            isScanning = true

            // disable the connect button
            connectButtonOutlet.disable()

            // app should be scanning now, update of cell is needed
            tableView.reloadRows(at: [IndexPath(row: Setting.connectionStatus.rawValue, section: 0)], with: .none)

            // disable screen lock
            UIApplication.shared.isIdleTimerDisabled = true

            // show info that user should keep the app in the foreground
            infoAlertWhenScanningStarts = PopupDialog(title: R.string.homeView.startScanningTitle(),
                    message: R.string.homeView.startScanningInfo(iOS.appDisplayName),
                    actionTitle: R.string.common.common_Ok(),
                    actionHandler: nil)
            present(infoAlertWhenScanningStarts!, animated: true)

        case .alreadyScanning, .alreadyConnected, .connecting:

            BluetoothPeripheralViewController.log.e("in handleScanningResult, scanning not started. Scanning result:  \(startScanningResult.description())")
            // no further processing, should normally not happen,

            // set isScanning false, although it should already be false
            isScanning = false

        case .poweredOff:

            BluetoothPeripheralViewController.log.e("in handleScanningResult, scanning not started. Bluetooth is not on")

            // show info that user should switch on bluetooth
            infoAlertWhenScanningStarts = PopupDialog(title: Texts_Common.warning,
                    message: Texts_HomeView.bluetoothIsNotOn,
                    actionTitle: R.string.common.common_Ok(),
                    actionHandler: nil)
            present(infoAlertWhenScanningStarts!, animated: true)

        case .other(let reason):

            BluetoothPeripheralViewController.log.e("in handleScanningResult, scanning not started. Scanning result: \(reason)")
                // no further processing, should normally not happen,

        case .unauthorized:

            BluetoothPeripheralViewController.log.e("in handleScanningResult, scanning not started. Scanning result = unauthorized")

            // show info that user should switch on bluetooth
            infoAlertWhenScanningStarts = PopupDialog(title: Texts_Common.warning,
                    message: Texts_HomeView.bluetoothIsNotAuthorized,
                    actionTitle: R.string.common.common_Ok(),
                    actionHandler: nil)
            present(infoAlertWhenScanningStarts!, animated: true)

        case .unknown:

            BluetoothPeripheralViewController.log.e("in handleScanningResult, scanning not started. Scanning result = unknown - this is always occurring when a BluetoothTransmitter starts scanning the first time. You should see now a new call to handleScanningResult")

        }
    }

    /// use clicked trash button, need to delete the bluetoothPeripheral
    private func trashButtonClicked() {
        // let's first check if bluetoothPeripheral exists, otherwise there's nothing to trash, normally this shouldn't happen because trashButton should be disabled if there's no bluetoothPeripheral
        guard let bluetoothPeripheral = bluetoothPeripheral else {
            return
        }

        // unwrap bluetoothPeripheralManager
        guard let bluetoothPeripheralManager = bluetoothPeripheralManager else {
            return
        }

        // first ask user if ok to delete and if yes delete
        let alert = PopupDialog(
                title: R.string.bluetoothPeripheralView.confirmDeletionPeripheral(),
                message: bluetoothPeripheral.blePeripheral.name,
                actionTitle: R.string.common.delete(),
                actionHandler: {
                    // delete
                    bluetoothPeripheralManager.deleteBluetoothPeripheral(bluetoothPeripheral: bluetoothPeripheral)

                    self.bluetoothPeripheral = nil

                    // close the viewController
                    self.navigationController?.popViewController(animated: true)
                    self.dismiss(animated: true, completion: nil)
                },
                cancelTitle: R.string.common.common_cancel()
        )

        present(alert, animated: true)
    }

    /// user clicked connect button
    private func connectButtonHandler() {
        // unwrap bluetoothPeripheralManager
        guard let bluetoothPeripheralManager = bluetoothPeripheralManager else {
            return
        }

        // unwrap expectedBluetoothPeripheralType
        guard let expectedBluetoothPeripheralType = expectedBluetoothPeripheralType else {
            return
        }

        // let's first check if bluetoothPeripheral exists
        if let bluetoothPeripheral = bluetoothPeripheral {
            // if shouldconnect = true then set setshouldconnect to false, this will also result in disconnecting
            if bluetoothPeripheral.blePeripheral.shouldconnect {
                // disconnect
                setShouldConnectToFalse(for: bluetoothPeripheral)

            } else {
                // check if it's a CGM being activated and if so that app is in master mode
                if expectedBluetoothPeripheralType.category() == .CGM, !UserDefaults.standard.isMaster {
                    present(PopupDialog(title: Texts_Common.warning,
                            message: Texts_BluetoothPeripheralView.cannotActiveCGMInFollowerMode,
                            actionTitle: R.string.common.common_Ok(),
                            actionHandler: nil),
                            animated: true,
                            completion: nil)

                    return
                }

                // device should automatically connect, this will be stored in coredata
                bluetoothPeripheral.blePeripheral.shouldconnect = true

                // save the update in coredata
                CoreDataManager.shared.saveChanges()

                // get bluetoothTransmitter
                if let bluetoothTransmitter = bluetoothPeripheralManager.getBluetoothTransmitter(for: bluetoothPeripheral, createANewOneIfNecessary: true) {

                    // set delegate of the new transmitter to self
                    bluetoothTransmitter.bluetoothTransmitterDelegate = self

                    // call configure in the model, as we have a new transmitter here
                    bluetoothPeripheralViewModel?.configure(bluetoothPeripheral: bluetoothPeripheral, bluetoothPeripheralManager: bluetoothPeripheralManager, tableView: tableView, bluetoothPeripheralViewController: self)

                    // connect (probably connection is already done because transmitter has just been created by bluetoothPeripheralManager, this is a transmitter for which mac address is known, so it will by default try to connect
                    bluetoothTransmitter.connect()
                }
            }

        } else {
            // there's no bluetoothPeripheral yet, so this is the case where viewController is opened to scan for a new peripheral
            // if it's a transmitter type that needs a transmitter id, and if there's no transmitterId yet, then ask transmitter id
            // else start scanning
            if expectedBluetoothPeripheralType.needsTransmitterId() && transmitterIdTempValue == nil {
                requestTransmitterId()

            } else {
                scanForBluetoothPeripheral(type: expectedBluetoothPeripheralType)
            }
        }

        // will change text of the button
        _ = BluetoothPeripheralViewController.setConnectButtonLabelTextAndGetStatusDetailedText(bluetoothPeripheral: bluetoothPeripheral,
                isScanning: isScanning,
                connectButtonOutlet: connectButtonOutlet,
                expectedBluetoothPeripheralType: expectedBluetoothPeripheralType,
                transmitterId: transmitterIdTempValue,
                bluetoothPeripheralManager: bluetoothPeripheralManager as! BluetoothPeripheralManager)
    }

    /// checks if bluetoothPeripheral is not nil, etc.
    /// - returns: true if bluetoothperipheral exists and is connected, false in all other cases
    private static func bluetoothPeripheralIsConnected(bluetoothPeripheral: BluetoothPeripheral, bluetoothPeripheralManager: BluetoothPeripheralManager) -> Bool {

        guard let connectionStatus = bluetoothPeripheralManager.getBluetoothTransmitter(for: bluetoothPeripheral, createANewOneIfNecessary: false)?.getConnectionStatus() else {
            return false
        }

        return connectionStatus == CBPeripheralState.connected
    }

    /// resets the bluetoothTransmitterDelegate to bluetoothPeripheralManager
    private func reassignBluetoothTransmitterDelegateToBluetoothPeripheralManager() {

        guard let bluetoothPeripheralManager = bluetoothPeripheralManager else {
            return
        }

        if let bluetoothPeripheral = bluetoothPeripheral,
           let bluetoothTransmitter = bluetoothPeripheralManager.getBluetoothTransmitter(for: bluetoothPeripheral, createANewOneIfNecessary: false) {

            // reassign delegate, actually as we're closing BluetoothPeripheralViewController, where BluetoothPeripheralsViewController
            bluetoothTransmitter.bluetoothTransmitterDelegate = bluetoothPeripheralManager
        }
    }

    private func requestTransmitterId() {

        // unwrap bluetoothPeripheralManager
        guard let bluetoothPeripheralManager = bluetoothPeripheralManager else {
            return
        }

        SettingsViewUtilities.runSelectedRowAction(
                selectedRowAction: .askText(
                        title: Texts_SettingsView.labelTransmitterId,
                        message: Texts_SettingsView.labelGiveTransmitterId,
                        keyboardType: .alphabet,
                        text: transmitterIdTempValue,
                        placeHolder: "00000",
                        actionTitle: nil,
                        cancelTitle: nil,
                        actionHandler: {
                            (transmitterId: String) in

                            // convert to uppercase
                            let transmitterIdUpper = transmitterId.uppercased().toNilIfLength0()

                            self.transmitterIdTempValue = transmitterIdUpper

                            // reload the specific row in the table
                            self.tableView.reloadRows(at: [IndexPath(row: Setting.transmitterId.rawValue, section: 0)], with: .none)

                            // as transmitter id has been set (or set to nil), connect button label text must change
                            _ = BluetoothPeripheralViewController.setConnectButtonLabelTextAndGetStatusDetailedText(bluetoothPeripheral: self.bluetoothPeripheral, isScanning: self.isScanning, connectButtonOutlet: self.connectButtonOutlet, expectedBluetoothPeripheralType: self.expectedBluetoothPeripheralType, transmitterId: transmitterIdUpper, bluetoothPeripheralManager: bluetoothPeripheralManager as! BluetoothPeripheralManager)

                        },
                        cancelHandler: nil,
                        inputValidator: {
                            transmitterId in

                            self.expectedBluetoothPeripheralType?.validateTransmitterId(transmitterId: transmitterId)
                        }
                ),
                forRowWithIndex: Setting.transmitterId.rawValue,
                forSectionWithIndex: generalSettingSectionNumber,
                withSettingsViewModel: nil,
                tableView: tableView,
                forUIViewController: self
        )
    }

    /// dismiss alert screen that shows info after cliking start scanning button
    private func dismissInfoAlertWhenScanningStarts() {
        if let infoAlertWhenScanningStarts = infoAlertWhenScanningStarts {
            infoAlertWhenScanningStarts.dismiss(animated: true, completion: nil)
            self.infoAlertWhenScanningStarts = nil
        }
    }
}

// MARK: - extension UITableViewDataSource, UITableViewDelegate

extension BluetoothPeripheralViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.textColor = ConstantsUI.tableViewHeaderTextColor
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        // there is one general section with settings applicable for all peripheral types, one or more specific section(s) with settings specific to type of bluetooth peripheral
        if bluetoothPeripheral == nil {
            // no peripheral known yet, only the first, bluetooth transmitter related settings are shown
            return 1

        } else {
            // number of sections = number of general sections + number of sections specific for the type of bluetoothPeripheral
            var numberOfSections = numberOfGeneralSections()

            if let bluetoothPeripheralViewModel = bluetoothPeripheralViewModel {
                numberOfSections = numberOfSections + bluetoothPeripheralViewModel.numberOfSections()
            }
            return numberOfSections
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return Setting.allCases.count
        }

        // it's not section 0 and it's not section 2 && weboop supported and it's not section 1 && nonfixed supported

        // this is the section with the transmitter specific settings
        // unwrap bluetoothPeripheralViewModel
        if let bluetoothPeripheralViewModel = bluetoothPeripheralViewModel {
            return bluetoothPeripheralViewModel.numberOfSettings(inSection: section)

        } else {
            fatalError("in tableView numberOfRowsInSection, bluetoothPeripheralViewModel is nil")
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell") ?? UITableViewCell(style: .value1, reuseIdentifier: "tableCell")

        // unwrap a few variables
        guard let bluetoothPeripheralManager = bluetoothPeripheralManager,
              let expectedBluetoothPeripheralType = expectedBluetoothPeripheralType
                else {
            return cell
        }

        let numberOfGeneralSections = numberOfGeneralSections()

        BluetoothPeripheralViewController.log.d("nonFixedSettingIsShown: \(nonFixedSettingIsShown), webOOPSettingIsShown: \(webOOPSettingIsShown)")

        // default value for accessoryView is nil
        cell.accessoryView = nil
        cell.accessoryType = .none
        cell.textLabel?.textColor = ConstantsUI.tableTitleColor
        cell.detailTextLabel?.textColor = ConstantsUI.tableDetailTextColor
        cell.isHidden = false

        // check if it's a Setting defined here in BluetoothPeripheralViewController, or a setting specific to the type of BluetoothPeripheral
        if indexPath.section >= numberOfGeneralSections {
            // it's a setting not defined here but in a BluetoothPeripheralViewModel
            if let bluetoothPeripheral = bluetoothPeripheral, let bluetoothPeripheralViewModel = bluetoothPeripheralViewModel {
                bluetoothPeripheralViewModel.update(cell: cell,
                        forRow: indexPath.row,
                        forSection: indexPath.section,
                        for: bluetoothPeripheral)
            }

            return cell
        }

        // bluetooth settings
        guard let setting = Setting(rawValue: indexPath.row) else {
            fatalError("BluetoothPeripheralViewController cellForRowAt, Unexpected setting")
        }

        updateWebOOPAndNonFixedSlope()

        // configure the cell depending on setting
        switch setting {

        case .name:
            cell.textLabel?.text = Texts_Common.name
            cell.detailTextLabel?.text = bluetoothPeripheral?.blePeripheral.name

        case .connectionStatus:
            cell.textLabel?.text = Texts_BluetoothPeripheralView.status
            cell.detailTextLabel?.text = BluetoothPeripheralViewController.setConnectButtonLabelTextAndGetStatusDetailedText(bluetoothPeripheral: bluetoothPeripheral, isScanning: isScanning, connectButtonOutlet: connectButtonOutlet, expectedBluetoothPeripheralType: expectedBluetoothPeripheralType, transmitterId: transmitterIdTempValue, bluetoothPeripheralManager: bluetoothPeripheralManager as! BluetoothPeripheralManager)

        case .transmitterId:
            cell.textLabel?.text = Texts_SettingsView.labelTransmitterId
            cell.detailTextLabel?.text = transmitterIdTempValue

            cell.isHidden = !expectedBluetoothPeripheralType.needsTransmitterId()

        case .connectOrDisconnectTimeStamp:
            if let bluetoothPeripheral = bluetoothPeripheral, let lastConnectionStatusChangeTimeStamp = bluetoothPeripheral.blePeripheral.lastConnectionStatusChangeTimeStamp {

                if BluetoothPeripheralViewController.bluetoothPeripheralIsConnected(bluetoothPeripheral: bluetoothPeripheral, bluetoothPeripheralManager: bluetoothPeripheralManager as! BluetoothPeripheralManager) {
                    cell.textLabel?.text = Texts_BluetoothPeripheralView.connectedAt

                } else {
                    cell.textLabel?.text = Texts_BluetoothPeripheralView.disConnectedAt
                }

                cell.detailTextLabel?.text = lastConnectionStatusChangeTimeStamp.toHumanFirendlyTime()

            } else {
                cell.textLabel?.text = Texts_BluetoothPeripheralView.connectedAt
                cell.detailTextLabel?.text = ""
            }

        case .nonFixedSlopeEnabled:

            cell.textLabel?.text = Texts_SettingsView.labelNonFixedTransmitter
            cell.detailTextLabel?.text = nil

            var currentStatus = false
            if let bluetoothPeripheral = bluetoothPeripheral {
                currentStatus = bluetoothPeripheral.blePeripheral.nonFixedSlopeEnabled
            }

            cell.accessoryView = UISwitch(isOn: currentStatus) {
                (isOn: Bool) in

                self.bluetoothPeripheral?.blePeripheral.nonFixedSlopeEnabled = isOn

                // send info to bluetoothPeripheralManager
                if let bluetoothPeripheral = self.bluetoothPeripheral {
                    bluetoothPeripheralManager.receivedNewValue(nonFixedSlopeEnabled: isOn, for: bluetoothPeripheral)
                    tableView.reloadSections(IndexSet(integer: 0), with: .none)
                }
            }

            // if it's a bluetoothPeripheral that uses oop web, then the setting can not be changed
            if let bluetoothPeripheral = bluetoothPeripheral {
                if bluetoothPeripheral.blePeripheral.webOOPEnabled {
                    cell.accessoryView?.isUserInteractionEnabled = false
                }
            }

            if !nonFixedSettingIsShown {
                cell.isHidden = true
            }

        case .webOOPEnabled:
            // set row text and set default row label to nil
            cell.textLabel?.text = R.string.settingsViews.settingsviews_manualcalibration()
            cell.detailTextLabel?.text = nil

            // get current value of webOOPEnabled, default false
            var currentWebOOPEnabledValue = false
            if let bluetoothPeripheral = bluetoothPeripheral {
                currentWebOOPEnabledValue = bluetoothPeripheral.blePeripheral.webOOPEnabled
            }

            cell.accessoryView = UISwitch(isOn: !currentWebOOPEnabledValue) {
                (isManualCalibrationOn: Bool) in

                self.bluetoothPeripheral?.blePeripheral.webOOPEnabled = !isManualCalibrationOn

                // send info to bluetoothPeripheralManager
                if let bluetoothPeripheral = self.bluetoothPeripheral {
                    bluetoothPeripheralManager.receivedNewValue(webOOPEnabled: !isManualCalibrationOn, for: bluetoothPeripheral)

                    // if user switches on web oop, then we need to force also use of non-fixed slopes to off
                    if !isManualCalibrationOn {
                        bluetoothPeripheral.blePeripheral.nonFixedSlopeEnabled = false
                        bluetoothPeripheralManager.receivedNewValue(nonFixedSlopeEnabled: false, for: bluetoothPeripheral)
                    }

                    // make sure that new value is stored in coredata, because a crash may happen here
                    CoreDataManager.shared.saveChanges()

                    // reload the section for nonFixedSettingsSectionNumber, even though the value may not have changed, because possibly isUserInteractionEnabled needs to be set to false for the nonFixedSettingsSectionNumber UISwitch
                    tableView.reloadSections(IndexSet(integer: 0), with: .none)

                    if isManualCalibrationOn {
                        let dialog = PopupDialog(title: R.string.bluetoothPeripheralView.dialog_title_manual_calibration_enabled(),
                                message: R.string.bluetoothPeripheralView.dialog_msg_manual_calibration_enabled(),
                                actionTitle: R.string.common.common_Ok(),
                                actionHandler: nil)
                        self.present(dialog, animated: true)
                    }
                }
            }

            if !webOOPSettingIsShown {
                cell.isHidden = true
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // unwrap a few needed variables
        guard let bluetoothPeripheralManager = bluetoothPeripheralManager,
              let bluetoothPeripheralViewModel = bluetoothPeripheralViewModel
                else {
            return
        }

        // check if it's one of the common settings or one of the peripheral type specific settings
        if indexPath.section >= numberOfGeneralSections() {
            // it's a setting not defined here but in a BluetoothPeripheralViewModel
            // bluetoothPeripheralViewModel should not be nil here, otherwise user wouldn't be able to click a row which is higher than maximum
            if let bluetoothPeripheral = bluetoothPeripheral {

                // parameter withSettingsViewModel is set to nil here, is used in the general settings page, where a view model represents a specific section, not used here
                SettingsViewUtilities.runSelectedRowAction(selectedRowAction: bluetoothPeripheralViewModel.userDidSelectRow(withSettingRawValue: indexPath.row, forSection: indexPath.section, for: bluetoothPeripheral, bluetoothPeripheralManager: bluetoothPeripheralManager), forRowWithIndex: indexPath.row, forSectionWithIndex: indexPath.section, withSettingsViewModel: nil, tableView: tableView, forUIViewController: self)

            }
            return
        }

        // it's a Setting defined here in BluetoothPeripheralViewController
        // is it a bluetooth setting or web oop setting  or non-fixed calibration slopes setting ?

        guard let setting = Setting(rawValue: indexPath.row) else {
            fatalError("BluetoothPeripheralViewController didSelectRowAt, Unexpected setting")
        }

        switch setting {

        case .name:
            guard let bluetoothPeripheral = bluetoothPeripheral else {
                return
            }

            let dialog = PopupDialog(title: R.string.common.name(),
                    message: bluetoothPeripheral.blePeripheral.name,
                    actionTitle: R.string.common.common_Ok(),
                    actionHandler: nil)

            present(dialog, animated: true)

        case .connectionStatus:
            break

        case .connectOrDisconnectTimeStamp:
            break

        case .transmitterId:
            // if transmitterId already has a value, then it can't be changed anymore. To change it, user must delete the transmitter and recreate one.
            if transmitterIdTempValue != nil {
                return
            }

            requestTransmitterId()

        case .webOOPEnabled, .nonFixedSlopeEnabled:
            // nothing to do
            break
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let bluetoothPeripheralViewModel = bluetoothPeripheralViewModel else {
            return nil
        }

        if section >= numberOfGeneralSections() {
            // title defined in viewModel
            return bluetoothPeripheralViewModel.sectionTitle(forSection: section)
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        if indexPath.section >= numberOfGeneralSections() {
            return 44
        }

        guard let setting = Setting(rawValue: indexPath.row) else {
            fatalError("BluetoothPeripheralViewController didSelectRowAt, Unexpected setting")
        }

        updateWebOOPAndNonFixedSlope()

        switch setting {

        case .webOOPEnabled:
            if webOOPSettingIsShown {
                return 44

            } else {
                return 0
            }

        case .nonFixedSlopeEnabled:
            if nonFixedSettingIsShown {
                return 44

            } else {
                return 0
            }

        case .transmitterId:
            if let expectedBluetoothPeripheralType = expectedBluetoothPeripheralType, expectedBluetoothPeripheralType.needsTransmitterId() {
                return 44

            } else {
                return 0
            }

        default:
            return 44
        }
    }

    private func updateWebOOPAndNonFixedSlope() {
        if webOOpAndNonFixedSlopeSettingsAreShownIsKnown {
            return
        }

        // first check if bluetoothPeripheral already known
        guard let bluetoothPeripheral = bluetoothPeripheral,
              let expectedBluetoothPeripheralType = expectedBluetoothPeripheralType else {
            return
        }

        // if transmitter is cgmTransmitter, if not nonWebOOPAllowed, then it means this is a transmitter that can not give rawdata
        // in that case don't show the sections  weboopenabled and nonfixedslope
        if let bluetoothPeripheralManager = bluetoothPeripheralManager,
           let bluetoothTransmitter = bluetoothPeripheralManager.getBluetoothTransmitter(for: bluetoothPeripheral, createANewOneIfNecessary: false) {

            // no need to recalculate webOOPSettingsSectionIsShown and nonFixedSettingsSectionIsShown later
            webOOpAndNonFixedSlopeSettingsAreShownIsKnown = true

            if let cgmTransmitter = bluetoothTransmitter as? CGMTransmitter {

                // is it allowed for this transmitter to work with rawdata?
                // if not then don't show weboopsettings and nonfixedslopesettings
                // there's only one section (the first) in this case
                if !cgmTransmitter.nonWebOOPAllowed() {

                    // mark web oop and non fixed slope settings sections as not shown
                    webOOPSettingIsShown = false
                    nonFixedSettingIsShown = false
                }
            }
        }

        if expectedBluetoothPeripheralType.canWebOOP(), expectedBluetoothPeripheralType.canUseNonFixedSlope() {

            // mark web oop and non fixed slope settings sections as shown
            webOOPSettingIsShown = true
            nonFixedSettingIsShown = true

        } else if expectedBluetoothPeripheralType.canUseNonFixedSlope() {

            // mark web oop and non fixed slope settings sections as not shown
            webOOPSettingIsShown = false
            nonFixedSettingIsShown = true

        } else if expectedBluetoothPeripheralType.canWebOOP() {

            // mark web oop and non fixed slope settings sections as not shown
            webOOPSettingIsShown = true
            nonFixedSettingIsShown = false
        }
    }
}

// MARK: - extension BluetoothTransmitterDelegate

extension BluetoothPeripheralViewController: BluetoothTransmitterDelegate {

    func transmitterNeedsPairing(bluetoothTransmitter: BluetoothTransmitter) {
        // handled in BluetoothPeripheralManager
        bluetoothPeripheralManager?.transmitterNeedsPairing(bluetoothTransmitter: bluetoothTransmitter)
    }

    func successfullyPaired() {
        // handled in BluetoothPeripheralManager
        bluetoothPeripheralManager?.successfullyPaired()
    }

    func pairingFailed() {
        // need to inform also other delegates
        bluetoothPeripheralManager?.pairingFailed()
    }

    func didConnectTo(bluetoothTransmitter: BluetoothTransmitter) {
        // handled in BluetoothPeripheralManager
        bluetoothPeripheralManager?.didConnectTo(bluetoothTransmitter: bluetoothTransmitter)

        // refresh complete first section (only status and connection timestamp changed but reload complete section)
        tableView.reloadSections(IndexSet(integer: 0), with: .none)
    }

    func didDisconnectFrom(bluetoothTransmitter: BluetoothTransmitter) {
        // handled in BluetoothPeripheralManager
        bluetoothPeripheralManager?.didDisconnectFrom(bluetoothTransmitter: bluetoothTransmitter)

        // refresh complete first section (only status and connection timestamp changed but reload complete section)
        tableView.reloadSections(IndexSet(integer: 0), with: .none)
    }

    func deviceDidUpdateBluetoothState(state: CBManagerState, bluetoothTransmitter: BluetoothTransmitter) {
        // handled in BluetoothPeripheralManager
        bluetoothPeripheralManager?.deviceDidUpdateBluetoothState(state: state, bluetoothTransmitter: bluetoothTransmitter)

        // when bluetooth status changes to powered off, the device, if connected, will disconnect, however didDisConnect doesn't get call (looks like an error in iOS) - so let's reload the cell that shows the connection status, this will refresh the cell
        // do this whenever the bluetooth status changes
        // refresh complete first section (only status and connection timestamp changed but reload complete section)
        tableView.reloadSections(IndexSet(integer: 0), with: .none)
    }

    func error(message: String) {
        // need to inform also other delegates
        bluetoothPeripheralManager?.error(message: message)

        let alert = PopupDialog(
                title: Texts_Common.warning,
                message: message,
                actionTitle: R.string.common.common_Ok(),
                actionHandler: nil
        )

        present(alert, animated: true)
    }
}

// MARK: - extension adding Segue Identifiers

/* EXPLANATION connect button text and status row detailed text
 For new ble
 - if needs transmitterId, but no transmitterId is given by user,
    - status = "need transmitter id"
    - button = "transmitter id" (same as text in cel)
 - if transmitter id not needed or transmitter id needed and already given, but not yet scanning :
    - status = "ready to scan"
    - button = "start scanning"
 - if  scanning :
    - status = "scanning"
    - button = "scanning" but button disabled
 
 Once BLE is known (mac address known)
 - if connected
    - status = connected
    - button = "disconnect"
 - if not connected, but shouldConnect = true
    - status = "trying to connect" (renamed to scanning)
    - button = "do no try to connect"
 - if not connected, but shouldConnect = false
    - status = "not trying to connect" (not scanning)
    - button = "try to connect"
 */
