import UIKit

final class BluetoothPeripheralNavigationController: UINavigationController {
    
    // MARK:- private properties
    
    /// a bluetoothPeripheralManager
    private weak var bluetoothPeripheralManager: BluetoothPeripheralManaging!
    
    // MARK:- public functions
    
    /// configure
    public func configure(bluetoothPeripheralManager: BluetoothPeripheralManaging) {
        self.bluetoothPeripheralManager = bluetoothPeripheralManager
    }
    
    // MARK: - overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
    }
}

extension BluetoothPeripheralNavigationController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        if let bluetoothPeripheralsViewController = viewController as? BluetoothPeripheralsViewController {
            bluetoothPeripheralsViewController.configure(bluetoothPeripheralManager: bluetoothPeripheralManager)
        }
    }
}

