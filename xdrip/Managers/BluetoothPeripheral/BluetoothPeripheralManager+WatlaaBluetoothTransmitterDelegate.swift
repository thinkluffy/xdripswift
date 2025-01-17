import Foundation

extension BluetoothPeripheralManager: WatlaaBluetoothTransmitterDelegate {
    
    func received(serialNumber: String, from watlaaBluetoothTransmitter: WatlaaBluetoothTransmitter) {
        
        guard let watlaa = findTransmitter(watlaaTransmitter: watlaaBluetoothTransmitter) else {return}
        
        // store serial number in miaoMiao object
        watlaa.blePeripheral.sensorSerialNumber = serialNumber
        
        CoreDataManager.shared.saveChanges()

    }
    
    
    func isReadyToReceiveData(watlaaBluetoothTransmitter: WatlaaBluetoothTransmitter) {
        
        // request battery level
        watlaaBluetoothTransmitter.readBatteryLevel()
        
    }
    
    func received(watlaaBatteryLevel: Int, watlaaBluetoothTransmitter: WatlaaBluetoothTransmitter) {
        
        guard let watlaa = bluetoothPeripheral as? Watlaa else {return}
        
        watlaa.watlaaBatteryLevel = watlaaBatteryLevel
        
        CoreDataManager.shared.saveChanges()
        
    }
    
    func received(transmitterBatteryLevel: Int, watlaaBluetoothTransmitter: WatlaaBluetoothTransmitter) {
        
        guard let watlaa = bluetoothPeripheral as? Watlaa else {return}
        
        watlaa.transmitterBatteryLevel = transmitterBatteryLevel
        
        CoreDataManager.shared.saveChanges()
        
    }
    
    private func findTransmitter(watlaaTransmitter: WatlaaBluetoothTransmitter) -> Watlaa? {
        
        guard let watlaa = bluetoothPeripheral as? Watlaa else {return nil}
        
        return watlaa
        
    }
    
}
