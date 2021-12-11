import UIKit
import CoreBluetooth

/// uiviewcontroller to show list of BluetoothPeripherals, first uiviewcontroller when clicking the BluetoothPeripheral tab
final class BluetoothPeripheralsViewController: UIViewController {
    
    // MARK: - IBOutlet's and IBAction's

    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func addButtonAction(_ sender: UIBarButtonItem) {
        addButtonAction()
    }
    
    // MARK:- private properties
        
    /// a bluetoothPeripheralManager
    private weak var bluetoothPeripheralManager: BluetoothPeripheralManaging?
    
    // MARK: public functions
    
    /// configure
    public func configure(bluetoothPeripheralManager: BluetoothPeripheralManaging) {
        self.bluetoothPeripheralManager = bluetoothPeripheralManager
        
        // setup bluetoothperipherals
        initializeBluetoothTransmitterDelegates()
    }

    /// - iterate through the known BluetoothPeripheral's.
    /// -  If there's one in the category CGM that has shouldConnect to true,
    ///     - then return true
    ///     - display alert that no more than one cgm should be connected
    public static func otherCGMTransmitterHasShouldConnectTrue(bluetoothPeripheralManager: BluetoothPeripheralManaging?, uiViewController: UIViewController) -> Bool {
        
        // unwrap bluetoothPeripheralManager
        guard let bluetoothPeripheralManager = bluetoothPeripheralManager else {return false}
        
        for bluetoothPeripheral in bluetoothPeripheralManager.getBluetoothPeripherals() {
            if bluetoothPeripheral.bluetoothPeripheralType().category() == .CGM &&
                bluetoothPeripheral.blePeripheral.shouldconnect {
            
                uiViewController.present(UIAlertController(title: Texts_Common.warning, message: Texts_BluetoothPeripheralsView.noMultipleActiveCGMsAllowed, actionHandler: nil), animated: true, completion: nil)
                
                return true
            }
        }
        return false
    }
    
    /// gets index in bluetoothPeripherals (and bluetoothtransmitters) for indexPath
    public func getIndexInTable(forRowAt indexPath: IndexPath) -> Int {
        // unwrap bluetoothPeripheralManager
        guard let bluetoothPeripheralManager = bluetoothPeripheralManager else {return 0}
        
        // start with 0
        var index = 0
        
        // loop through bluetoothperipherals. increase index as long as section of found peripheral does not match section in indexPath
        for bluetoothPeripheral in bluetoothPeripheralManager.getBluetoothPeripherals() {
            if bluetoothPeripheral.bluetoothPeripheralType().category().index() < indexPath.section {
                index = index + 1
                
            } else {
                break
            }
        }
        return index + indexPath.row
    }

    // MARK:- overrides
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // reinitialise bluetoothPeripherals because we're coming back from BluetoothPeripheralViewController where a BluetoothPeripheral may have been added or deleted
        initializeBluetoothTransmitterDelegates()
        
        // reload the table
        tableView.reloadSections(IndexSet(integersIn:  0..<tableView.numberOfSections), with: .none)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Texts_BluetoothPeripheralsView.screenTitle
        
        setupTableView()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let segueIdentifier = segue.identifier else {
            fatalError("In BluetoothPeripheralsViewController, prepare for segue, Segue had no identifier")
        }

        if segueIdentifier == R.segue.bluetoothPeripheralsViewController.bluetoothPeripheral.identifier {
            
            guard let vc = segue.destination as? BluetoothPeripheralViewController else {
                fatalError("In BluetoothPeripheralsViewController, prepare for segue, viewcontroller is not BluetoothPeripheralViewController or coreDataManager is nil" )
            }
            
            guard let expectedBluetoothPeripheralType = (sender as? BluetoothPeripheral) != nil ? (sender as! BluetoothPeripheral).bluetoothPeripheralType() : (sender as? BluetoothPeripheralType) != nil ? (sender as! BluetoothPeripheralType): nil  else {

                fatalError("In BluetoothPeripheralsViewController, prepare for segue, sender is not BluetoothPeripheral and not BluetoothPeripheralType" )

            }
            
            // unwrap bluetoothPeripheralManager
            guard let bluetoothPeripheralManager = bluetoothPeripheralManager else {return}
            
            vc.configure(bluetoothPeripheral: sender as? BluetoothPeripheral,
                         bluetoothPeripheralManager: bluetoothPeripheralManager,
                         expectedBluetoothPeripheralType: expectedBluetoothPeripheralType)
        }
    }

    // MARK: private helper functions
    
    /// user clicked add button
    private func addButtonAction() {
        // check that no other CGM has shouldconnect set to true
        // the function otherCGMTransmitterHasShouldConnectTrue will also create an alert with info that only one CGM can be active
        if BluetoothPeripheralsViewController.otherCGMTransmitterHasShouldConnectTrue(bluetoothPeripheralManager: bluetoothPeripheralManager,
                                                                                      uiViewController: self) {
            return
        }
        
        // check the app is in master mode
        if !UserDefaults.standard.isMaster {
            present(UIAlertController(title: Texts_Common.warning,
                                      message: Texts_BluetoothPeripheralView.cannotActiveCGMInFollowerMode,
                                      actionHandler: nil),
                    animated: true)
            return
        }
        
        // the category has only CGM currently
        
        let data = BluetoothPeripheralCategory.listOfBluetoothPeripheralTypes(withCategory: BluetoothPeripheralCategory.listOfCategories()[0])
        
        let pickerViewData = PickerViewDataBuilder(data: data, actionHandler: {
            (_ typeIndex: Int) in
            
            // get the selected BluetoothPeripheralType
            let type = BluetoothPeripheralType(rawValue: BluetoothPeripheralCategory.listOfBluetoothPeripheralTypes(withCategory: BluetoothPeripheralCategory.listOfCategories()[0])[typeIndex])
            
            // go to screen to add a new BluetoothPeripheral
            // in the sender we add the selected bluetoothperipheraltype
            self.performSegue(withIdentifier: R.segue.bluetoothPeripheralsViewController.bluetoothPeripheral, sender: type)
            
        })
            .title(Texts_BluetoothPeripheralsView.selectType)
            .build()
        
        BottomSheetPickerViewController.show(in: self, pickerViewData: pickerViewData)
    }
    
    // setup datasource, delegate, seperatorInset
    private func setupTableView() {
        guard let tableView = tableView else {
            return
        }
        
        // insert slightly the separator text so that it doesn't touch the safe area limit
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
    }

    /// calls tableView.reloadRows for the row where bluetoothPeripheral is shown
    private func updateRow(for bluetoothPeripheral: BluetoothPeripheral) {
        // possibly an instance of BluetoothPeripheralViewController is on top of this UIViewController, in which case it's better not to update the rows (xcode creates warnings if this would be done)
        if isViewLoaded && (view.window != nil) {
            tableView.reloadRows(at: [IndexPath(row: getIndexInSection(for: bluetoothPeripheral), section: bluetoothPeripheral.bluetoothPeripheralType().category().index())], with: .none)
        }
    }
    
    /// for specific BluetoothPeripheral, finds the number of the row in the table in it's section
    private func getIndexInSection(for bluetoothPeripheral: BluetoothPeripheral) -> Int {
        // unwrap bluetoothPeripheralManager
        guard let bluetoothPeripheralManager = bluetoothPeripheralManager else {return 0}
        
        // start with 0
        var rowNumber = 0
        
        // loop through all BluetoothPeripheral's, skip those that are not of the same category, continue until one is found with the same address, increase rowNumber each time one is found in same category
        for peripheralInList in bluetoothPeripheralManager.getBluetoothPeripherals() {
            if peripheralInList.bluetoothPeripheralType().category() == bluetoothPeripheral.bluetoothPeripheralType().category() {
                if peripheralInList.blePeripheral.address == bluetoothPeripheral.blePeripheral.address {
                    break
                }
                rowNumber = rowNumber + 1
            }
        }
  
        // we should not get here
        return rowNumber
    }
    
    /// - sets the delegates of each transmitter to self
    /// - bluetoothPeripheralManager will also still receive delegate calls
    private func initializeBluetoothTransmitterDelegates() {
        if let bluetoothPeripheralManager = bluetoothPeripheralManager  {
            for bluetoothTransmitter in bluetoothPeripheralManager.getBluetoothTransmitters() {
                // assign self as BluetoothTransmitterDelegate
                bluetoothTransmitter.bluetoothTransmitterDelegate = self
            }
        }
    }
    
    /// number of rows in section
    private func numberOfRows(inSection section: Int) -> Int {
        // unwrap bluetoothPeripheralManager
        guard let bluetoothPeripheralManager = bluetoothPeripheralManager else {return 0}
        
        // initially set to 0
        var numberOfRows = 0
        
        // loop through bluetoothPeripheralManager's and count amount that has a category matching the section number
        for bluetoothPeripheral in bluetoothPeripheralManager.getBluetoothPeripherals() {
            if bluetoothPeripheral.bluetoothPeripheralType().category().index() == section {
                numberOfRows = numberOfRows + 1
            }
        }
        
        return numberOfRows
    }
}

// MARK: extension UITableViewDataSource and UITableViewDelegate

extension BluetoothPeripheralsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.textColor = ConstantsUI.tableViewHeaderTextColor
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRows(inSection: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell") ?? UITableViewCell(style: .value1, reuseIdentifier: "tableCell")
        cell.textLabel?.textColor = ConstantsUI.tableTitleColor
        cell.detailTextLabel?.textColor = ConstantsUI.tableDetailTextColor
        
        // unwrap bluetoothPeripheralManager
        guard let bluetoothPeripheralManager = bluetoothPeripheralManager else {return cell}

        // get the bluetoothPeripheral
        let bluetoothPeripheral = bluetoothPeripheralManager.getBluetoothPeripherals()[getIndexInTable(forRowAt: indexPath)]
        
        cell.textLabel?.text = bluetoothPeripheral.blePeripheral.name
        
        // detail is the connection status
        cell.detailTextLabel?.text = BluetoothPeripheralViewController.setConnectButtonLabelTextAndGetStatusDetailedText(bluetoothPeripheral: bluetoothPeripheral, isScanning: false, connectButtonOutlet: nil, expectedBluetoothPeripheralType: bluetoothPeripheral.bluetoothPeripheralType(), transmitterId: nil, bluetoothPeripheralManager: bluetoothPeripheralManager as! BluetoothPeripheralManager)

        // clicking the cell will always open a new screen which allows the user to edit the alert type - add disclosureIndicator
        // set color of disclosureIndicator to ConstantsUI.disclosureIndicatorColor
        cell.accessoryView = DTCustomColoredAccessory(color: ConstantsUI.disclosureIndicatorColor)

        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // equal to the amount of BluetoothPeripheralCategory types
        return BluetoothPeripheralCategory.allCases.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
       
        // unwrap bluetoothPeripheralManager
        guard let bluetoothPeripheralManager = bluetoothPeripheralManager else {return}
        
        performSegue(withIdentifier: R.segue.bluetoothPeripheralsViewController.bluetoothPeripheral,
                     sender: bluetoothPeripheralManager.getBluetoothPeripherals()[getIndexInTable(forRowAt: indexPath)])
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section < BluetoothPeripheralCategory.allCases.count else {return nil}
        
        // if there's no bluetoothperipherals then show no title
        if numberOfRows(inSection: section) == 0 {return nil}
        
        return BluetoothPeripheralCategory.allCases[section].rawValue
    }

}

// MARK: - extension BluetoothTransmitterDelegate

extension BluetoothPeripheralsViewController: BluetoothTransmitterDelegate {
    
    func transmitterNeedsPairing(bluetoothTransmitter: BluetoothTransmitter) {
        // forward this call to bluetoothPeripheralManager who will handle it
        bluetoothPeripheralManager?.transmitterNeedsPairing(bluetoothTransmitter: bluetoothTransmitter)
    }
    
    func successfullyPaired() {
        // forward this call to bluetoothPeripheralManager who will handle it
        bluetoothPeripheralManager?.successfullyPaired()
    }
    
    func pairingFailed() {
        // forward this call to bluetoothPeripheralManager who will handle it
        bluetoothPeripheralManager?.pairingFailed()
    }
    
    func error(message: String) {
        // forward this call to bluetoothPeripheralManager who will handle it
        bluetoothPeripheralManager?.error(message: message)
    }
    
    func didConnectTo(bluetoothTransmitter: BluetoothTransmitter) {
        // forward this call to bluetoothPeripheralManager who will handle it
        bluetoothPeripheralManager?.didConnectTo(bluetoothTransmitter: bluetoothTransmitter)

        // unwrap bluetoothPeripheralManager
        guard let bluetoothPeripheralManager = bluetoothPeripheralManager, let bluetoothPeripheral =  bluetoothPeripheralManager.getBluetoothPeripheral(for: bluetoothTransmitter) else {return}
        
        // row with connection status in the view must be updated
        updateRow(for: bluetoothPeripheral)
    }
    
    func didDisconnectFrom(bluetoothTransmitter: BluetoothTransmitter) {
        // forward this call to bluetoothPeripheralManager who will handle it
        bluetoothPeripheralManager?.didDisconnectFrom(bluetoothTransmitter: bluetoothTransmitter)

        // unwrap bluetoothPeripheralManager
        guard let bluetoothPeripheralManager = bluetoothPeripheralManager, let bluetoothPeripheral =  bluetoothPeripheralManager.getBluetoothPeripheral(for: bluetoothTransmitter) else {return}
        
        // row with connection status in the view must be updated
        updateRow(for: bluetoothPeripheral)
    }
    
    func deviceDidUpdateBluetoothState(state: CBManagerState, bluetoothTransmitter: BluetoothTransmitter) {
        // forward this call to bluetoothPeripheralManager who will handle it
        bluetoothPeripheralManager?.deviceDidUpdateBluetoothState(state: state, bluetoothTransmitter: bluetoothTransmitter)

        // unwrap bluetoothPeripheralManager
        guard let bluetoothPeripheralManager = bluetoothPeripheralManager, let bluetoothPeripheral =  bluetoothPeripheralManager.getBluetoothPeripheral(for: bluetoothTransmitter) else {return}

        // when bluetooth status changes to powered off, the device, if connected, will disconnect, however didDisConnect doesn't get call (looks like an error in iOS) - so let's reload the cell that shows the connection status, this will refresh the cell
        if state == CBManagerState.poweredOff {
            updateRow(for: bluetoothPeripheral)
        }
    }
}

