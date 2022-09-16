//
//  xDripWatch_Widget.swift
//  xDripWatch Widget
//
//  Created by Liu Xudong on 2022/9/16.
//  Copyright © 2022 zDrip. All rights reserved.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
		let date = Date()
		let placeHolder = SimpleEntry(date: date)
		if context.isPreview {
			completion(placeHolder)
			return
		}
		PhoneCommunicator.shared.requestLatest { result in
			if let result = result {
				let text = Date().timeIntervalSince(result.0) > Constants.DataValidTimeInterval ? "---" : result.1
				completion(SimpleEntry(date: result.0, text: text))
			} else {
				completion(placeHolder)
			}
		}
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
		let entryDate = Calendar.current.date(byAdding: .minute, value: Int(Constants.DataValidTimeInterval), to: currentDate)!
		let entry = SimpleEntry(date: entryDate)
		entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
	var text: String = "---"
}

struct xDripWatch_WidgetEntryView : View {

	@Environment(\.widgetFamily) private var family
	
	var entry: Provider.Entry

    var body: some View {
		switch family {
		case .accessoryRectangular:
			VStack(alignment: .leading) {
				Text(entry.date, style: .time)
					.font(.footnote)
				HStack {
					Text(entry.text)
						.font(.title)
						.bold()
					Spacer()
				 }
			}
			.minimumScaleFactor(0.5)
			.padding(4)
		default:
			VStack {
				Text(entry.date, style: .time)
				Text(entry.text)
				
			}
			.minimumScaleFactor(0.5)
			.padding(4)
		}
		
    }
}

@main
struct xDripWatch_Widget: Widget {
    let kind: String = "xDripWatch_Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            xDripWatch_WidgetEntryView(entry: entry)
        }
        .configurationDisplayName(Constants.DisplayName)
        .description("This is an zDrip complication widget.")
		.supportedFamilies([.accessoryCorner, .accessoryCircular, .accessoryInline, .accessoryRectangular])
    }
}

struct xDripWatch_Widget_Previews: PreviewProvider {
    static var previews: some View {
        xDripWatch_WidgetEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
    }
}
