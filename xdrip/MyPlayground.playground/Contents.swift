import UIKit

//extension Double {
//
//    func round(toDecimalPlaces: Int) -> Double {
//        let multiplier = pow(10, Double(toDecimalPlaces))
//        return Darwin.round(self * multiplier) / multiplier
//    }
//
//    func mgToMmol() -> Double {
//        self / 18.018018018
//    }
//
//    func mgdlToMmolAndToString(mgdl: Bool) -> String {
//        if mgdl {
//            return String(format: "%.0f", self)
//
//        } else {
//            return String(format: "%.1f", self.mgdlToMmol())
//        }
//    }
//}

let a = 300.0
a.mgdlToMmol().round(toDecimalPlaces: 1)

a.mgdlToMmolAndToString(mgdl: false)
a.mgdlToMmol()
String(format: "%.1f", a.mgdlToMmol())

let b = 40.0
b.mgdlToMmol().round(toDecimalPlaces: 1)
b.mgdlToMmolAndToString(mgdl: false)


String(format: "%.1f", 16.64)
String(format: "%.1f", 16.65)
String(format: "%.1f", 16.66)
String(format: "%.1f", 17.65)
String(format: "%.1f", 0.65)
String(format: "%.1f", 1.65)
