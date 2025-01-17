import UIKit

final class AlertsSettingsViewController: SubSettingsViewController {

    // MARK: - Properties
    
    @IBOutlet weak var tableView: UITableView!
 
    // unwind segue, from AlertSettingsViewController to AlertsSettingsViewController
    @IBAction func unwindToAlertsSettingsViewController(segue: UIStoryboardSegue) {
        
        // for in case an alertEntry got deleted, reinitialize alertEntriesPerAlertKind - otherwise alertEntriesPerAlertKind would have an empty value and an empty row would be shown
        resetAlertEntriesPerAlertKind()
        
        // will refresh one of the sections
        if let toDoWhenUnwinding = toDoWhenUnwinding {
            toDoWhenUnwinding()
        }
    }
    
    private lazy var alertEntriesAccessor = AlertEntriesAccessor()
    
    private lazy var alertTypesAccessor = AlertTypesAccessor()
    
    /// all alertEntries, one array of alertEntries per alertKind
    private lazy var alertEntriesPerAlertKind:[[AlertEntry]] = {
        return alertEntriesAccessor.getAllEntriesPerAlertKind(alertTypesAccessor: alertTypesAccessor)
    }()
    
    /// reset alertEntriesPerAlertKind
    private func resetAlertEntriesPerAlertKind()  {
        alertEntriesPerAlertKind = alertEntriesAccessor.getAllEntriesPerAlertKind(alertTypesAccessor: alertTypesAccessor)
    }
    
    /// closure to be set before performSegue to AlertSettingsViewController.
    ///
    /// this closure can be called when returning from AlertSettingsViewController to AlertsSettingsViewController.
    private var toDoWhenUnwinding: (() -> ())?

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Texts_Alerts.alertsScreenTitle
        setupView()
    }
    
    // MARK: - other overriden functions
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segue.identifier else {
            fatalError("In AlertsSettingsViewController, prepare for segue, Segue had no identifier")
        }
        
        guard let segueIdentifierAsCase = AlertSettingsViewController.SegueIdentifiers(rawValue: segueIdentifier) else {
            fatalError("In AlertsSettingsViewController, segueIdentifierAsCase could not be initialized")
        }
        
        switch segueIdentifierAsCase {
            
        case AlertSettingsViewController.SegueIdentifiers.alertsToAlertSettings:
            guard let vc = segue.destination as? AlertSettingsViewController, let (section, row) = sender as? (Int,Int) else {
                fatalError("In AlertsSettingsViewController, prepare for segue, viewcontroller is not AlertSettingsViewController or sender is not (Int,Int)) or coreDataManager is nil" )
            }
            
            // function to run when unwinding from AlertSettingsViewController tp AlertsSettingsViewController occurs
            toDoWhenUnwinding = {self.tableView.reloadSections(IndexSet(integer: section), with: .none)}
            
            // do the mapping for section number. The sections in the view are ordered differently than the cases in AlertKind.
            let mappedSectionNumber = AlertKind.alertKindRawValue(forSection: section)
            
            // minimumStart should be 1 minute higher than start of previous row, except if this is the first row, then minimumStart is 0
            var minimumStart:Int16 = 0
            if row > 0 {minimumStart = alertEntriesPerAlertKind[mappedSectionNumber][row - 1].start + 1}
            
            // maximumStart is start of next row - 1 minute, except if this is the last row
            var maximumStart:Int16 = 24 * 60 - 1
            if row < alertEntriesPerAlertKind[mappedSectionNumber].count - 1 {
                maximumStart = alertEntriesPerAlertKind[mappedSectionNumber][row + 1].start - 1
            }
            
            // configure view controller
            vc.configure(alertEntry: alertEntriesPerAlertKind[mappedSectionNumber][row],
                         minimumStart: minimumStart,
                         maximumStart: maximumStart)
        default:
            // shouldn't happen because we're in alertssettings view here
            break
        }
    }
    
    // MARK: - private helper functions
    
    // setup the view
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

extension AlertsSettingsViewController:UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - UITableViewDataSource and UITableViewDelegate protocol Methods
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if let view = view as? UITableViewHeaderFooterView {
            
            view.textLabel?.textColor = ConstantsUI.tableViewHeaderTextColor
            
        }
        
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alertEntriesPerAlertKind[AlertKind.alertKindRawValue(forSection: section)].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell") ?? UITableViewCell(style: .value1, reuseIdentifier: "tableCell")
        cell.textLabel?.textColor = ConstantsUI.tableTitleColor
        cell.detailTextLabel?.textColor = ConstantsUI.tableDetailTextColor
        
        // alertKind corresponds to the section number, mapped to correct section
        guard let alertKind = AlertKind(forSection: indexPath.section) else {
            fatalError("AlertsSettingsViewController, in cellForRowAt, failed to create alertKind")
        }
        
        // get the alertEntry
        let alertEntry = alertEntriesPerAlertKind[alertKind.rawValue][indexPath.row]

        // get alertValue as Double
        let alertValue = alertEntry.value
        
        // start creating the textLabel, star with start time in presentation hh:mm
        var textLabelToUse = (Int(alertEntry.start)).convertMinutesToTimeAsString()
        
        // add a space
        textLabelToUse = textLabelToUse + " "
        
        // do we add the alert value or not ?
        //   - is the alerttype enabled ? If it's not no need to show the value (it was like that in iosxdrip, seems a good approach)
        //   - does the alert type need a value ? at the moment al do, iphone muted alert (not present) yet would need it
        if alertKind.needsAlertValue() && alertEntry.alertType.enabled {
            // only bg level alerts would need conversion
            if alertKind.valueNeedsConversionToMmol() {
                textLabelToUse = textLabelToUse + Double(alertValue).mgdlToMmolAndToString(mgdl: UserDefaults.standard.bloodGlucoseUnitIsMgDl)
            } else {
                textLabelToUse = textLabelToUse + alertValue.description
            }
            textLabelToUse = textLabelToUse + " "
        }
        
        // and now the name of the alerttype
        textLabelToUse = textLabelToUse + alertEntry.alertType.name
        
        cell.textLabel?.text = textLabelToUse
        
        // no detail text to be shown
        cell.detailTextLabel?.text = nil
        
        // clicking the cell will always open a new screen which allows the user to edit the alert type
        cell.accessoryType = .disclosureIndicator
        
        // set color of disclosureIndicator to ConstantsUI.disclosureIndicatorColor
        cell.accessoryView = DTCustomColoredAccessory(color: ConstantsUI.disclosureIndicatorColor)
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // we're having one section per alertkind, so the number = the size of the array alertsEntriesPerAlertKind
        return alertEntriesPerAlertKind.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        // sender = tuple with section and row index
        self.performSegue(withIdentifier:AlertSettingsViewController.SegueIdentifiers.alertsToAlertSettings.rawValue, sender: (indexPath.section, indexPath.row))
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return AlertKind(forSection: section)?.alertTitle()
    }
}
