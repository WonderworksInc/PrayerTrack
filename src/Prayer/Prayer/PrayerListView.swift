//
//  PrayerListView.swift
//  Prayer
//
//  Created by Ben on 3/28/20.
//  Copyright © 2020 Ben. All rights reserved.
//

import SwiftUI

struct PrayerPrayedTodayCheckbox: View
{
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var prayer: PrayerEntity
    @FetchRequest(
        entity: DateEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \DateEntity.dateAttribute, ascending: true)]
    ) var dates: FetchedResults<DateEntity>
    
    var body : some View
    {
        Button(
            action: toggle,
            label: {Image(systemName: (prayedToday() ? "checkmark.circle.fill" : "circle")).imageScale(.large).font(.headline)}
        )
    }
    
    func toggle() -> Void
    {
        if prayedToday()
        {
            let today = prayer.datesPrayed.last!
            prayer.removeFromDatesPrayedRelationship(today)
            
            deleteDateIfEmtpy(date: today)
        }
        else
        {
            prayer.addToDatesPrayedRelationship(getOrCreateDateFromDatabase(date: Date()))
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
    
    func getOrCreateDateFromDatabase(date: Date) -> DateEntity
    {
        if let prexisting_date_entity = dates.first(where: {date_entity in date_entity.date.ymd == date.ymd})
        {
            return prexisting_date_entity
        }
        
        let new_date_entity = DateEntity(context: moc)
        new_date_entity.date = date
        return new_date_entity
    }
    
    func prayedToday() -> Bool
    {
        guard let last_date_prayed = prayer.datesPrayed.last else
        {
            return false
        }
        
        return (last_date_prayed.date.ymd == Date().ymd)
    }
}

struct PrayerWithPersonAndTagsListItem: View
{
    @ObservedObject var prayer: PrayerEntity
    let mode: SortPrayersByOption

    var body: some View
    {
        VStack(alignment: .leading)
        {
            if (mode == .title)
            {
                Text(prayer.title)
                .font(.headline)
                if (nil != prayer.personRelationship)
                {
                    Text(prayer.personRelationship!.name)
                    .foregroundColor(.secondary)
                }
            }
            else if (mode == .person)
            {
                Text(prayer.title)
                .font(.headline)
//                HStack
//                {
//                    Text("Tags:")
//                    ForEach(prayer.tags, id: \.id)
//                    {tag in
//                        Text(tag.title)
//                    }
//                }
//                .foregroundColor(.secondary)
            }
            else if (mode == .tag)
            {
                Text(prayer.title)
                .font(.headline)
                if (nil != prayer.personRelationship)
                {
                    Text(prayer.personRelationship!.name)
                    .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct TodayModeOrDoneButtonLabel: View
{
    @Binding var inTodayMode: Bool
    
    var body: some View
    {
        // VStack for view type erasure.  How to get around that in a more Swifty way?
        VStack
        {
            if self.inTodayMode
            {
                Text("Done")
            }
            else
            {
                HStack
                {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Today")
                }
            }
        }
    }
}

struct AddPrayerButtonLabel: View
{
    var body: some View
    {
        HStack
        {
            Image(systemName: "plus")
            Text("Prayer")
        }
    }
}

struct PrayerListRow: View
{
    @ObservedObject var prayer: PrayerEntity
    @Binding var inTodayMode: Bool
    let mode: SortPrayersByOption
    
    var body: some View
    {
        // Need VStack to return one consistent type from closure.  Could find another way around that,
        // I'm sure.
        VStack
        {
            if self.inTodayMode
            {
                HStack
                {
                    PrayerPrayedTodayCheckbox(prayer: prayer)
                    PrayerWithPersonAndTagsListItem(prayer: prayer, mode: mode)
                }
            }
            else
            {
                NavigationLink(
                    destination: PrayerView(prayer: prayer),
                    label: {PrayerWithPersonAndTagsListItem(prayer: prayer, mode: mode)}
                )
            }
        }
    }
}

struct TodayModeButton: View
{
    @Binding var inTodayMode: Bool
    
    var body: some View
    {
        Button(
            action: {self.inTodayMode.toggle()},
            label: {TodayModeOrDoneButtonLabel(inTodayMode: self.$inTodayMode)})
    }
}

struct NewPrayerButton: View
{
    @Environment(\.managedObjectContext) var moc
    @State private var showingNewPrayerSheet = false
    
    var body: some View
    {
        Button(
            action: {self.showingNewPrayerSheet = true},
            label: {AddPrayerButtonLabel()})
        .sheet(isPresented: $showingNewPrayerSheet)
        {
            NewPrayerView(isPresented: self.$showingNewPrayerSheet)
            // The sheet doesn't inherit the environment, which is a bug.
            // https://oleb.net/2020/sheet-environment/
            .environment(\.managedObjectContext, self.moc)
        }
    }
}

struct PrayersByTitleList: View
{
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(
        entity: PrayerEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \PrayerEntity.titleAttribute, ascending: true)]
    ) var prayers: FetchedResults<PrayerEntity>
    @FetchRequest(
        entity: SettingsEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \SettingsEntity.sortPrayersByAttribute, ascending: true)]
    ) var settingsList: FetchedResults<SettingsEntity>
    @Binding var inTodayMode: Bool
    
    var body: some View
    {
        let showArchivedPrayersChoice = Binding<ShowArchivedPrayersOption>(
            get: {ShowArchivedPrayersOption(rawValue: self.settingsList[0].showArchivedPrayersAttribute)!},
            set: {let _ = $0.rawValue}
        )

        List
        {
            ForEach(
                prayers.filter(GetArchivedFilter(showArchivedPrayersChoice.wrappedValue)),
                id: \.id)
            {prayer in
                PrayerListRow(prayer: prayer, inTodayMode: self.$inTodayMode, mode: .title)
            }
            
            .onDelete(perform: deletePrayers)
        }
    }
    
    func deletePrayers(at offsets: IndexSet)
    {
        for offset in offsets
        {
            deletePrayer(prayer: prayers[offset])
        }
        
        /*if moc.hasChanges
        {
            do
            {
                try moc.save()
                moc.refreshAllObjects()
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
}

struct PrayersByPersonList: View
{
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(
        entity: PrayerEntity.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \PrayerEntity.titleAttribute, ascending: true)]
    ) var prayers: FetchedResults<PrayerEntity>
    @FetchRequest(
        entity: PersonEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \PersonEntity.nameAttribute, ascending: true)]
    ) var people: FetchedResults<PersonEntity>
    @FetchRequest(
        entity: SettingsEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \SettingsEntity.sortPrayersByAttribute, ascending: true)]
    ) var settingsList: FetchedResults<SettingsEntity>
    @Binding var inTodayMode: Bool
    
    var body: some View
    {
        let showArchivedPrayersChoice = Binding<ShowArchivedPrayersOption>(
            get: {ShowArchivedPrayersOption(rawValue: self.settingsList[0].showArchivedPrayersAttribute)!},
            set: {let _ = $0.rawValue}
        )

        let prayers_with_no_person = prayers.filter(
            {
                let prayer_has_person = (nil != $0.personRelationship)
                if (prayer_has_person)
                {
                    return false
                }

                // SHOW PRAYERS BASED ON WHETHER THE PRAYER IS ARCHIVED AND WHETHER THE USER CHOSE TO SEE ARCHIVED PRAYERS.
                let prayer_is_archived = $0.archivedAttribute
                switch (showArchivedPrayersChoice.wrappedValue)
                {
                    case .showNonArchivedOnly: return !prayer_is_archived
                    case .showArchivedOnly: return prayer_is_archived
                    default: return true
                }
            }
        )

        let people_with_prayers = people.filter(
            {
                let person_has_prayers = !$0.prayers.isEmpty
                if (!person_has_prayers)
                {
                    return false
                }

                switch (showArchivedPrayersChoice.wrappedValue)
                {
                    case .showNonArchivedOnly:
                        let all_prayers_for_person_archived = $0.prayers.allSatisfy({$0.archivedAttribute})
                        return !all_prayers_for_person_archived
                    case .showArchivedOnly:
                        let all_prayers_for_person_not_archived = $0.prayers.allSatisfy({!$0.archivedAttribute})
                        return !all_prayers_for_person_not_archived
                    default: return true
                }
            }
        )
        
        return List
        {
            ForEach(people_with_prayers, id: \.id)
            {person in
                Section(header: Text("\(person.name)"))
                {
                    ForEach(
                        person.prayers.filter(GetArchivedFilter(showArchivedPrayersChoice.wrappedValue)),
                        id: \.id)
                    {prayer in
                        PrayerListRow(prayer: prayer, inTodayMode: self.$inTodayMode, mode: .person)
                    }
                    .onDelete(perform: {offsets in
                        for offset in offsets
                        {
                            deletePrayer(prayer: person.prayers[offset])
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
}

struct PrayersByTagList: View
{
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(
        entity: TagEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TagEntity.titleAttribute, ascending: true)]
    ) var tags: FetchedResults<TagEntity>
    @FetchRequest(
        entity: PrayerEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \PrayerEntity.titleAttribute, ascending: true)]
    ) var prayers: FetchedResults<PrayerEntity>
    @FetchRequest(
        entity: SettingsEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \SettingsEntity.sortPrayersByAttribute, ascending: true)]
    ) var settingsList: FetchedResults<SettingsEntity>
    @Binding var inTodayMode: Bool
    /// Necessary for unknown reason.  Sometimes (and not always), the view won't update when the prayer's
    /// tag changes.  This forces it to update.
    @State private var forceRefresh = false
    
    var body: some View
    {
        let prayers_with_no_tag = prayers.filter({($0.tags.isEmpty)})
        let tags_with_prayers = tags.filter({!$0.prayers.isEmpty})

        let showArchivedPrayersChoice = Binding<ShowArchivedPrayersOption>(
            get: {ShowArchivedPrayersOption(rawValue: self.settingsList[0].showArchivedPrayersAttribute)!},
            set: {let _ = $0.rawValue}
        )

        return List
        {if (forceRefresh || !forceRefresh){
            ForEach(tags_with_prayers, id: \.id)
            {tag in
                Section(header: Text("\(tag.title)"))
                {
                    ForEach(
                        tag.prayers.filter(GetArchivedFilter(showArchivedPrayersChoice.wrappedValue)),
                        id: \.id)
                    {prayer in
                        PrayerListRow(prayer: prayer, inTodayMode: self.$inTodayMode, mode: .tag)
                    }
                    .onDelete(perform: {offsets in
                        for offset in offsets
                        {
                            deletePrayer(prayer: tag.prayers[offset])
                        }
                    })
                }
            }
            
            if !prayers_with_no_tag.isEmpty
            {
                Section(header: Text("No tag"))
                {
                    return ForEach(
                        prayers_with_no_tag.filter(GetArchivedFilter(showArchivedPrayersChoice.wrappedValue)),
                        id: \.id)
                    {prayer in
                        PrayerListRow(prayer: prayer, inTodayMode: self.$inTodayMode, mode: .tag)
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
}

struct PrayerListView: View
{
    @Environment(\.managedObjectContext) var moc
    @State private var inTodayMode = false
    @FetchRequest(
        entity: SettingsEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \SettingsEntity.sortPrayersByAttribute, ascending: true)]
    ) var settingsList: FetchedResults<SettingsEntity>

    /*@FetchRequest(
        entity: PrayerEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \PrayerEntity.titleAttribute, ascending: true)]
    ) var prayers: FetchedResults<PrayerEntity>

    @FetchRequest(
        entity: TagEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TagEntity.titleAttribute, ascending: true)]
    ) var tags: FetchedResults<TagEntity>

    @FetchRequest(
        entity: PersonEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \PersonEntity.nameAttribute, ascending: true)]
    ) var people: FetchedResults<PersonEntity>

    @FetchRequest(
        entity: DateEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \DateEntity.dateAttribute, ascending: true)]
    ) var dates: FetchedResults<DateEntity>*/

    var body: some View
    {
        let sortPrayersByChoice = Binding<SortPrayersByOption>(
            get: {SortPrayersByOption(rawValue: self.settingsList[0].sortPrayersByAttribute)!},
            set: {
                self.settingsList[0].sortPrayersByAttribute = $0.rawValue
                /*if self.moc.hasChanges
                {
                    do
                    {
                        try self.moc.save(); self.moc.refreshAllObjects()
                    }
                    catch
                    {
                        // Replace this implementation with code to handle the error appropriately.
                        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                        let nserror = error as NSError
                        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                    }
                }*/
            })
        
        return NavigationView
        {
            // VStack for view type erasure.
            VStack
            {
                if sortPrayersByChoice.wrappedValue == .person
                {
                    PrayersByPersonList(inTodayMode: self.$inTodayMode)
                }
                else if sortPrayersByChoice.wrappedValue == .tag
                {
                    PrayersByTagList(inTodayMode: self.$inTodayMode)
                }
                else if sortPrayersByChoice.wrappedValue == .title
                {
                    PrayersByTitleList(inTodayMode: self.$inTodayMode)
                }
            }
            .navigationBarTitle("Prayers")
            .navigationBarItems(
                leading: TodayModeButton(inTodayMode: self.$inTodayMode),
                trailing: NewPrayerButton())
        }
        /*.onAppear
        {
            for prayer in self.prayers
            {
                prayer.title += "a"
            }

            for tag in self.tags
            {
                tag.title += "a"
            }

            for person in self.people
            {
                person.name += "a"
            }

            for date in self.dates
            {
                date.date += TimeInterval(1)
            }

            if self.moc.hasChanges
            {
                do
                {
                    try self.moc.save(); self.moc.refreshAllObjects()
                }
                catch
                {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }*/
    }
}

/// Returns a closure for the filter() function of an Array or FetchedResults<> of type Prayer Entity.
/// The closure returns whether the prayer should be shown to the user based on the "show_archived_prayers"
/// and whether the prayer is archived.
/// \return A closure for the filter() function of an Array or FetchedResults<> of type Prayer Entity.
/// \date 2020-01-01
func GetArchivedFilter(_ show_archived_prayers_option: ShowArchivedPrayersOption) -> (PrayerEntity) -> Bool
{
    let closure = { (prayer: PrayerEntity) -> Bool in
        // SHOW PRAYERS BASED ON WHETHER THE PRAYER IS ARCHIVED AND WHETHER THE USER CHOSE TO SEE ARCHIVED PRAYERS.
        let prayer_is_archived = prayer.archivedAttribute
        switch (show_archived_prayers_option)
        {
            case .showNonArchivedOnly: return !prayer_is_archived
            case .showArchivedOnly: return prayer_is_archived
            default: return true
        }
    }

    return closure
}
