import UIKit
import PopupDialog

final class SnoozeViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!

    private enum Section {
        static let bulkActions = 0

        static func alertKind(for section: Int) -> AlertKind? {
            guard section > bulkActions else { return nil }
            return AlertKind(forSection: section - 1)
        }
    }

    private enum BulkActionRow: Int, CaseIterable {
        case snoozeUnsnoozed
        case snoozeAll
        case unSnoozeAll
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        updateTitle()
        setupView()
    }

    private func setupView() {
        if let tableView = tableView {
            tableView.dataSource = self
            tableView.delegate = self
            tableView.showsVerticalScrollIndicator = false
        }
    }

    private func updateTitle() {
        let summary = AlertManager.shared.snoozeSummary()
        titleLabel.text = TextsSnooze.screenTitle(snoozed: summary.snoozed, total: summary.total)
    }

    private func reloadDataAndTitle() {
        updateTitle()
        tableView.reloadData()
    }

    private func defaultSnoozeRow() -> Int {
        let defaultSnoozePeriod = Int(ConstantsDefaultAlertTypeSettings.snoozePeriod)
        var defaultRow = 0

        for (index, snoozeValue) in AlertManager.shared.snoozeValueMinutes.enumerated() {
            if snoozeValue > defaultSnoozePeriod {
                break
            }

            defaultRow = index
        }

        return defaultRow
    }

    private func showBulkSnoozePicker(mode: SnoozeBulkMode) {
        let summary = AlertManager.shared.snoozeSummary()
        let title: String
        let subTitle: String

        switch mode {
        case .onlyNotSnoozed:
            title = TextsSnooze.snoozeUnsnoozedTitle
            subTitle = TextsSnooze.snoozeUnsnoozedPickerSubtitle(unsnoozed: summary.total - summary.snoozed)
        case .overwriteAll:
            title = TextsSnooze.snoozeAllTitle
            subTitle = TextsSnooze.snoozeAllPickerSubtitle(total: summary.total)
        }

        let pickerViewData = PickerViewDataBuilder(data: AlertManager.shared.snoozeValueStrings) { [weak self] snoozeIndex, _ in
            let snoozePeriod = AlertManager.shared.snoozeValueMinutes[snoozeIndex]
            AlertManager.shared.snoozeAlerts(mode: mode, snoozePeriodInMinutes: snoozePeriod)
            self?.reloadDataAndTitle()
        }
            .title(title)
            .subTitle(subTitle)
            .selectedRow(defaultSnoozeRow())
            .priority(.high)
            .actionTitle(Texts_Common.Ok)
            .cancelHandler { [weak self] in
                self?.reloadDataAndTitle()
            }
            .build()

        _ = BottomSheetPickerViewController.show(in: self, pickerViewData: pickerViewData)
    }

    private func showUnSnoozeAllConfirmation() {
        let alert = PopupDialog(
            title: TextsSnooze.confirmUnSnoozeAllTitle,
            message: TextsSnooze.confirmUnSnoozeAllMessage,
            actionTitle: TextsSnooze.unSnoozeAllTitle,
            actionHandler: { [weak self] in
                AlertManager.shared.unSnoozeAll()
                self?.reloadDataAndTitle()
            },
            cancelTitle: R.string.common.common_cancel()
        )

        present(alert, animated: true, completion: nil)
    }

    private func configureBulkActionCell(_ cell: UITableViewCell, row: BulkActionRow) {
        let summary = AlertManager.shared.snoozeSummary()
        let snoozedCount = summary.snoozed
        let unsnoozedCount = summary.total - summary.snoozed
        let isEnabled: Bool

        switch row {
        case .snoozeUnsnoozed:
            cell.textLabel?.text = TextsSnooze.snoozeUnsnoozedTitle
            cell.accessoryType = .disclosureIndicator
            isEnabled = unsnoozedCount > 0

        case .snoozeAll:
            cell.textLabel?.text = TextsSnooze.snoozeAllTitle
            cell.accessoryType = .disclosureIndicator
            isEnabled = true

        case .unSnoozeAll:
            cell.textLabel?.text = TextsSnooze.unSnoozeAllTitle
            cell.accessoryType = .none
            isEnabled = snoozedCount > 0
        }

        cell.detailTextLabel?.text = nil
        cell.accessoryView = nil
        if !isEnabled {
            cell.accessoryType = .none
        }
        cell.selectionStyle = isEnabled ? .default : .none
        cell.isUserInteractionEnabled = isEnabled
        cell.textLabel?.textColor = bulkActionTextColor(row: row, isEnabled: isEnabled)
        cell.detailTextLabel?.textColor = ConstantsUI.tableDetailTextColor
    }

    private func bulkActionTextColor(row: BulkActionRow, isEnabled: Bool) -> UIColor {
        guard isEnabled else { return ConstantsUI.tableDetailTextColor }

        switch row {
        case .unSnoozeAll:
            return ConstantsUI.accentRed
        case .snoozeUnsnoozed, .snoozeAll:
            return ConstantsUI.tableTitleColor
        }
    }

    private func configureAlertKindCell(_ cell: UITableViewCell, for indexPath: IndexPath) {
        // alertKind corresponds to section number after the bulk actions section
        guard let alertKind = Section.alertKind(for: indexPath.section) else {
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
        cell.selectionStyle = .default
        cell.isUserInteractionEnabled = true
        cell.textLabel?.textColor = ConstantsUI.tableTitleColor
        cell.detailTextLabel?.textColor = ConstantsUI.tableDetailTextColor

        // uiswitch will be on if currently snoozed, off if currently not snoozed
        cell.accessoryView = UISwitch(isOn: isSnoozed) {
            [weak self] (isOn: Bool) in

            // closure to reload the row after user clicked form on to off, or from off to on and selected a snoozeperiod
            let reloadRow = {
                self?.updateTitle()
                self?.tableView.reloadRows(at: [IndexPath(row: 0, section: indexPath.section)], with: .none)
                self?.tableView.reloadSections(IndexSet(integer: Section.bulkActions), with: .none)
            }

            // changing from off to on. Means user wants to pre-snooze
            if isOn {
                // create and display pickerViewData
                let pickerViewData = AlertManager.shared.createPickerViewData(
                        forAlertKind: alertKind,
                        content: nil,
                        actionHandler: { reloadRow() },
                        cancelHandler: { reloadRow() }
                )

                if let self = self {
                    _ = BottomSheetPickerViewController.show(in: self, pickerViewData: pickerViewData)
                }

            } else {
                // changing from on to off. Means user wants to unsnooze
                AlertManager.shared.unSnooze(alertKind: alertKind)

                reloadRow()
            }
        }
    }
}

// MARK: - Conform to UITableViewDataSource

extension SnoozeViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        // number of sections corresponds to bulk actions plus number of alarm types
        AlertKind.displayOrder.count + 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Section.bulkActions {
            return BulkActionRow.allCases.count
        }

        // just one row per alarm type
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell") ?? UITableViewCell(style: .value1, reuseIdentifier: "tableCell")
        cell.textLabel?.textColor = ConstantsUI.tableTitleColor
        cell.detailTextLabel?.textColor = ConstantsUI.tableDetailTextColor

        if indexPath.section == Section.bulkActions {
            guard let row = BulkActionRow(rawValue: indexPath.row) else {
                fatalError("In SnoozeViewController, cellForRowAt, could not create BulkActionRow")
            }

            configureBulkActionCell(cell, row: row)
        } else {
            configureAlertKindCell(cell, for: indexPath)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == Section.bulkActions {
            return nil
        }

        // alertKind corresponds to section number after the bulk actions section
        guard let alertKind = Section.alertKind(for: section) else {
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

        guard indexPath.section == Section.bulkActions, let row = BulkActionRow(rawValue: indexPath.row) else {
            return
        }

        let summary = AlertManager.shared.snoozeSummary()

        switch row {
        case .snoozeUnsnoozed:
            guard summary.snoozed < summary.total else { return }
            showBulkSnoozePicker(mode: .onlyNotSnoozed)

        case .snoozeAll:
            showBulkSnoozePicker(mode: .overwriteAll)

        case .unSnoozeAll:
            guard summary.snoozed > 0 else { return }
            showUnSnoozeAllConfirmation()
        }
    }
}
