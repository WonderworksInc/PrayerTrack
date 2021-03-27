//
//  PrayerView.swift
//  Prayer
//
//  Created by Ben on 3/28/20.
//  Copyright © 2020 Ben. All rights reserved.
//

import SwiftUI

struct TagCheckboxRow: View
{
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var prayer: PrayerEntity
    @ObservedObject var tag: TagEntity
    
    var body : some View
    {
        Button(
            action: toggle,
            label:
            {
                HStack
                {
                    Image(systemName: prayerTagged() ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
                    .font(.headline)
                    
                    Text(tag.title)
                }
                // Change color becuase the button turns it to the accent color.
                .foregroundColor(prayerTagged() ? .primary : .secondary)
            }
        )
    }
    
    func toggle() -> Void
    {
        if prayerTagged()
        {
            prayer.removeFromTagsRelationship(tag)
        }
        else
        {
            prayer.addToTagsRelationship(tag)
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
    
    func prayerTagged() -> Bool
    {
        let tag_in_prayer = prayer.tags.first(where: {$0.id == self.tag.id})
        return (nil != tag_in_prayer)
    }
}

struct PrayerView: View
{
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var prayer: PrayerEntity
    @State private var newDateState: Date?
    @State private var showingPrayedOnCalendar = false
    @State private var showingNewPrayedOnDatePicker = false
    @State private var showingAnsweredDatePicker = false
    
    @FetchRequest(
        entity: PersonEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \PersonEntity.nameAttribute, ascending: true)]
    ) var people: FetchedResults<PersonEntity>
    @FetchRequest(
        entity: DateEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \DateEntity.dateAttribute, ascending: true)]
    ) var dates: FetchedResults<DateEntity>
    @FetchRequest(
        entity: TagEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TagEntity.titleAttribute, ascending: true)]
    ) var tags: FetchedResults<TagEntity>
    
    var body: some View
    {
        // Wrap state in local binding variable so that setting can be intercepted.
        // https://www.hackingwithswift.com/books/ios-swiftui/creating-custom-bindings-in-swiftui
        let title = Binding<String>(
            get: {self.prayer.title},
            set: {self.prayer.title = $0})
        let personId = Binding<UUID>(
            get: {self.prayer.personRelationship?.id ?? UUID()},
            set: {newPersonId in
                let person_index = self.people.firstIndex(where: {person in newPersonId == person.id})
                let person_found = (nil != person_index)
                if person_found
                {
                    self.prayer.personRelationship = self.people[person_index!]
                }
            })
        
        let descriptionText = Binding<String>(
            get: {self.prayer.descriptionText},
            set: {self.prayer.descriptionText = $0})
        
        let newDate = Binding<Date>(
            get: {(nil != self.newDateState ? self.newDateState! : Date())},
            set: {self.newDateState = $0})

        let archived = Binding<Bool>(
            get: {self.prayer.archivedAttribute},
            set: {self.prayer.archivedAttribute = $0}
        )

        let answered = Binding<Bool>(
            get: {self.prayer.answeredAttribute},
            set: {
                self.prayer.answeredAttribute = $0
                self.prayer.answerDescriptionAttribute = ""
                if let date_answered = self.prayer.dateAnsweredRelationship
                {
                    self.prayer.dateAnsweredRelationship = nil
                    
                    deleteDateIfEmtpy(date: date_answered)
                }
            }
        )
        
        let answeredAffirmatively = Binding<Bool>(
            get: {self.prayer.answeredAffirmativelyAttribute},
            set: {self.prayer.answeredAffirmativelyAttribute = $0}
        )
        
        let answerDescription = Binding<String>(
            get: {(nil != self.prayer.answerDescriptionAttribute) ? self.prayer.answerDescriptionAttribute! : ""},
            set: {self.prayer.answerDescriptionAttribute = $0}
        )
        
        let answerDate = Binding<Date>(
            get: {(nil != self.prayer.dateAnsweredRelationship) ? self.prayer.dateAnsweredRelationship!.date : Date()},
            set: {
                if let date_answered = self.prayer.dateAnsweredRelationship
                {
                    if date_answered.date.ymd == $0.ymd
                    {
                        return
                    }
                    
                    self.prayer.dateAnsweredRelationship = nil
                    
                    deleteDateIfEmtpy(date: date_answered)
                }
                self.prayer.dateAnsweredRelationship = self.getOrCreateDateFromDatabase(date: $0)
            }
        )
        
        return
            Form
            {
                VStackTextView(top: title, bottom: "Title")
                NavigationLink(
                    destination:
                        TextEditorCommitOnlyOnDisappear(text: descriptionText)
                        .navigationBarTitle("Description/Notes"),
                    label: {
                        let added_text = (descriptionText.wrappedValue.isEmpty ? "" : ":\n" + descriptionText.wrappedValue)
                        Text("Description/Notes" + added_text).lineLimit(2)
                    }
                )
                Picker(
                    "Person",
                    // The Picker's selection must be a Binding<A>, where A is the ForEach's id parameter's type.
                    selection: personId,
                    content: {ForEach(people, id: \.id, content: {person in Text(person.name)})}
                )
                NavigationLink(
                    destination: List
                    {
                        ForEach(tags, id: \.id)
                        {tag in
                            TagCheckboxRow(prayer: self.prayer, tag: tag)
                        }
                    }
                    .navigationBarTitle("Tags")
                    .navigationBarItems(trailing: NewTagButton()),
                    label: {Text("Tags: " + getTagsString())})

                Toggle(isOn: archived, label: {Text("Archived")})

                Section(
                    header: Text("Answer"),
                    content: {
                        Toggle(isOn: answered, label: {Text("Answered")})
                        if (answered.wrappedValue)
                        {
                            Toggle(isOn: answeredAffirmatively, label: {Text("Answered affirmatively")})
                            NavigationLink(
                                destination:
                                    TextEditorCommitOnlyOnDisappear(text: answerDescription)
                                    .navigationBarTitle("Answer Description/Notes"),
                                label: {
                                    let added_text = (answerDescription.wrappedValue.isEmpty ? "" : ":\n" + answerDescription.wrappedValue)
                                    Text("Answer Description/Notes" + added_text).lineLimit(2)
                                }
                            )
                            HStack {
                                Text("Answered date")
                                Spacer()
                                Text(getDateString(date: answerDate.wrappedValue))
                                .foregroundColor(.accentColor)
                            }
                            .onTapGesture(perform: {self.showingAnsweredDatePicker = true})
                            .sheet(
                                isPresented: self.$showingAnsweredDatePicker,
                                content: {Self.getDatePicker(date: answerDate, isPresented: self.$showingAnsweredDatePicker)}
                            )
                        }
                    }
                )

                Section(
                    header: Text("Prayed-on dates"),
                    content: {
//                        // NEW PRAYED-ON DATE.
//                        if (nil == newDateState) {
//                            Button("Add new prayed-on date", action: {self.newDateState = Date()})
//                        }
//                        else {
//                            DatePicker("New prayed-on date", selection: newDate, in: ...Date(), displayedComponents: .date)
//                        }
                        
                        // NEW PRAYED-ON DATE.
                        if (nil == newDateState)
                        {
                            Button("Add new prayed-on date", action: {self.newDateState = Date()})
                        }
                        else
                        {
                            HStack
                            {
                                Text("New prayed-on date")
                                Spacer()
                                Text(getDateString(date: newDateState!))
                                .foregroundColor(.accentColor)
                            }
                            .onTapGesture(perform: {self.showingNewPrayedOnDatePicker = true})
                            .sheet(
                                isPresented: $showingNewPrayedOnDatePicker,
                                content: {Self.getDatePicker(date: newDate, isPresented: self.$showingNewPrayedOnDatePicker)}
                            )
                        }
                        
                        if !prayer.datesPrayed.isEmpty
                        {
                            List {
                                Button("Show on calendar", action: {self.showingPrayedOnCalendar = true})
                                .sheet(
                                    isPresented: $showingPrayedOnCalendar,
                                    // Had to tell this closure what type it returned because otherwise, it wouldn't let
                                    // me locally declare the RKManager because it was using ViewBuilder.
                                    content: {() -> RKViewController in
                                        let last_date = self.prayer.datesPrayed.last!.date

                                        // Unknown why a date next month is required to show this month.  For example,
                                        // if last date is April 8, then April won't show unless the RKManager's maximumDate
                                        // is in May.
                                        let some_day_next_month_after_last_date = Calendar.current.date(byAdding: .month, value: 1, to: last_date)!

                                        let local_rkmanager = RKManager(
                                            calendar: Calendar.current,
                                            minimumDate: self.prayer.datesPrayed.first!.date,
                                            maximumDate: some_day_next_month_after_last_date,
                                            mode: 0)

                                        // DISABLE DATES THAT WERE NOT PRAYED ON.
                                        var disabled_date = Date()
                                        for index in 0..<self.prayer.datesPrayed.count
                                        {
                                            let is_last_prayed_on_date = (index == (self.prayer.datesPrayed.count - 1))
                                            if is_last_prayed_on_date
                                            {
                                                break;
                                            }

                                            disabled_date = self.prayer.datesPrayed[index].date.nextDay
                                            while ((disabled_date < self.prayer.datesPrayed[index + 1].date) && (disabled_date.ymd != self.prayer.datesPrayed[index+1].date.ymd))
                                            {
                                                local_rkmanager.disabledDates.append(disabled_date)
                                                disabled_date = disabled_date.nextDay
                                            }
                                        }

                                        disabled_date = last_date.nextDay
                                        while (disabled_date <= some_day_next_month_after_last_date)
                                        {
                                            local_rkmanager.disabledDates.append(disabled_date)
                                            disabled_date = disabled_date.nextDay
                                        }

                                        
                                        for prayed_on_date_entity in self.prayer.datesPrayed
                                        {
                                            local_rkmanager.selectedDates.append(prayed_on_date_entity.date)
                                        }
                                        return RKViewController(isPresented: self.$showingPrayedOnCalendar, rkManager: local_rkmanager)
                                    }
                                )
                                ForEach(prayer.datesPrayed, id: \.date, content: {prayed_on_date -> Text in
                                    let date_formatter = DateFormatter()
                                    // .full means "Sunday, March 22, 2020", for example.
                                    date_formatter.dateStyle = .full
                                    // Don't display the time because this prayer tracker tracks only dates.
                                    date_formatter.timeStyle = .none
                                    return Text(date_formatter.string(from: prayed_on_date.date))
                                })
                                .onDelete(perform: deletePrayedOnDates)
                            }
                        }
                    }
                )
            }
            .onDisappear(perform: {self.savePrayer()})
            .navigationBarTitle(Text(prayer.title), displayMode: .inline)
    }
    
    func savePrayer()
    {
        let user_says_they_prayed_on_a_new_date = (nil != newDateState)
        if user_says_they_prayed_on_a_new_date
        {
            // CHECK WHETHER THE PRAYER IS ALREADY MARKED AS PRAYED ON THAT DATE.
            for already_prayed_date in prayer.datesPrayed {
                let already_prayed_on_this_date = (newDateState!.ymd == already_prayed_date.date.ymd)
                if already_prayed_on_this_date {
                    newDateState = nil
                    break
                }
            }
        }
        
        let user_actually_prayed_on_a_new_date = (nil != newDateState)
        if user_actually_prayed_on_a_new_date
        {
            prayer.addToDatesPrayedRelationship(getOrCreateDateFromDatabase(date: newDateState!))
        }
        
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
    
    func returnToLastView()
    {
        self.presentationMode.wrappedValue.dismiss()
    }
    
    func deletePrayedOnDates(at offsets: IndexSet)
    {
        for offset in offsets
        {
            let date = prayer.datesPrayed[offset]
            prayer.removeFromDatesPrayedRelationship(date)
            
            deleteDateIfEmtpy(date: date)
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
    
    func getTagsString() -> String
    {
        if prayer.tags.isEmpty
        {
            return ""
        }
        
        var text = prayer.tags[0].title
        
        for index in 1..<prayer.tags.count
        {
            text.append(", " + prayer.tags[index].title)
        }
        
        return text
    }
    
    func getDateString(date: Date) -> String
    {
        let date_formatter = DateFormatter()
        // .full means "Sunday, March 22, 2020", for example.
        date_formatter.dateStyle = .short
        // Don't display the time because this prayer tracker tracks only dates.
        date_formatter.timeStyle = .none
        return date_formatter.string(from: date)
    }
    
    static func getFirstDayOfLastMonth() -> Date
    {
        let last_day_of_previous_month = Calendar.current.date(byAdding: .day, value: -(Date().ymd.day!), to: Date())!
        let first_day_of_previous_month = Calendar.current.date(byAdding: .day, value: -(last_day_of_previous_month.ymd.day! - 1), to: last_day_of_previous_month)!
        return first_day_of_previous_month
    }
    
    static func getDatePicker(date: Binding<Date>, isPresented: Binding<Bool>) -> some View
    {
        let rkmanager: RKManager = RKManager(
            calendar: Calendar.current,
            minimumDate: Self.getFirstDayOfLastMonth(),
            maximumDate: Date(),
            mode: 0)
        
        rkmanager.selectedDate = date.wrappedValue
//        if (nil == rkmanager.selectedDate)
//        {
//            rkmanager.selectedDate = Date()
//        }
        
        let view = RKViewController(
            isPresented: isPresented,
            rkManager: rkmanager)
            .onDisappear(perform: {
                if (nil != rkmanager.selectedDate)
                {
                    date.wrappedValue = rkmanager.selectedDate
                }
            })
        
        return view
    }
}

extension Date {
    /// Get the year, month, day from the date.
    var ymd: DateComponents {
        let dmy_components = Set<Calendar.Component>([.day, .month, .year])
        return Calendar.current.dateComponents(dmy_components, from: self)
    }
}
