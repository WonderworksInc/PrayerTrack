//
//  PrayerListView.swift
//  Prayer
//
//  Created by Ben on 3/28/20.
//  Copyright © 2020 Ben. All rights reserved.
//

import SwiftUI

struct PrayerListViewSelected: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode
    @Binding var rkmanager: RKManager
    @FetchRequest(
        entity: DateEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \DateEntity.dateAttribute, ascending: true)]
    ) var dates: FetchedResults<DateEntity>
    
    @Binding var showingCalendar: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Button(
                    action: {self.showingCalendar = true; self.presentationMode.wrappedValue.dismiss()},
                    label: {Text("Select new date")}
                )
                Section(
                    header: Text("Prayers answered on this date"),
                    content: {
                        if (nil == getDateEntity() || getDateEntity()!.prayersAnswered.isEmpty)
                        {
                            //Text("No prayers answered on this date")
                        }
                        else
                        {
                            List{
                                ForEach(getDateEntity()!.prayersAnswered, id: \.id,
                                    content: {prayer in
                                        NavigationLink(destination: PrayerView(prayer: prayer),
                                            label: {
                                                VStack(alignment: .leading){
                                                    Text(prayer.title)
                                                    .font(.headline)
                                                    if (nil != prayer.personRelationship)
                                                    {
                                                        Text(prayer.personRelationship!.name)
                                                        .foregroundColor(.secondary)
                                                    }
                                                }
                                            }
                                        )
                                    }
                                )
                            }
                        }
                    }
                )
                Section(
                    header: Text("Prayers prayed on this date"),
                    content: {
                        if (nil == getDateEntity() || getDateEntity()!.prayersPrayed.isEmpty)
                        {
                            //Text("No prayers prayed on this date")
                        }
                        else
                        {
                            List{
                                ForEach(getDateEntity()!.prayersPrayed, id: \.id,
                                    content: {prayer in
                                        NavigationLink(destination: PrayerView(prayer: prayer),
                                            label: {
                                                VStack(alignment: .leading){
                                                    Text(prayer.title)
                                                    .font(.headline)
                                                    if (nil != prayer.personRelationship)
                                                    {
                                                        Text(prayer.personRelationship!.name)
                                                        .foregroundColor(.secondary)
                                                    }
                                                }
                                            }
                                        )
                                    }
                                )
                            }
                        }
                    }
                )
            }
            .navigationBarTitle(getDateString())
        }
    }
    
    func getDateEntity() -> DateEntity?
    {
        return dates.first(where: {date_entity in date_entity.date.ymd == getDate().ymd})
    }
//    func deletePrayers(at offsets: IndexSet) {
//        for offset in offsets{
//            let prayer = date.prayers[offset]
//            
//            for prayed_on_date in prayer.dates
//            {
//                prayer.removeFromDatesRelationship(prayed_on_date)
//                
//                let nothing_prayed_on_date = prayed_on_date.prayers.isEmpty
//                if nothing_prayed_on_date
//                {
//                    moc.delete(prayed_on_date)
//                }
//            }
//            
//            moc.delete(prayer)
//        }
//        
//        if moc.hasChanges
//        {
//            do
//            {
//                try moc.save(); moc.refreshAllObjects()
//            }
//            catch
//            {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                let nserror = error as NSError
//                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
//            }
//        }
//    }

    func getDate() -> Date
    {
        return rkmanager.selectedDate ?? Date()
    }

    func getDateString() -> String
    {
        let date_formatter = DateFormatter()
        // .full means "Sunday, March 22, 2020", for example.
        date_formatter.dateStyle = .medium
        // Don't display the time because this prayer tracker tracks only dates.
        date_formatter.timeStyle = .none
        return date_formatter.string(from: getDate())
    }
}
