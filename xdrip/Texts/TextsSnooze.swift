import Foundation

class TextsSnooze {
    
    static private let filename = "Snooze"
    
    static let not_snoozed: String = {
        return NSLocalizedString("not_snoozed", tableName: filename, bundle: Bundle.main, value: "Not snoozed", comment: "row text for overview snooze. Not snoozed alarm")
    }()
    
    static let snoozed_until: String = {
        return NSLocalizedString("snoozed_until", tableName: filename, bundle: Bundle.main, value: "Snoozed until", comment: "row text for overview snooze. Snoozed alarm, until .. followed by timestamp")
    }()

    static func screenTitle(snoozed: Int, total: Int) -> String {
        return String(format: NSLocalizedString("snooze_screen_title_format", tableName: filename, bundle: Bundle.main, value: "Snoozed Alarms %d/%d", comment: "Title for snooze overview, showing how many alarms are currently snoozed"), snoozed, total)
    }

    static let snoozeUnsnoozedTitle: String = {
        return NSLocalizedString("snooze_unsnoozed_title", tableName: filename, bundle: Bundle.main, value: "Snooze Unsnoozed Alarms", comment: "Bulk action title to snooze alarms that are not currently snoozed")
    }()

    static let snoozeAllTitle: String = {
        return NSLocalizedString("snooze_all_title", tableName: filename, bundle: Bundle.main, value: "Snooze All Alarms Together", comment: "Bulk action title to snooze all alarms with one selected period")
    }()

    static let unSnoozeAllTitle: String = {
        return NSLocalizedString("unsnooze_all_title", tableName: filename, bundle: Bundle.main, value: "Cancel All Snoozes", comment: "Bulk action title to remove all active snoozes")
    }()

    static let confirmUnSnoozeAllTitle: String = {
        return NSLocalizedString("confirm_unsnooze_all_title", tableName: filename, bundle: Bundle.main, value: "Cancel All Snoozes?", comment: "Confirmation title before removing all active snoozes")
    }()

    static let confirmUnSnoozeAllMessage: String = {
        return NSLocalizedString("confirm_unsnooze_all_message", tableName: filename, bundle: Bundle.main, value: "This will cancel every alarm snooze shown here.", comment: "Confirmation message before removing all active snoozes shown in the snooze overview")
    }()

    static func snoozeUnsnoozedPickerSubtitle(unsnoozed: Int) -> String {
        return String(format: NSLocalizedString("snooze_unsnoozed_picker_subtitle_format", tableName: filename, bundle: Bundle.main, value: "Choose a snooze time for alarms without an active snooze (%d). Existing snoozes stay unchanged.", comment: "Subtitle for bulk snooze picker that only affects unsnoozed alarms"), unsnoozed)
    }

    static func snoozeAllPickerSubtitle(total: Int) -> String {
        return String(format: NSLocalizedString("snooze_all_picker_subtitle_format", tableName: filename, bundle: Bundle.main, value: "All %d alarms will restart with the selected snooze time.", comment: "Subtitle for bulk snooze picker that overwrites all snoozes"), total)
    }
    
}
