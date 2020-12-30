//
//  PersonListView.swift
//  Person
//
//  Created by Ben on 3/28/20.
//  Copyright © 2020 Ben. All rights reserved.
//

import SwiftUI

/// View of "+ Person" for the NewPersonButton.
/// \date   2020-05-03
struct AddPersonButtonLabel: View
{
    var body: some View
    {
        HStack
        {
            Image(systemName: "plus")
            Text("Person")
        }
    }
}

/// A button that shows a sheet to add a person and returns the new person, if any, via the newPerson Binding (callback).
struct NewPersonButton: View
{
    @Environment(\.managedObjectContext) var moc
    @State private var showingNewPersonSheet = false

    /// The callback (via the Binding's set method) that is called when the sheet is dismissed, returning
    /// the new person if one was created.  Calls set with nil if not.
    @Binding var newPerson: PersonEntity?

    var body: some View
    {
        Button(
            action: {self.showingNewPersonSheet = true},
            label: {AddPersonButtonLabel()})
        .sheet(
            isPresented: $showingNewPersonSheet,
            content: {
                NewPersonView(isPresented: self.$showingNewPersonSheet, newPerson: self.$newPerson)
                // The sheet doesn't inherit the environment, which is a bug.
                // https://oleb.net/2020/sheet-environment/
                .environment(\.managedObjectContext, self.moc)}
        )
    }
}

struct PersonListRow: View
{
    @ObservedObject var person: PersonEntity
    
    var body: some View
    {
        NavigationLink(
            destination: PersonView(person: person),
            label: {
                Text(person.name)
                .font(.headline)
            })
    }
}

struct PersonListView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(
        entity: PersonEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \PersonEntity.nameAttribute, ascending: true)]
    ) var people: FetchedResults<PersonEntity>

    var body: some View
    {
        let newPerson = Binding<PersonEntity?>(
            get: {PersonEntity?(nil)},
            set: {newPerson in /*Do nothing.*/})

        return NavigationView
        {
            List
            {
                // Use the person's ID as the identifier rather than the name because using \.name causes
                // the PersonView to dismiss and the PersonListView to come back into focus as soon as
                // the PersonView changes the person's name.
                // This is the second squirrely thing I've found about ForEach.  It's sensitive to the
                // IDs changing, obviously, but maybe also the count.
                ForEach(people, id: \.id)
                {person in
                    PersonListRow(person: person)
                }
                .onDelete(perform: deletePeople)
            }
            .navigationBarTitle("People")
            .navigationBarItems(trailing: NewPersonButton(newPerson: newPerson))
        }
    }
    
    func deletePeople(at offsets: IndexSet)
    {
        for offset in offsets
        {
            // Leave the prayers; just unlink them from people.
            /// \todo   Change this to delete the prayers, too.
            moc.delete(people[offset])
        }
        
        if moc.hasChanges
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
        }
    }
}

struct PersonListView_Previews: PreviewProvider {
    static var previews: some View {
        PersonListView()
    }
}
