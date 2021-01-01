//
//  TagView.swift
//  Tag
//
//  Created by Ben on 3/28/20.
//  Copyright © 2020 Ben. All rights reserved.
//

import SwiftUI

struct PersonAndPrayers
{
    let person: PersonEntity
    let prayers: [PrayerEntity]
}

struct PrayersForTagList: View
{
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var tag: TagEntity
    
    @Binding var inTodayMode: Bool
    
    var body: some View
    {
        let prayers_with_no_person = tag.prayers.filter({(nil == $0.personRelationship)})
        
        return List
        {
            ForEach(getPrayersByPerson(), id: \.person.id)
            {person_and_prayers in
                Section(header: Text("\(person_and_prayers.person.name)"))
                {
                    ForEach(person_and_prayers.prayers, id: \.id)
                    {prayer in
                        PrayerListRow(prayer: prayer, inTodayMode: self.$inTodayMode, mode: .person)
                    }
                    .onDelete(perform: {offsets in
                        for offset in offsets
                        {
                            deletePrayer(prayer: person_and_prayers.prayers[offset])
                        }
                    })
                }
            }
            if !prayers_with_no_person.isEmpty
            {
                Section(header: Text("No one"))
                {
                    return ForEach(prayers_with_no_person, id: \.id)
                    {prayer in
                        PrayerListRow(prayer: prayer, inTodayMode: self.$inTodayMode, mode: .person)
                    }
                    .onDelete(perform: {offsets in
                        for offset in offsets
                        {
                            deletePrayer(prayer: prayers_with_no_person[offset])
                        }
                    })
                }
            }
        }
    }
    
    func getPrayersByPerson() -> [PersonAndPrayers]
    {
        var prayers_by_person = Dictionary<PersonEntity, [PrayerEntity]>()
        
        for prayer in tag.prayers
        {
            if (nil == prayer.personRelationship)
            {
                continue
            }
            
            if (nil == prayers_by_person[prayer.personRelationship!])
            {
                prayers_by_person[prayer.personRelationship!] = []
            }
            
            prayers_by_person[prayer.personRelationship!]!.append(prayer)
        }
        
        var array = [PersonAndPrayers]()
        for a in prayers_by_person
        {
            let person_and_prayers = PersonAndPrayers(person: a.key, prayers: a.value)
            array.append(person_and_prayers)
        }
        return array.sorted(by: {$0.person.name < $1.person.name})
    }
}

struct TagView: View
{
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var tag: TagEntity
    @State private var inTodayMode = false
    
    var body: some View
    {
        // Wrap state in local binding variable so that setting can be intercepted.
        // https://www.hackingwithswift.com/books/ios-swiftui/creating-custom-bindings-in-swiftui
        let title = Binding<String>(
            get: {self.tag.title},
            set: {self.tag.title = $0})
        
        return Form
        {
            VStackTextView(top: title, bottom: "Title")
            PrayersForTagList(tag: tag, inTodayMode: self.$inTodayMode)
            //Section(header: Text("Prayers"))
            //{
//                // Cannot have the ForEach change count based on a NavigationLink from this view.
//                // That's why prayers are added via sheet instead of NavigationLink.  Dunno why.
//                ForEach(tag.prayers, id: \.id)
//                {prayer in
//                    NavigationLink(
//                        destination: PrayerView(prayer: prayer),
//                        label: {Text(prayer.title)})
//                }
//                .onDelete(perform: {self.deletePrayers(at: $0)})
            //    PrayersForTagList(tag: tag, inTodayMode: self.$inTodayMode)
            //}
        }
        .navigationBarTitle(Text(title.wrappedValue), displayMode: .inline)
        //.navigationBarItems(trailing: TodayModeButton(inTodayMode: self.$inTodayMode))
    }
    
    func saveTag()
    {
        //tag.prayersRelationship = Set(prayersState) as NSSet
    
        // SAVE THE PRAYER TO CORE DATA.
        /*if moc.hasChanges
        {
            do
            {
                try moc.save(); moc.refreshAllObjects()
            }
            catch
            {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }*/
    }
    
    func deletePrayers(at offsets: IndexSet)
    {
        for offset in offsets
        {
            deletePrayer(prayer: tag.prayers[offset])
        }
        
        /*if moc.hasChanges
        {
            do
            {
                try moc.save(); moc.refreshAllObjects()
            }
            catch
            {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }*/
    }
    
    func returnToLastView()
    {
        self.presentationMode.wrappedValue.dismiss()
    }
}
