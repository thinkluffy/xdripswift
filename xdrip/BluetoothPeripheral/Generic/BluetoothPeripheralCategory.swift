import Foundation

/// categories are M5Stack, CGM, watlaa, ...
enum BluetoothPeripheralCategory: String, CaseIterable {
    
    /// for Dexcom, bubble, MiaoMiao ...
    case CGM = "CGM"
    
    /// returns index in list of BluetoothPeripheralCategory's
    func index() -> Int {
        for (index, type) in BluetoothPeripheralCategory.allCases.enumerated() {
            if type == self {
                return index
            }
        }
        return 0
    }
    
    /// - returns list of bluetooth peripheral type's rawValue,  that have a bluetoothperipheral category, that has withCategory
    /// - so it gives a list of bluetoothperipheral types for a specific bluetoothperipheral category
    static func listOfBluetoothPeripheralTypes(withCategory category: BluetoothPeripheralCategory, isFullFeatureMode: Bool) -> [String] {
        var list = [String]()
        for bluetoothPeripheralType in BluetoothPeripheralType.allCases {
            if bluetoothPeripheralType.category() == category &&
                (isFullFeatureMode || !bluetoothPeripheralType.onlyForFullFeatureMode()) {
                list.append(bluetoothPeripheralType.rawValue)
            }
        }
        return list
    }
}
