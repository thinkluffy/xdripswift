import UIKit

/// viewcontroller for first settings screen
final class SettingsViewController: UIViewController {

    // MARK: - IBOutlet's and IPAction's
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Private Properties
            
    /// will show pop up with title and message
    private var messageHandler: ((String, String) -> Void)?
    
    /// UIAlertController used by messageHandler
    private var messageHandlerUiAlertController: UIAlertController?
    
    /// array of viewmodels, one per section
    private var viewModels = [SettingsViewModelProtocol]()
    
    private enum Section: Int, CaseIterable, SettingsProtocol {
        
        ///General settings - language, glucose unit
        case general
        
        ///Home Screen settings - urgent high, high, target, low and urgent low values for guidelines
        case homescreen
        
        /// statistics settings
        case statistics
        
        /// alarms
        case alarms
        
        ///nightscout settings
        case nightscout
        
        ///dexcom share settings
        case dexcom
        
        /// healthkit
        case healthkit
        
        /// store bg values in healthkit
        case speak
        
        /// M5 stack settings
        case M5stack
        
        /// Apple Watch settings
        case AppleWatch
        
        /// more settings
        case more
        
        func viewModel() -> SettingsViewModelProtocol {
            switch self {
                
            case .general:
                return SettingsViewGeneralSettingsViewModel()
            case .homescreen:
                return SettingsViewHomeScreenSettingsViewModel()
            case .statistics:
                return SettingsViewStatisticsSettingsViewModel()
            case .alarms:
                return SettingsViewAlertSettingsViewModel()
            case .nightscout:
                return SettingsViewNightScoutSettingsViewModel()
            case .dexcom:
                return SettingsViewDexcomSettingsViewModel()
            case .healthkit:
                return SettingsViewHealthKitSettingsViewModel()
            case .speak:
                return SettingsViewSpeakSettingsViewModel()
            case .M5stack:
                return SettingsViewM5StackSettingsViewModel()
            case .AppleWatch:
                return SettingsViewAppleWatchSettingsViewModel()
            case .more:
                return SettingsViewMoreSettingsViewModel()
            }
        }
    }
        
    private func configure() {
        // create messageHandler
        messageHandler = { (title, message) in
            
            // piece of code that we need two times
            let createAndPresentMessageHandlerUIAlertController = {
                self.messageHandlerUiAlertController = UIAlertController(title: title, message: message, actionHandler: nil)
                
                if let messageHandlerUiAlertController = self.messageHandlerUiAlertController {
                    self.present(messageHandlerUiAlertController, animated: true, completion: nil)
                }
            }
            
            // first check if messageHandlerUiAlertController is not nil and is presenting. If it is, dismiss it and when completed call createAndPresentMessageHandlerUIAlertController
            if let messageHandlerUiAlertController = self.messageHandlerUiAlertController {
                if messageHandlerUiAlertController.isBeingPresented {
                    messageHandlerUiAlertController.dismiss(animated: true, completion: createAndPresentMessageHandlerUIAlertController)
                    return
                    
                }
            }
            
            // we're here which means there wasn't a messageHandlerUiAlertController being presented, so present it now
            createAndPresentMessageHandlerUIAlertController()
        }

        // initialize viewModels
        for section in Section.allCases {
            // get a viewModel for the section
            let viewModel = section.viewModel()
            
            // unwrap messageHandler and store in the viewModel
            if let messageHandler = messageHandler {
                viewModel.storeMessageHandler(messageHandler: messageHandler)
            }
            
            // store self as uiViewController in the viewModel
            viewModel.storeUIViewController(uIViewController: self)
            
            // store reload closure in the viewModel
            viewModel.storeRowReloadClosure(rowReloadClosure: {row in
                self.tableView.reloadRows(at: [IndexPath(row: row, section: section.rawValue)], with: .none)
            })

            // store the viewModel
            self.viewModels.append(viewModel)
        }
    }

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Texts_SettingsView.screenTitle
        
        setupView()
        
        configure()
    }

    // MARK: - Private helper functions
    
    private func setupView() {
        setupTableView()
    }

    /// setup datasource, delegate, seperatorInset
    private func setupTableView() {
        if let tableView = tableView {
            // insert slightly the separator text so that it doesn't touch the safe area limit
            tableView.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
}

extension SettingsViewController:UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - UITableViewDataSource protocol Methods
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.textColor = ConstantsUI.tableViewHeaderTextColor
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModels[section].sectionTitle()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels[section].numberOfRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "tableCell") ?? UITableViewCell(style: .value1, reuseIdentifier: "tableCell")
        
        // Configure Cell
        SettingsViewUtilities.configureSettingsCell(cell: &cell,
                                                    forRowWithIndex: indexPath.row,
                                                    forSectionWithIndex: indexPath.section,
                                                    withViewModel: viewModels[indexPath.section],
                                                    tableView: tableView)
        
        return cell
    }
    
    // MARK: - UITableViewDelegate protocol Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let viewModel = viewModels[indexPath.section]
        
        if viewModel.isEnabled(index: indexPath.row) {
            let selectedRowAction = viewModel.onRowSelect(index: indexPath.row)
            
            SettingsViewUtilities.runSelectedRowAction(selectedRowAction: selectedRowAction,
                                                       forRowWithIndex: indexPath.row,
                                                       forSectionWithIndex: indexPath.section,
                                                       withSettingsViewModel: viewModel,
                                                       tableView: tableView,
                                                       forUIViewController: self)
        }
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        // apple doc says : Use this method to respond to taps in the detail button accessory view of a row. The table view does not call this method for other types of accessory views.
        // when user clicks on of the detail buttons, then consider this as row selected, for now - as it's only license that is using this button for now
        self.tableView(tableView, didSelectRowAt: indexPath)
    }
}

/// defines perform segue identifiers used within settingsviewcontroller
extension SettingsViewController {
    
    enum SegueIdentifiers:String {

        /// to go from general settings screen to alert types screen
        case settingsToAlertTypeSettings = "settingsToAlertTypeSettings"
        
        /// to go from general settings screen to alert screen
        case settingsToAlertSettings = "settingsToAlertSettings"
        
        /// to go from general settings screen to M5Stack settings screen
        case settingsToM5StackSettings = "settingsToM5StackSettings"
        
        /// to go from general settings to more settings
        case settingsToMore = "settingsToMore"
    }
}
