//
//  PrayerView.swift
//  Prayer
//
//  Created by Ben on 3/28/20.
//  Copyright © 2020 Ben. All rights reserved.
//

import SwiftUI

struct TagCheckboxRowForNewPrayer: View
{
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var tag: TagEntity
    @Binding var tags: [TagEntity]

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
            tags.removeAll(where: {$0.id == self.tag.id})
        }
        else
        {
            tags.append(tag)
        }
    }
    
    func prayerTagged() -> Bool
    {
        let tag_in_prayer = tags.first(where: {$0.id == self.tag.id})
        return (nil != tag_in_prayer)
        //return false
    }
}

struct PersonRowForNewPrayerView: View
{
    @ObservedObject var person: PersonEntity
    @Binding var chosenPersonId: UUID

    var body : some View
    {
        Button(
            action:
            {
                self.chosenPersonId = self.person.id
            },
            label:
            {
                HStack
                {
                    Text(person.name)
                    // Change color becuase the button turns it to the accent color.
                    .foregroundColor(.primary)
                    Spacer()
                    if (chosenPersonId == person.id)
                    {
                        Image(systemName: "checkmark").imageScale(.large).foregroundColor(.primary)
                    }
                }
            }
        )
    }
}

/// A view to choose a person for a new prayer.
/// \date 2020-05-03
struct ChoosePersonWhileMakingNewPrayerView: View
{
    @Environment(\.presentationMode) var presentationMode
    /// The output of the view; the ID of the chosen person.
    @Binding var chosenPersonId: UUID
    @FetchRequest(
        entity: PersonEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \PersonEntity.nameAttribute, ascending: true)]
    ) var people: FetchedResults<PersonEntity>

    var body: some View
    {
        // Callback function (the set method) to react to the user choosing a person.  This records
        // the chosen person's ID and dismisses the "choose person" view.
        let localChosenPersonId = Binding<UUID>(
            get: {self.chosenPersonId},
            set: {chosen_person_id in
                // Choose the person.
                self.chosenPersonId = chosen_person_id
                // Dismiss this "choose person" view because the user is done choosing.
                self.presentationMode.wrappedValue.dismiss()
            })

        // Callback function (the set method) to react (dismiss this "choose person" view) if the user
        // creates a new person.
        let newPerson = Binding<PersonEntity?>(
            get: {PersonEntity?(nil)},
            set: {new_person in
                // CHECK WHETHER THE USER CREATED A NEW PERSON.
                let user_created_new_person = (nil != new_person)
                if user_created_new_person
                {
                    // Choose the newly-created person.
                    localChosenPersonId.wrappedValue = new_person!.id
                }
            })

        return List
        {
            ForEach(people, id: \.id)
            {
                person in PersonRowForNewPrayerView(person: person, chosenPersonId: localChosenPersonId)
            }
        }
        .navigationBarItems(trailing: NewPersonButton(newPerson: newPerson))
    }
}

struct NewPrayerView: View
{
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var personId = UUID()
    @State private var chosenTags = [TagEntity]()

    @Binding var isPresented: Bool
    
    init(personId: UUID, isPresented: Binding<Bool>)
    {
        _personId = .init(initialValue: personId)
        self._isPresented = isPresented
    }
    
    init(isPresented: Binding<Bool>)
    {
        self._isPresented = isPresented
    }
    
    @FetchRequest(
        entity: PersonEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \PersonEntity.nameAttribute, ascending: true)]
    ) var people: FetchedResults<PersonEntity>
    
    @FetchRequest(
        entity: TagEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TagEntity.titleAttribute, ascending: true)]
    ) var allTags: FetchedResults<TagEntity>
    
    var body: some View
    {
        
//        let personId = Binding<UUID>(
//            get: {self.prayer.personRelationship?.id ?? UUID()},
//            set: {newPersonId in
//                let person_index = self.people.firstIndex(where: {person in newPersonId == person.id})
//                let person_found = (nil != person_index)
//                if person_found
//                {
//                    let person = self.people[person_index!]
//                    self.prayer.personRelationship = person
//                }
//            })

        return NavigationView
        {
            Form
            {
                // PRAYER TITLE.
                TextField("Title", text: $title)
                
                // PICK THE PRAYER'S PERSON.
                Section(header: Text("Who is the prayer for?"))
                {
//                    Picker(
//                        "Existing person",
//                        // The Picker's selection must be a Binding<A>, where A is the ForEach's id parameter's type.
//                        selection: $personId,
//                        content: {
//                            ForEach(people, id: \.id, content: {person in Text(person.name)})
//                        }
//                    )
                    NavigationLink(
                        destination: ChoosePersonWhileMakingNewPrayerView(chosenPersonId: self.$personId),
                        label: {Text(getChosenPersonName())}
                    )
                }

                Section(header: Text("Tag the prayer:"))
                {
                    NavigationLink(
                        destination: List
                        {
                            ForEach(allTags, id: \.id)
                            {available_tag in
                                TagCheckboxRowForNewPrayer(tag: available_tag, tags: self.$chosenTags)
                            }
                        }
                        .navigationBarTitle("Tags")
                        .navigationBarItems(trailing: NewTagButton()),
                        label: {Text("Tags: " + getTagsString())})
                }
            }
            .navigationBarTitle(
                Text(title.isEmpty ? "New Prayer" : title),
                displayMode: .inline)
            .navigationBarItems(leading: DismissSheetDoneButton(isPresented: $isPresented))
        }
            
        /// \todo On appear, make new prayer.  On disappear, delete it if its title is empty.
        /// That way, I wouldn't need a custom TagCheckboxRowForNewPrayer but could instead
        /// use the one that already exists for the PrayerListView.
            
        .onDisappear{self.saveOrDiscardPrayer()}
    }

    func getChosenPersonName() -> String
    {
        if let chosen_person = people.first(where: {person in person.id == self.personId})
        {
            return chosen_person.name
        }
        else
        {
            return "Person"
        }
    }
    
    func saveOrDiscardPrayer()
    {
        let new_prayer_created = !title.isEmpty
        if !new_prayer_created
        {
            return
        }

        let prayer = PrayerEntity(context: moc)
        prayer.id = UUID()
        
        prayer.title = title
        
        let person_index = self.people.firstIndex(where: {person in personId == person.id})
        let person_found = (nil != person_index)
        if person_found
        {
            let person = self.people[person_index!]
            prayer.personRelationship = person
        }
        
        for chosen_tag in chosenTags
        {
            prayer.addToTagsRelationship(chosen_tag)
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
    
    func getTagsString() -> String
    {
        if chosenTags.isEmpty
        {
            return ""
        }
        
        let sortedChosenTags = chosenTags.sorted(by: {$0.title < $1.title})
        var text = sortedChosenTags[0].title
        
        for index in 1..<sortedChosenTags.count
        {
            text.append(", " + sortedChosenTags[index].title)
        }
        
        return text
    }
    
    func returnToLastView()
    {
        self.presentationMode.wrappedValue.dismiss()
    }
}
