//
//  PersonView.swift
//  Person
//
//  Created by Ben on 3/28/20.
//  Copyright © 2020 Ben. All rights reserved.
//

import SwiftUI


struct NewPersonView: View
{
    @Environment(\.managedObjectContext) var moc
    @State private var nameState = ""
    @Binding var isPresented: Bool

    /// The callback (via the Binding's set method) that is called when the sheet is dismissed, returning
    /// the new person if one was created.  Calls set with nil if not.
    @Binding var newPerson: PersonEntity?

    var body: some View
    {
        NavigationView
        {
            Form
            {
                TextField("Name", text: $nameState)
            }
            .navigationBarTitle(Text(nameState.isEmpty ? "New person" : nameState), displayMode: .inline)
            .navigationBarItems(leading: DismissSheetDoneButton(isPresented: $isPresented))
        }
        .onDisappear(perform: {self.savePerson()})
    }
    
    func savePerson()
    {
        if nameState.isEmpty
        {
            // Call the callback (the Binding's set method), indicating that no new person was created.
            newPerson = nil
            return
        }
        
        let person = PersonEntity(context: moc)
        person.name = nameState
        person.id = UUID()
        
        // SAVE THE PRAYER TO CORE DATA.
        if moc.hasChanges
        {
            do
            {
                try moc.save(); moc.refreshAllObjects()
                // Call the callback (the Binding's set method) with the new person that was created.
                newPerson = person
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
