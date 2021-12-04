import Foundation
import CoreData

/// is the same as M5Stack except that isM5StickC (which is an attribute in M5Stack) will be set to true
class M5StickC: M5Stack {
    
    init(address: String, name: String, textColor: M5StackColor, backGroundColor: M5StackColor, rotation: UInt16,
         nsManagedObjectContext: NSManagedObjectContext) {
        
        super.init(address: address,
                   name: name,
                   textColor: textColor,
                   backGroundColor: backGroundColor,
                   rotation: rotation,
                   brightness: 100,
                   nsManagedObjectContext: nsManagedObjectContext)
        
        self.isM5StickC = true
        
    }
}
