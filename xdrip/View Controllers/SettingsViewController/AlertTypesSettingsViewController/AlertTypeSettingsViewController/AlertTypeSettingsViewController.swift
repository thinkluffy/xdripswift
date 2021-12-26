import UIKit
import PopupDialog

/// a case per type of attribute that can be set in an AlerTypeSettingsView
fileprivate enum Setting:Int, CaseIterable {
    /// is it enabled or not
    case enabled = 0
    /// vibrate or not
    case vibrate = 1
    /// sound name
    case soundName = 2
    /// override mute or not
    case overridemute = 3
    /// snooze Via Notification on homescreen or not
    case snoozeViaNotification = 4
    /// default snoozeperiod when snoozing from homescreen
    case defaultSnoozePeriod = 5
    /// the name of the alert type
    case name = 6
}

/// edit or add an alert types,
final class AlertTypeSettingsViewController: SubSettingsViewController {
    
    // MARK: - IBOutlet's and IBAction's
    
    /// a tableView is used to display all alerttype properties - not the nicest solution maybe, but the quickest right now
    @IBOutlet weak var tableView: UITableView!
    
    // done button, to confirm changes
    @IBAction func doneButtonAction(_ sender: UIBarButtonItem) {
        doneButtonAction()
    }
    
    // MARK: - private properties
        
    private let alertTypesAccessor = AlertTypesAccessor()

    /// the alerttype being edited - will only be used initially to initialize the temp properties used locally, and in the end to update the alerttype - if nil then it's about creating a new alertType
    private var alertTypeAsNSObject: AlertType?
    
    // MARK:- alerttype temp properties
    
    // following properties are used to temporary store alertType attributes which can be modified. The actual update of the alertType being processed will be done only when the user clicks the done button
    private var enabled = ConstantsDefaultAlertTypeSettings.enabled
    private var name: String? = nil
    private var overrideMute = ConstantsDefaultAlertTypeSettings.overrideMute
    private var snooze = ConstantsDefaultAlertTypeSettings.snooze
    private var snoozePeriod = ConstantsDefaultAlertTypeSettings.snoozePeriod
    private var vibrate = ConstantsDefaultAlertTypeSettings.vibrate
    private var soundName = ConstantsDefaultAlertTypeSettings.soundName
        
    func configure(alertType: AlertType?) {
        self.alertTypeAsNSObject = alertType
        
        // configure local temp alert type properties if alertType not nil - if alertType is nil then this viewcontroller is opened to create a ne alertType, in that case default values are used
        if let alertType = alertType {
            enabled = alertType.enabled
            name = alertType.name
            overrideMute = alertType.overridemute
            snooze = alertType.snooze
            snoozePeriod = alertType.snoozeperiod
            vibrate = alertType.vibrate
            soundName = alertType.soundname
        }
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Texts_AlertTypeSettingsView.editAlertTypeScreenTitle
        
        setupView()
    }
    
    // MARK: - View Methods
    
    private func setupView() {
        if let tableView = tableView {
            tableView.dataSource = self
            tableView.delegate = self
            tableView.indicatorStyle = .white
        }
    }
    
    /// to do when user cliks done button
    private func doneButtonAction() {
        if name == nil {
            saveNewAlertType()
            
        } else {
            updateAlertType()
        }
    }
    
    private func saveNewAlertType() {
        let dialog = PopupDialog(
            title: Texts_AlertTypeSettingsView.alertTypeName,
            message: nil,
            keyboardType: .default,
            text: nil,
            placeHolder: nil,
            actionTitle: R.string.common.save(),
            dismissOnActionButtonTap: false
        ) {
            dialog, text in
            
            if text.isEmpty {
                dialog.shake()
                return
            }
            
            var hasDuplicatedName = false
            // first check if name is a unique name
            for alertTypeAlreadyStored in self.alertTypesAccessor.getAllAlertTypes() {
                // if name == alertTypeAlreadyStored.name and alertTypeAlreadyStored is not the same object as alertTypeAsNSObject then not ok
                if alertTypeAlreadyStored.name == text {
                    hasDuplicatedName = true
                    break
                }
            }
            
            if hasDuplicatedName {
                dialog.shake()
                
                self.view.makeToast(R.string.alertTypesSettingsView.alertTypeNameAlreadyExists(), duration: 2, position: .bottom)
                return
            }
            
            dialog.dismiss()
            
            self.alertTypeAsNSObject = AlertType(
                enabled: self.enabled,
                name: text,
                overrideMute: self.overrideMute,
                snooze: self.snooze,
                snoozePeriod: Int(self.snoozePeriod),
                vibrate: self.vibrate,
                soundName: self.soundName,
                alertEntries: nil,
                nsManagedObjectContext: CoreDataManager.shared.mainManagedObjectContext
            )
            
            // save the alerttype
            CoreDataManager.shared.saveChanges()
            
            // go back to alerttypes settings screen
            self.performSegue(withIdentifier: UnwindSegueIdentifiers.unwindToAlertTypesSettingsViewController.rawValue,
                              sender: self)
        }
        
        present(dialog, animated: true)
    }
    
    private func updateAlertType() {
        guard let alertTypeAsNSObject = alertTypeAsNSObject, let name = name else {
            return
        }

        // first check if name is a unique name
        for alertTypeAlreadyStored in alertTypesAccessor.getAllAlertTypes() {
            // if name == alertTypeAlreadyStored.name and alertTypeAlreadyStored is not the same object as alertTypeAsNSObject then not ok
            if alertTypeAlreadyStored.name == name && alertTypeAlreadyStored != alertTypeAsNSObject {
                
                // define and present alertcontroller, this will show message and an ok button, without action when clicking ok
                let alert = PopupDialog(title: Texts_Common.warning,
                                        message: R.string.alertTypesSettingsView.alertTypeNameAlreadyExists(),
                                        actionTitle: R.string.common.common_Ok(),
                                        actionHandler: nil)
                
                present(alert, animated: true, completion: nil)
                
                return
            }
        }
        
        alertTypeAsNSObject.name = name
        alertTypeAsNSObject.enabled = enabled
        alertTypeAsNSObject.overridemute = overrideMute
        alertTypeAsNSObject.snooze = snooze
        alertTypeAsNSObject.snoozeperiod = snoozePeriod
        alertTypeAsNSObject.vibrate = vibrate
        alertTypeAsNSObject.soundname = soundName
        
        // save the alerttype
        CoreDataManager.shared.saveChanges()
        
        // go back to alerttypes settings screen
        performSegue(withIdentifier: UnwindSegueIdentifiers.unwindToAlertTypesSettingsViewController.rawValue, sender: self)
    }
    
    /// check if soundPlayer is playing and if yes stop it (might be that an alert sound is playing and that it will stop here althought it shouldn't - bad luck
    private func stopSoundPlayerIfPlaying() {
        if SoundPlayer.shared.isPlaying() {
            SoundPlayer.shared.stopPlaying()
        }
    }
}

extension AlertTypeSettingsViewController: UITableViewDataSource, UITableViewDelegate {
        
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.textColor = ConstantsUI.tableViewHeaderTextColor
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        // section 1 is the delete tableview cell, return 1 to hide the delete row
        
        // the type is used by alert entries
        if let alertEntries = alertTypeAsNSObject?.alertEntries, alertEntries.count > 0 {
            return 1
        }
        
        // create a new type
        if alertTypeAsNSObject == nil {
            return 1
        }
        
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            // adding a new type, ask user to input name when done button clicked
            if name == nil {
                return Setting.allCases.count - 1
            }
            return Setting.allCases.count
            
        } else {
            // section 1 is the delete section
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "tableCellDelete") ?? DeleteTableViewCell(style: .default, reuseIdentifier: "tableCellDelete")
            return cell
        }
        
        // section 0
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell") ?? UITableViewCell(style: .value1, reuseIdentifier: "tableCell")
        cell.textLabel?.textColor = ConstantsUI.tableTitleColor
        cell.detailTextLabel?.textColor = ConstantsUI.tableDetailTextColor
        
        guard let setting = Setting(rawValue: indexPath.row) else {
            fatalError("AlertTypeSettingsViewController cellForRowAt, Unexpected setting")
        }
        
        // default value for accessoryView is nil
        cell.accessoryView = nil
        cell.accessoryType = .none

        // configure the cell depending on setting
        switch setting {
            
        case .name:
            cell.textLabel?.text = Texts_AlertTypeSettingsView.alertTypeName
            cell.detailTextLabel?.text = name

        case .enabled:
            cell.textLabel?.text = Texts_AlertTypeSettingsView.alertTypeEnabled
            cell.detailTextLabel?.text = nil
            cell.accessoryView = UISwitch(isOn: enabled) {
                (isOn: Bool) in
                self.enabled = isOn
                tableView.reloadSections(IndexSet(integer: 0), with: .none)
            }
            
        case .vibrate:
            cell.textLabel?.text = Texts_AlertTypeSettingsView.alertTypeVibrate
            cell.detailTextLabel?.text = nil
            cell.accessoryView = UISwitch(isOn: vibrate) {
                (isOn: Bool) in
                self.vibrate = isOn
                tableView.reloadRows(at: [IndexPath(row: Setting.vibrate.rawValue, section: 0)], with: .none) // just for case where status of switch is nog aligned with value
            }
            
        case .snoozeViaNotification:
            cell.textLabel?.text = Texts_AlertTypeSettingsView.alertTypeSnoozeViaNotification
            cell.detailTextLabel?.text = nil
            cell.accessoryView = UISwitch(isOn: snooze) {
                (isOn: Bool) in
                self.snooze = isOn
                tableView.reloadRows(at: [IndexPath(row: Setting.snoozeViaNotification.rawValue, section: 0)], with: .none) // just for case where status of switch is nog aligned with value
            }
            
        case .defaultSnoozePeriod:
            cell.textLabel?.text = R.string.alertTypesSettingsView.alerttypesettingsview_defaultsnoozeperiod()
            cell.detailTextLabel?.text = R.string.common.howManyMinutes(Int(snoozePeriod))
            
        case .soundName:
            cell.textLabel?.text = Texts_AlertTypeSettingsView.alertTypeSound
            cell.detailTextLabel?.text = soundName != nil ? soundName! == "" ? Texts_AlertTypeSettingsView.alertTypeNoSound : soundName! : Texts_AlertTypeSettingsView.alertTypeDefaultIOSSound
            
        case .overridemute:
            cell.textLabel?.text = Texts_AlertTypeSettingsView.alertTypeOverrideMute
            cell.detailTextLabel?.text = nil
            cell.accessoryView = UISwitch(isOn: overrideMute) {
                (isOn: Bool) in
                self.overrideMute = isOn
                tableView.reloadRows(at: [IndexPath(row: Setting.overridemute.rawValue, section: 0)], with: .none) // just for case where status of switch is nog aligned with value
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // the delete section
        
        if indexPath.section == 1 {
            // delete the alerttype if one exists
            if let alertTypeAsNSObject = alertTypeAsNSObject {
                // first ask user if ok to delete and if yes delete
                let alert = PopupDialog(
                    title: R.string.common.pleaseConfirm(),
                    message: R.string.alertTypesSettingsView.confirmdeletionalerttype(alertTypeAsNSObject.name),
                    actionTitle: R.string.common.delete(),
                    actionHandler: {
                        CoreDataManager.shared.mainManagedObjectContext.delete(alertTypeAsNSObject)
                        CoreDataManager.shared.saveChanges()
                        // go back to alerttypes settings screen
                        self.performSegue(withIdentifier: UnwindSegueIdentifiers.unwindToAlertTypesSettingsViewController.rawValue, sender: self)
                    },
                    cancelTitle: R.string.common.common_cancel()
                )
                
                present(alert, animated: true, completion: nil)
                
            } else {
                // go back to alerttypes settings screen
                performSegue(withIdentifier: UnwindSegueIdentifiers.unwindToAlertTypesSettingsViewController.rawValue, sender: self)
            }
            return
        }
        
        guard let setting = Setting(rawValue: indexPath.row) else { fatalError("AlertTypeSettingsViewController didSelectRowAt, Unexpected setting") }
        
        // configure the cell depending on setting
        switch setting {
            
        case .name:
            let dialog = PopupDialog(
                title: Texts_AlertTypeSettingsView.alertTypeName,
                message: nil,
                keyboardType: .default,
                text: name,
                placeHolder: nil,
                actionTitle: R.string.common.save(),
                dismissOnActionButtonTap: false
            ) {
                dialog, text in
                
                if text.isEmpty {
                    dialog.shake()
                    return
                }
                
                for alertTypeAlreadyStored in self.alertTypesAccessor.getAllAlertTypes() {
                    if alertTypeAlreadyStored.name == text && alertTypeAlreadyStored != self.alertTypeAsNSObject {
                        // duplicated name
                        dialog.shake()
                        return
                    }
                }
                
                dialog.dismiss()
                
                self.name = text
                tableView.reloadRows(at: [IndexPath(row: Setting.name.rawValue, section: 0)], with: .none)
            }
            present(dialog, animated: true)
            
        case .enabled:
            break
            
        case .vibrate:
            break
            
        case .snoozeViaNotification:
            break
            
        case .defaultSnoozePeriod:
            let snoozeMinutes = AlertManager.shared.snoozeValueMinutes
            var selectedRow: Int?
            
            for (i, snoozeMinute) in snoozeMinutes.enumerated() {
                if snoozeMinute == snoozePeriod {
                    selectedRow = i
                    break
                }
            }
            
            let pickerViewData = PickerViewDataBuilder(
                data:  AlertManager.shared.snoozeValueStrings,
                actionHandler: {
                    index, rowData in
                    
                    self.snoozePeriod = Int16(snoozeMinutes[index])
                    tableView.reloadRows(at: [IndexPath(row: Setting.defaultSnoozePeriod.rawValue, section: 0)], with: .none)
                }
            )
                .title(R.string.alertTypesSettingsView.alerttypesettingsview_defaultsnoozeperiod())
                .selectedRow(selectedRow)
                .build()
            
            BottomSheetPickerViewController.show(in: self, pickerViewData: pickerViewData)
            
        case .soundName:
            // create array of all sounds and sound filenames, inclusive default ios sound and also empty string, which is "no sound"
            var sounds = ConstantsSounds.allSoundsBySoundNameAndFileName()
            sounds.soundNames.insert(Texts_AlertTypeSettingsView.alertTypeDefaultIOSSound, at: 0)
            sounds.soundNames.insert(Texts_AlertTypeSettingsView.alertTypeNoSound, at: 0)
            
            // find index of current soundName
            var selectedRow = 0 // this corresponds to no sound
            if soundName == nil {
                selectedRow = 1// default ios sound is on position 1
                
            } else {
                for (index, soundNameInList) in sounds.soundNames.enumerated() {
                    if soundNameInList == soundName {
                        selectedRow = index
                        break
                    }
                }
            }
            
            // configure pickerViewData
            let pickerViewData = PickerViewData(
                withTitle: Texts_AlertTypeSettingsView.alertTypePickSoundName,
                withSubTitle: nil,
                withData: sounds.soundNames,
                selectedRow: selectedRow,
                withPriority: nil,
                actionButtonText: nil, onActionClick: {
                    (_ index: Int, _) in
                    
                    // soundPlayer might still be playing, stop  it now
                    self.stopSoundPlayerIfPlaying()
                    
                    if index == 1 {
                        // default iOS sound was selected, set to nil
                        self.soundName = nil
                        
                    } else if index == 0 {
                        // no sound to play
                        self.soundName = ""
                        
                    } else {
                        self.soundName = sounds.soundNames[index]
                    }
                    tableView.reloadRows(at: [IndexPath(row: Setting.soundName.rawValue, section: 0)],
                                         with: .none)
                },
                onCancelClick: {
                    // soundPlayer might still be playing, stop  it now
                    self.stopSoundPlayerIfPlaying()
                },
                didSelectRowHandler: {(_ index: Int) in
                    
                    // user scrolling through the sounds, a sound is selected (but ok not pressed yet), play the sound
                    if index == 0 || index == 1 {
                        // if no sound or default iOS selected, then no sound will not be played - but also stop playing sound
                        self.stopSoundPlayerIfPlaying()
                        
                    } else {
                        // stop playing
                        self.stopSoundPlayerIfPlaying()
                        
                        // play the selected sound
                        SoundPlayer.shared.playSound(soundFileName: sounds.fileNames[index - 2])
                    }
                }
            )
            
            BottomSheetPickerViewController.show(in: self, pickerViewData: pickerViewData)

        case .overridemute:
            break // status is changed only when clicking the switch, not the row
        }
    }
}
    
/// defines perform segue identifiers used within AlertTypeSettingsViewController - there's only one at the moment, but there could be more in the future, that's why it's an enum
extension AlertTypeSettingsViewController {
    
    public enum SegueIdentifiers:String {
        
        /// to go from alerttypes settings screen to alert type settings screen
        case alertTypesToAlertTypeSettings = "alertTypesToAlertTypeSettings"
        
    }
    
    private enum UnwindSegueIdentifiers:String {
        
        /// to go back from alerttype settings screen to alerttypes settings screen
        case unwindToAlertTypesSettingsViewController = "unwindToAlertTypesSettingsViewController"
    }
}
