//
//  ComplicationController.swift
//  WatchApp WatchKit Extension
//
//  Created by Liu Xudong on 2021/10/29.
//

import ClockKit
import WatchKit

class ComplicationController: NSObject, CLKComplicationDataSource {
	
	static func reload() {
		let server = CLKComplicationServer.sharedInstance()
		for complication in server.activeComplications ?? [] {
			server.reloadTimeline(for: complication)
		}
	}
	// MARK: - Complication Configuration

	func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
		let descriptors = [
			CLKComplicationDescriptor(identifier: "complication_text", displayName: Constants.DisplayName, supportedFamilies: [.circularSmall, .modularSmall, .modularLarge, .utilitarianSmall, .utilitarianLarge, .extraLarge, .graphicCorner, .graphicCircular, .graphicBezel, .graphicExtraLarge]),
			CLKComplicationDescriptor(identifier: "complication_graphicRectangular", displayName: Constants.DisplayName, supportedFamilies: [.graphicRectangular])
			// Multiple complication support can be added here with more descriptors
		]
		
		// Call the handler with the currently supported complication descriptors
		handler(descriptors)
	}

	// MARK: - Timeline Configuration
	
	func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
		// Call the handler with the last entry date you can currently provide or nil if you can't support future timelines
		handler(Date().addingTimeInterval(Constants.DataValidTimeInterval))
	}
    
	// MARK: - Timeline Population
	
	func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
		// Call the handler with the current timeline entry
		createTimelineEntry(for: complication, date: Date()) { entry in
			handler(entry)
		}
	}
	
	func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
		// Call the handler with the timeline entries after the given date
		handler(nil)
	}
	
	func getPlaceholderTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
		let dateProvider = CLKTimeTextProvider(date: Date())
		let text = "---"
		let textProvider = CLKSimpleTextProvider(text: text, shortText: text)
		
		let imageProvider = CLKFullColorImageProvider(fullColorImage: self.getImage(from: text) ?? UIImage(named: "128")!)

		let template = getTemplate(for: complication, dateProvider: dateProvider, textProvider: textProvider, imageProvider: imageProvider)
		handler(template)
	}
}


extension ComplicationController {
    
	func createTimelineEntry(for complication: CLKComplication, date: Date, completion: @escaping ((CLKComplicationTimelineEntry?) -> Void)) {
		PhoneCommunicator.shared.requestLatest { result in
			if let result = result {
				let dateProvider = CLKTimeTextProvider(date: result.0)
				let text = Date().timeIntervalSince(result.0) > Constants.DataValidTimeInterval ? "---" : result.1
				let textProvider = CLKSimpleTextProvider(text: text, shortText: text)
				
				let imageProvider = CLKFullColorImageProvider(fullColorImage: self.getImage(from: text) ?? UIImage())

				let template: CLKComplicationTemplate? = self.getTemplate(for: complication,
                                                                          dateProvider: dateProvider,
                                                                          textProvider: textProvider,
                                                                          imageProvider: imageProvider)
                
				if let template = template {
					completion(CLKComplicationTimelineEntry(date: date, complicationTemplate: template))
                    
				} else {
					completion(nil)
				}
                
			} else {
				completion(nil)
			}
		}
	}
    
	func getTemplate(for complication: CLKComplication,
					 dateProvider: CLKTimeTextProvider,
					 textProvider: CLKSimpleTextProvider,
					 imageProvider: CLKFullColorImageProvider
	) -> CLKComplicationTemplate? {
		var template: CLKComplicationTemplate?
		switch complication.family {
		case .circularSmall:
			template = CLKComplicationTemplateCircularSmallSimpleText(textProvider: textProvider)
		case .modularSmall:
			template = CLKComplicationTemplateModularSmallSimpleText(textProvider: textProvider)
		case .modularLarge:
			template = CLKComplicationTemplateModularLargeTallBody(headerTextProvider: dateProvider, bodyTextProvider: textProvider)
		case .utilitarianSmall:
			template = CLKComplicationTemplateUtilitarianSmallFlat(textProvider: textProvider, imageProvider: nil)
		case .utilitarianLarge:
			template = CLKComplicationTemplateUtilitarianLargeFlat(textProvider: textProvider)
		case .extraLarge:
			template = CLKComplicationTemplateExtraLargeSimpleText(textProvider: textProvider)
		case .graphicCorner:
			template = CLKComplicationTemplateGraphicCornerStackText(innerTextProvider: dateProvider, outerTextProvider: textProvider)
		case .graphicCircular:
			template = CLKComplicationTemplateGraphicCircularStackText(line1TextProvider: dateProvider, line2TextProvider: textProvider)
		case .graphicBezel:
			let circular = CLKComplicationTemplateGraphicCircularStackText(line1TextProvider: CLKSimpleTextProvider(text: ""), line2TextProvider: textProvider)
			template = CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: circular, textProvider: dateProvider)
		case .graphicRectangular: // ?
			template = CLKComplicationTemplateGraphicRectangularLargeImage(textProvider: dateProvider, imageProvider: imageProvider)
		case .graphicExtraLarge:
			template = CLKComplicationTemplateGraphicExtraLargeCircularStackText(line1TextProvider: dateProvider, line2TextProvider: textProvider)
		default:
			break
		}
		return template
	}
}


extension ComplicationController {
    
	func getImage(from text: String) -> UIImage? {
		func imageSize() -> CGSize {
			switch WKInterfaceDevice.current().screenBounds.width {
			case 198...:
				return CGSize(width: 178.5, height: 56)
			case 184...:
				return CGSize(width: 171, height: 54)
			case 176...:
				return CGSize(width: 159, height: 50)
			default:
				return CGSize(width: 150, height: 47)
			}
		}
		let size = imageSize()
		let maxWidth: CGFloat = imageSize().width
		let maxHeight: CGFloat = imageSize().height
		UIGraphicsBeginImageContextWithOptions(size, false, 0)
		
		if #available(watchOS 9.0, *) {
		} else {
			let context = UIGraphicsGetCurrentContext()
			context?.setFillColor(UIColor.black.cgColor)
			context?.fill([CGRect.init(origin: .zero, size: size)])
		}
		
		let font = UIFont.monospacedSystemFont(ofSize: 32, weight: .medium)
		let textStyle = NSMutableParagraphStyle()
		textStyle.alignment = NSTextAlignment.left
		let textColor = UIColor.white
		let attributes = [NSAttributedString.Key.font:font,
						  NSAttributedString.Key.paragraphStyle:textStyle,
						  NSAttributedString.Key.foregroundColor:textColor]

		//vertically center (depending on font)
		let text_h = font.lineHeight
		let text_y = (maxHeight - text_h)/2
		let text_rect = CGRect(x: 0, y: text_y, width: maxWidth, height: text_h)
		text.draw(in: text_rect, withAttributes: attributes)
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return image
	}
}
