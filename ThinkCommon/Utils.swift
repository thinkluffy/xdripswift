//
//  Utils.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/3/30.
//  Copyright © 2020 thinkyeah. All rights reserved.
//
import UIKit
import SwiftyJSON
import CommonCrypto
import AdSupport
import StoreKit

public class Utils {
    
    private static let log = Log(type: Utils.self)
    
    private init() {
        
    }
    
    public static func imageFromLayer(layer: CALayer) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, layer.isOpaque, 0)
        var outputImage: UIImage? = nil
        if let context = UIGraphicsGetCurrentContext() {
            layer.render(in: context)
            outputImage = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        
        return outputImage
    }
    
    public static func prepareDir(forFile filePath: URL) -> Bool {
        do {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: filePath.deletingLastPathComponent().path, isDirectory: &isDir) {
                return isDir.boolValue
            }
            
            try FileManager.default.createDirectory(at: filePath.deletingLastPathComponent(), withIntermediateDirectories: true)
            return true
            
        } catch {
            Utils.log.e("Fail to parepare dir, \(error)")
            return false
        }
    }
    
    
    public static func jsonFromFile(_ fileUrl: URL) -> JSON? {
        do {
            let data = try Data(contentsOf: fileUrl)
            return try JSON(data: data)
            
        } catch {
            Utils.log.e("Fail to load data from json, \(fileUrl), error: \(error)")
            return nil
        }
    }
    
    public static func jsonToFile(json: JSON, fileUrl: URL) -> Bool {
        do {
            let data = try json.rawData(options: [.prettyPrinted])
            try data.write(to: fileUrl, options: [.atomicWrite])
            
        } catch {
            Utils.log.e("Fail to write json to file, \(fileUrl), error: \(error)")
            return false
        }
        return true
    }
    
    public static func lastModifiedTimeOfFile(fileUrl: URL) -> Date? {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: fileUrl.path)
            return attr[FileAttributeKey.modificationDate] as? Date
            
        } catch {
            Utils.log.e("Fail to get modified time, path: \(fileUrl), error: \(error)")
            return nil
        }
    }
    
    public static func clearFolder(rootPath: URL, removeDir: Bool = false) -> Bool {
        var ret = true
        do {
            let files = try FileManager.default.contentsOfDirectory(at: rootPath, includingPropertiesForKeys: nil)
            for f in files {
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: f.path, isDirectory: &isDir) && isDir.boolValue { // dir
                    if !clearFolder(rootPath: f, removeDir: removeDir) {
                        ret = false
                    }
                    
                    if removeDir {
                        try FileManager.default.removeItem(at: f)
                    }
                    
                } else { // file
                    try FileManager.default.removeItem(at: f)
                }
            }
            
        } catch {
            Utils.log.e("Fail to remove file, \(error)")
            ret = false
        }
        return ret
    }
    
    /// return the farest point and distance
    public static func findFarthestPoint(from: CGPoint, toPoints: CGPoint ...) -> (CGPoint, CGFloat) {
        var farestDistance: CGFloat = 0.0
        var farestPoint: CGPoint?
        for to in toPoints {
            let deltaX = to.x - from.x
            let deltaY = to.y - from.y
            let distance = deltaX * deltaX + deltaY * deltaY
            if farestDistance < distance {
                farestDistance = distance
                farestPoint = to
            }
        }
        return (farestPoint!, CGFloat(sqrtf(Float(farestDistance))))
    }
    
    public static func openAppReview(appId: String) {
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
            
        } else {
            guard let url = URL(string: "itms-apps://itunes.apple.com/app/\(appId)?action=write-review"),
                UIApplication.shared.canOpenURL(url) else {
                    return
            }
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    public static func romanNumber(of decimal: Int) -> String? {
        let nums = ["Ⅰ", "Ⅱ", "Ⅲ", "Ⅳ", "Ⅴ", "Ⅵ", "Ⅶ", "Ⅷ", "Ⅸ", "Ⅹ"]
        let index = decimal - 1
        guard index >= 0, index < nums.count else {
            return nil
        }
        return nums[index]
    }
}

extension UIColor {
    
    private static let log = Log(type: UIColor.self)
    
    public var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }
    
    public var grayInt: Int {
        let (r, g, b, _) = rgba
        return (Int) ((r * 0.3 + g * 0.59 + b * 0.11) * 255)
    }
    
    public var rgbaInt: Int {
        let (r, g, b, a) = rgba
        let iRed = Int(r * 255.0)
        let iGreen = Int(g * 255.0)
        let iBlue = Int(b * 255.0)
        let iAlpha = Int(a * 255.0)
        
        //  (Bits 24-31 are alpha, 16-23 are red, 8-15 are green, 0-7 are blue).
        return (iAlpha << 24) + (iRed << 16) + (iGreen << 8) + iBlue
    }
    
    /// 255, 255, 255 -> White;  255, 0, 0 -> Red
    public static func rgba(_ redInt: Int, _ greenInt: Int, _ blueInt: Int, _ alphaInt: Int = 255) -> UIColor {
        return UIColor(red: CGFloat(redInt) / 255.0,
                       green: CGFloat(greenInt) / 255.0,
                       blue: CGFloat(blueInt) / 255.0,
                       alpha: CGFloat(alphaInt) / 255.0)
    }
    
    public static func hex(_ hex: Int) -> UIColor {
        return UIColor.rgba((hex >> 16) & 0xFF, (hex >> 8) & 0xFF, hex & 0xFF, (hex >> 24) & 0xFF)
    }
    
    public static func hex(hexStr: String) -> UIColor? {
        var str = hexStr.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if str.hasPrefix("#") {
            str.remove(at: str.startIndex)
        }
        
        if str.count == 6 {
            str = "FF" + str
        }
        
        guard str.count == 8 else {
            log.e("Unexpected hex string: \(hexStr)")
            return nil
        }
        
        var rgbValue: UInt32 = 0
        Scanner(string: str).scanHexInt32(&rgbValue)
        let rbgInt = Int(rgbValue)
        
        return .hex(rbgInt)
    }
}

extension Date {
    
    public static var minuteInSeconds: Double {
        60
    }
    
    public static var hourInSeconds: Double {
        minuteInSeconds * 60
    }
    
    public static var dayInSeconds: Double {
        hourInSeconds * 24
    }
	
	public static var halfDayInSeconds: Double {
		hourInSeconds * 12
	}
}

extension URL {
    
    public func appendingParameter(name: String, value: String) -> URL {
        var components = URLComponents(string: absoluteString)!
        if components.queryItems == nil {
            components.queryItems = [
                URLQueryItem(name: name, value: value)
            ]
            
        } else {
            components.queryItems?.append(URLQueryItem(name: name, value: value))
        }
        return components.url!
    }
    
    public func queryParameter(_ param: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else {
            return nil
        }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
}

extension UIProgressView {
    
    var barHeight : CGFloat {
        get {
            return transform.d * 2.0
        }
        set {
            // 2.0 Refers to the default height of 2
            let heightScale = newValue / 2.0
            let c = center
            transform = CGAffineTransform(scaleX: 1.0, y: heightScale)
            center = c
        }
    }
}

extension String {
    
    func boundingWidth(with font: UIFont) -> CGFloat {
        let size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: font.lineHeight)
        let preferredRect = (self as NSString).boundingRect(with: size,
                                                            options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                            attributes: [NSAttributedString.Key.font: font],
                                                            context: nil)
        return ceil(preferredRect.width)
    }
    
    var sha256: String {
        let data = Data(utf8)
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }
        
        return hash.map { String(format: "%02hhx", $0) }.joined()
    }
}

extension UITapGestureRecognizer {
    
    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)
        
        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize
        
        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)
        
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x, y: locationOfTouchInLabel.y - textContainerOffset.y)
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        return NSLocationInRange(indexOfCharacter, targetRange)
    }
}

extension CALayer {
    
    static func performWithoutAnimation(_ actionsWithoutAnimation: () -> Void) {
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        actionsWithoutAnimation()
        CATransaction.commit()
    }
    
    static func iterateLayer(_ rootLayer: CALayer, handler: (_ layer: CALayer) -> Void) {
        guard let sublayers = rootLayer.sublayers else {
            return
        }
        
        for layer in sublayers {
            handler(layer)
            iterateLayer(layer, handler: handler)
        }
    }
}

extension UIImage {
    
    var grayScaled: UIImage {
        let ciImage = CIImage(image: self)!
        
        let colorFilter = CIFilter(name: "CIColorControls")!
        colorFilter.setValue(ciImage, forKey: kCIInputImageKey)
        colorFilter.setValue(0.0, forKey: kCIInputBrightnessKey)
        colorFilter.setValue(0.0, forKey: kCIInputSaturationKey)
        colorFilter.setValue(1.1, forKey: kCIInputContrastKey)
        let intermediateImage = colorFilter.outputImage!
        
        let exposureFilter = CIFilter(name: "CIExposureAdjust")!
        exposureFilter.setValue(intermediateImage, forKey: kCIInputImageKey)
        exposureFilter.setValue(0.7, forKey: kCIInputEVKey)
        let output: CIImage! = exposureFilter.outputImage
        
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(output, from: output.extent)!
        
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }
    
    func resizeTo(width newWidth: CGFloat) -> UIImage {
        let scale = newWidth / size.width
        let newHeight = size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

extension UIFont {
    
    func withTraits(_ traits:UIFontDescriptor.SymbolicTraits...) -> UIFont {
        let descriptor = fontDescriptor
            .withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits).union(fontDescriptor.symbolicTraits))
        return UIFont(descriptor: descriptor!, size: 0)
    }
    
    func withoutTraits(_ traits:UIFontDescriptor.SymbolicTraits...) -> UIFont {
        let descriptor = self.fontDescriptor
            .withSymbolicTraits(fontDescriptor.symbolicTraits.subtracting(UIFontDescriptor.SymbolicTraits(traits)))
        return UIFont(descriptor: descriptor!, size: 0)
    }
    
    func bold() -> UIFont {
        return withTraits( .traitBold)
    }
    
    func italic() -> UIFont {
        return withTraits(.traitItalic)
    }
    
    func noItalic() -> UIFont {
        return withoutTraits(.traitItalic)
    }
    
    func noBold() -> UIFont {
        return withoutTraits(.traitBold)
    }
}

extension CGRect {
    
    init(center: CGPoint, radius: CGFloat) {
        self.init(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }
}

extension UIStackView {
    
    func clearArrangedSubviews() {
        for v in arrangedSubviews {
            v.removeFromSuperview()
        }
    }
}

extension UIView {
    
    func roundCorners(radius: CGFloat, corners: CACornerMask? = nil) {
        clipsToBounds = true
        layer.cornerRadius = radius
        
        if let maskedCorners = corners {
            layer.maskedCorners = maskedCorners
        }
    }
}

