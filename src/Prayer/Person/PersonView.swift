//
//  PersonView.swift
//  Person
//
//  Created by Ben on 3/28/20.
//  Copyright © 2020 Ben. All rights reserved.
//

import SwiftUI

struct NewPrayerForPersonButton: View
{
    @Environment(\.managedObjectContext) var moc
    @State private var showingNewPrayerSheet = false
    @ObservedObject var person: PersonEntity
    
    var body: some View
    {
        Button(
            action: {self.showingNewPrayerSheet = true},
            label: {AddPrayerButtonLabel()})
        .sheet(isPresented: $showingNewPrayerSheet)
        {
            NewPrayerView(personId: self.person.id, isPresented: self.$showingNewPrayerSheet)
            // The sheet doesn't inherit the environment, which is a bug.
            // https://oleb.net/2020/sheet-environment/
            .environment(\.managedObjectContext, self.moc)
        }
    }
}

struct TagAndPrayers
{
    let tag: TagEntity
    let prayers: [PrayerEntity]
}

struct PrayersForPersonList: View
{
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var person: PersonEntity
    
    @Binding var inTodayMode: Bool
    /// Necessary for unknown reason.  Sometimes (and not always), the view won't update when the prayer's
    /// tag changes.  This forces it to update.
    @State private var forceRefresh = false
    
    var body: some View
    {
        let prayers_with_no_tag = person.prayers.filter({($0.tags.isEmpty)})
        
        return List
        {if (forceRefresh || !forceRefresh){
            ForEach(getPrayersByTag(), id: \.tag.id)
            {tag_and_prayers in
                Section(header: Text("\(tag_and_prayers.tag.title)"))
                {
                    ForEach(tag_and_prayers.prayers, id: \.id)
                    {prayer in
                        PrayerListRow(prayer: prayer, inTodayMode: self.$inTodayMode, mode: .person)
                    }
                    .onDelete(perform: {offsets in
                        for offset in offsets
                        {
                            deletePrayer(prayer: tag_and_prayers.prayers[offset])
                        }
                    })
                }
            }
            
            if !prayers_with_no_tag.isEmpty
            {
                Section(header: Text("No tag"))
                {
                    return ForEach(prayers_with_no_tag, id: \.id)
                    {prayer in
                        PrayerListRow(prayer: prayer, inTodayMode: self.$inTodayMode, mode: .person)
                    }
                    .onDelete(perform: {offsets in
                        for offset in offsets
                        {
                            deletePrayer(prayer: prayers_with_no_tag[offset])
                        }
                    })
                }
            }
        }}
        .onAppear(perform: {self.forceRefresh.toggle()})
    }
    
    func getPrayersByTag() -> [TagAndPrayers]
    {
        var prayers_by_tag = Dictionary<TagEntity, [PrayerEntity]>()
        
        for prayer in person.prayers
        {
            if prayer.tags.isEmpty
            {
                continue
            }
            
            for tag in prayer.tags
            {
                if (nil == prayers_by_tag[tag])
                {
                    prayers_by_tag[tag] = []
                }
                
                prayers_by_tag[tag]!.append(prayer)
            }
        }
        
        var array = [TagAndPrayers]()
        for a in prayers_by_tag
        {
            let tag_and_prayers = TagAndPrayers(tag: a.key, prayers: a.value)
            array.append(tag_and_prayers)
        }
        
        return array.sorted(by: {$0.tag.title < $1.tag.title})
    }
}


struct PersonView: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var person: PersonEntity
    @State private var inTodayMode = false
    
    var body: some View
    {
        // Wrap state in local binding variable so that setting can be intercepted.
        // https://www.hackingwithswift.com/books/ios-swiftui/creating-custom-bindings-in-swiftui
        let name = Binding<String>(
            get: {self.person.name},
            set: {self.person.name = $0})
        
        return Form
        {
            // PERSON NAME.
            VStackTextView(top: name, bottom: "Name")
            PrayersForPersonList(person: person, inTodayMode: self.$inTodayMode)
//            //Section(header: Text("Name"), content: {TextField("Name", text: name)})
////                // SAVE BUTTON.
////                Section{Button("Save", action: {self.savePerson(); self.returnToLastView()})}
//            // PRAYERS.
//            Section(header: Text("Prayers"))
//            {
//                // Cannot have the ForEach change count based on a NavigationLink from this view.
//                // That's why prayers are added via sheet instead of NavigationLink.  Dunno why.
//                ForEach(person.prayers, id: \.id)
//                {prayer in
//                    NavigationLink(
//                        destination: PrayerView(prayer: prayer),
//                        label: {Text(prayer.title)})
//                }
//                .onDelete(perform: {self.deletePrayers(at: $0)})
//            }
        }
        .navigationBarTitle(Text(name.wrappedValue), displayMode: .inline)
        .navigationBarItems(trailing: NewPrayerForPersonButton(person: person))
    }
    
    func savePerson()
    {
        //person.prayersRelationship = Set(prayersState) as NSSet
    
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
            deletePrayer(prayer: person.prayers[offset])
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
