//
//  ContentView.swift
//  xdrip
//
//  Created by Johan Degraeve on 29/09/2021.
//

import SwiftUI
import CoreData

struct BgReadingView: View {
    
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BgReading.timeStamp, ascending: true)],
        animation: .default)
    private var bgReadings: FetchedResults<BgReading>

    var body: some View {
        
        NavigationView {
            
            List {
                
                ForEach(bgReadings, id: \.self) { bgReading in
                    
                    Text(bgReading.timeStamp, formatter: dateFormatter)
                    
                }
                
            }
            
        }

    }

}

fileprivate let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BgReadingView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
