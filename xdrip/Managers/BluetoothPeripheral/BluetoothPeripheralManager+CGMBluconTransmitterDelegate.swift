import Foundation

extension BluetoothPeripheralManager: CGMBluconTransmitterDelegate {
    
    func received(serialNumber: String?, from cGMBluconTransmitter: CGMBluconTransmitter) {
        
        guard let blucon = findTransmitter(cGMBluconTransmitter: cGMBluconTransmitter) else {return}
        
        // store serial number in blucon object
        blucon.blePeripheral.sensorSerialNumber = serialNumber
        
        CoreDataManager.shared.saveChanges()

    }
    
    func received(batteryLevel: Int, from cGMBluconTransmitter: CGMBluconTransmitter) {
        
        guard let blucon = findTransmitter(cGMBluconTransmitter: cGMBluconTransmitter) else {return}
        
        // store serial number in blucon object
        blucon.batteryLevel = batteryLevel
        
        // no coredatamanager savechanges needed because batterylevel is not stored in coredata

    }
 
    private func findTransmitter(cGMBluconTransmitter: CGMBluconTransmitter) -> Blucon? {
        
        guard let index = bluetoothTransmitters.firstIndex(of: cGMBluconTransmitter), let blucon = bluetoothPeripherals[index] as? Blucon else {return nil}
        
        return blucon
        
    }

}
