import Foundation

extension BluetoothPeripheralManager: CGMGNSEntryTransmitterDelegate {
    
    func received(bootLoader: String, from cGMGNSEntryTransmitter: CGMGNSEntryTransmitter) {
        
        guard let gNSEntry = findTransmitter(cGMGNSEntryTransmitter: cGMGNSEntryTransmitter) else {return}
        
        // store bootLoader in gNSEntry object
        gNSEntry.bootLoader = bootLoader
        
        CoreDataManager.shared.saveChanges()
        
    }
    
    func received(firmwareVersion: String, from cGMGNSEntryTransmitter: CGMGNSEntryTransmitter) {
        
        guard let gNSEntry = findTransmitter(cGMGNSEntryTransmitter: cGMGNSEntryTransmitter) else {return}
        
        // store firmwareVersion in gNSEntry object
        gNSEntry.firmwareVersion = firmwareVersion
        
        CoreDataManager.shared.saveChanges()
        
    }
    
    func received(serialNumber: String, from cGMGNSEntryTransmitter: CGMGNSEntryTransmitter) {
        
        guard let gNSEntry = findTransmitter(cGMGNSEntryTransmitter: cGMGNSEntryTransmitter) else {return}
        
        // store serialNumber in gNSEntry object
        gNSEntry.serialNumber = serialNumber
        
        CoreDataManager.shared.saveChanges()
        
    }
    
    private func findTransmitter(cGMGNSEntryTransmitter: CGMGNSEntryTransmitter) -> GNSEntry? {
        
        guard let gNSEntry = bluetoothPeripheral as? GNSEntry else {return nil}
        
        return gNSEntry
        
    }
    
}
