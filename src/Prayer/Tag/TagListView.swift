//
//  TagListView.swift
//  Tag
//
//  Created by Ben on 3/28/20.
//  Copyright © 2020 Ben. All rights reserved.
//

import SwiftUI

struct NewTagView: View
{
    @Environment(\.managedObjectContext) var moc
    @State private var titleState = ""
    @Binding var isPresented: Bool
    
    var body: some View
    {
        NavigationView
        {
            Form
            {
                TextField("Title", text: $titleState)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification))
                { _ in
                    self.isPresented = false
                }
            }
            .navigationBarTitle(Text(titleState.isEmpty ? "New tag" : titleState), displayMode: .inline)
            .navigationBarItems(
                leading: DismissSheetDoneButton(isPresented: $isPresented))
        }
        .onDisappear(perform: {self.saveTag()})
    }
    
    /// \todo   Prevent duplicate tags/people.
    
    func saveTag()
    {
        if titleState.isEmpty
        {
            return
        }
        
        let tag = TagEntity(context: moc)
        tag.title = titleState
        tag.id = UUID()
        
        // SAVE THE CHANGES TO CORE DATA.
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

struct NewTagButton: View
{
    @Environment(\.managedObjectContext) var moc
    @State private var showingNewTagSheet = false
    
    var body: some View
    {
        Button(
            action: {self.showingNewTagSheet = true},
            label: {
                HStack
                {
                    Image(systemName: "plus")
                    Text("Tag")
                }
            })
        .sheet(
            isPresented: $showingNewTagSheet,
            content: {
                NewTagView(isPresented: self.$showingNewTagSheet)
                // The sheet doesn't inherit the environment, which is a bug.
                // https://oleb.net/2020/sheet-environment/
                .environment(\.managedObjectContext, self.moc)}
        )
    }
}

struct TagListRow: View
{
    @ObservedObject var tag: TagEntity
    
    var body: some View
    {
        NavigationLink(
            destination: TagView(tag: tag),
            label: {
                Text(tag.title)
                .font(.headline)
            })
    }
}

struct TagListView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(
        entity: TagEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TagEntity.titleAttribute, ascending: true)]
    ) var tags: FetchedResults<TagEntity>

    var body: some View
    {
        NavigationView
        {
            List
            {
                // Use the tag's ID as the identifier rather than the title because using \.title causes
                // the TagView to dismiss and the TagListView to come back into focus as soon as
                // the TagView changes the person's name.
                // This is the second squirrely thing I've found about ForEach.  It's sensitive to the
                // IDs changing, obviously, but maybe also the count.
                ForEach(tags, id: \.id)
                {tag in
                    TagListRow(tag: tag)
                }
                .onDelete(perform: deleteTags)
            }
            .navigationBarTitle("Tags")
            .navigationBarItems(
                trailing: NewTagButton())
        }
    }
    
    func deleteTags(at offsets: IndexSet)
    {
        for offset in offsets
        {
            moc.delete(tags[offset])
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
