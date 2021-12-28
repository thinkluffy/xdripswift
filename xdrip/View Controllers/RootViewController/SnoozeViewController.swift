import UIKit

final class SnoozeViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = Texts_HomeView.snoozeButton
        setupView()
    }

    private func setupView() {
        if let tableView = tableView {
            tableView.dataSource = self
            tableView.delegate = self
            tableView.showsVerticalScrollIndicator = false
        }
    }
}

// MARK: - Conform to UITableViewDataSource

extension SnoozeViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // number of sections corresponds to number of alarm types
        return AlertKind.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // just one row per alarm type
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell") ?? UITableViewCell(style: .value1, reuseIdentifier: "tableCell")
        cell.textLabel?.textColor = ConstantsUI.tableTitleColor
        cell.detailTextLabel?.textColor = ConstantsUI.tableDetailTextColor
        
        // alertKind corresponds to section number
        guard let alertKind = AlertKind(forSection: indexPath.section) else {
            fatalError("In SnoozeViewController, cellForRowAt, could not create alertKind")
        }
        
        // get snoozeParameters for the alertKind
        let (isSnoozed, remainingSeconds) = AlertManager.shared.getSnoozeParameters(alertKind: alertKind).getSnoozeValue()

        if isSnoozed {
            guard let remainingSeconds = remainingSeconds else {
                fatalError("In SnoozeViewController, remainingSeconds is nil but alert is snoozed")
            }

            // till when snoozed, as Date
            let snoozedTillDate = Date(timeIntervalSinceNow: Double(remainingSeconds))
            
            // if snoozed till after 00:00 then show date and time when it ends, else only show time
            let showDate = snoozedTillDate.toMidnight() > Date()
            
            cell.textLabel?.text = TextsSnooze.snoozed_until + " " + snoozedTillDate.toString(timeStyle: .short, dateStyle: showDate ? .short : .none)
            
        } else {
            cell.textLabel?.text = TextsSnooze.not_snoozed
        }
        
        // no detailed text to be shown, the snooze time is already given in the textLabel
        cell.detailTextLabel?.text = nil
        
        // no accessory type to be shown
        cell.accessoryType = .none
        
        // uiswitch will be on if currently snoozed, off if currently not snoozed
        cell.accessoryView = UISwitch(isOn: isSnoozed) {
            (isOn: Bool) in
            
            // closure to reload the row after user clicked form on to off, or from off to on and selected a snoozeperiod
            let reloadRow = { tableView.reloadRows(at: [IndexPath(row: 0, section: indexPath.section)], with: .none)}
            
            // changing from off to on. Means user wants to pre-snooze
            if isOn {
                // create and display pickerViewData
                let pickerViewData = AlertManager.shared.createPickerViewData(
                    forAlertKind: alertKind,
                    content: nil,
                    actionHandler: { reloadRow() },
                    cancelHandler: { reloadRow() }
                )
                                                                       
                BottomSheetPickerViewController.show(in: self, pickerViewData: pickerViewData)

            } else {
                // changing from on to off. Means user wants to unsnooze
                AlertManager.shared.unSnooze(alertKind: alertKind)
                
                reloadRow()
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // alertKind corresponds to section number
        guard let alertKind = AlertKind(forSection: section) else {
            fatalError("In titleForHeaderInSection, could not create alertKind")
        }
        
        return alertKind.alertTitle()
    }
}

// MARK: - Conform to UITableViewDelegate

extension SnoozeViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.textColor = ConstantsUI.tableViewHeaderTextColor
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
