import Foundation
import UIKit

enum ConstantsUI {
    
    static let tabBarBackgroundColor = UIColor.rgba(8, 12, 29)

    static let mainBackgroundColor = UIColor.rgba(34, 39, 72)

    static let contentBackgroundColor = UIColor.rgba(20, 24, 49)
    
    static let accentRed = UIColor.rgba(234, 45, 100)

    static let glucoseLowColor = UIColor.rgba(233, 127, 57)
    static let glucoseInRangeColor = UIColor.rgba(72, 235, 56)
    static let glucoseHighColor = ConstantsUI.accentRed

    /// color for section titles in grouped table views, example in settings view
    static let tableViewHeaderTextColor = UIColor.lightText
    static let tableTitleColor = UIColor.white
    static let tableDetailTextColor = UIColor.lightText

    /// color to use as background when a row is selected
    static let tableRowSelectedBackgroundColor = UIColor.hex(0xff1A1F3D)
    
    /// color to use for disclosure indicator in settings views
    static let disclosureIndicatorColor = UIColor.gray
    
    /// segmentedControl font size
    static let segmentedControlFont = UIFont.systemFont(ofSize: 11)
    /// segmentedControl background color
    static let segmentedControlBackgroundColor = UIColor.init(white: 0.05, alpha: 1)
    /// segmentedControl border width
    static let segmentedControlBorderWidth: CGFloat = 0.0
    /// segmentedControl font color
    static let segmentedControlNormalTextColor = UIColor.gray
    /// segmentedControl font color when selected
    static let segmentedControlSelectedTextColor = UIColor.black
    /// segmentedControl background color when selected
    static let segmentedControlSelectedTintColor = UIColor.lightGray
    
    /// colors for lock screen button in toolbar
    static let screenLockIconColor = UIColor.gray
    
    /// value label font size when the screen is in normal operation mode
    static let valueLabelFontSizeNormal = UIFont.systemFont(ofSize: 90)
    /// value label font bigger size when the screen is in screen lock mode
    static let valueLabelFontSizeScreenLock = UIFont.systemFont(ofSize: 120)
    
    /// clock label font color. It shouldn't be too white or it could be distracting at night.
    static let clockLabelColor = UIColor.lightGray
    /// clock label font size (ideally should be set to the same as the bigger valueLabel font size
    static let clockLabelFontSize = UIFont.systemFont(ofSize: 120)
    
}
