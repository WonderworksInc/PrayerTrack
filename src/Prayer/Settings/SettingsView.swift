//
//  SettingsView.swift
//  Prayer
//
//  Created by Ben on 4/4/20.
//  Copyright © 2020 Ben. All rights reserved.
//

import SwiftUI

enum SortPrayersByOption: Int16, CaseIterable
{
    case title = 0
    case person = 1
    case tag = 2
}

extension SortPrayersByOption
{
    func toString() -> String
    {
        switch self
        {
            case .title: return "Title"
            case .person: return "Person"
            case .tag: return "Tag"
        }
    }
}

enum ShowArchivedPrayersOption: Int16, CaseIterable
{
    case showAll = 0
    case showNonArchivedOnly = 1
    case showArchivedOnly = 2
}

extension ShowArchivedPrayersOption
{
    func toString() -> String
    {
        switch self
        {
            case .showAll: return "Both"
            case .showNonArchivedOnly: return "Non-archived"
            case .showArchivedOnly: return "Archived"
        }
    }
}

enum ShowAnsweredPrayersOption: Int16, CaseIterable
{
    case showAll = 0
    case showUnansweredOnly = 1
    case showAnsweredOnly = 2
}

extension ShowAnsweredPrayersOption
{
    func toString() -> String
    {
        switch self
        {
            case .showAll: return "Both"
            case .showUnansweredOnly: return "Unanswered"
            case .showAnsweredOnly: return "Answered"
        }
    }
}

struct SettingsView: View
{
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(
        entity: SettingsEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \SettingsEntity.sortPrayersByAttribute, ascending: true)]
    ) var settingsList: FetchedResults<SettingsEntity>
    
    var body: some View
    {
        let showArchivedPrayersChoice = Binding<ShowArchivedPrayersOption>(
        get: {ShowArchivedPrayersOption(rawValue: self.settingsList[0].showArchivedPrayersAttribute)!},
        set: {
            self.settingsList[0].showArchivedPrayersAttribute = $0.rawValue
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

        let showAnsweredPrayersChoice = Binding<ShowAnsweredPrayersOption>(
            get: {ShowAnsweredPrayersOption(rawValue: self.settingsList[0].showAnsweredPrayersAttribute)!},
            set: {self.settingsList[0].showAnsweredPrayersAttribute = $0.rawValue})

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

        let requireUnlockingChoice = Binding<Bool>(
            get: {self.settingsList[0].requireUnlockingAttribute},
            set: {self.settingsList[0].requireUnlockingAttribute = $0}
        )

        return NavigationView
        {
            Form
            {
                Section(header: Text("Show which prayers in Prayer tab?"))
                {
                    Picker(
                        "Show which prayers?",
                        // The Picker's selection must be a Binding<A>, where A is the ForEach's id parameter's type.
                        selection: showAnsweredPrayersChoice)
                    {
                        ForEach(ShowAnsweredPrayersOption.allCases, id: \.self)
                        {option in
                            Text(option.toString())
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    Picker(
                        "Show which prayers?",
                        // The Picker's selection must be a Binding<A>, where A is the ForEach's id parameter's type.
                        selection: showArchivedPrayersChoice)
                    {
                        ForEach(ShowArchivedPrayersOption.allCases, id: \.self)
                        {option in
                            Text(option.toString())
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Sort prayers by"))
                {
                    Picker(
                        "Sort prayers by",
                        // The Picker's selection must be a Binding<A>, where A is the ForEach's id parameter's type.
                        selection: sortPrayersByChoice)
                    {
                        ForEach(SortPrayersByOption.allCases, id: \.self)
                        {option in
                            Text(option.toString())
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Require unlocking for privacy?"))
                {
                    Toggle(isOn: requireUnlockingChoice, label: {Text("Require unlocking")})
                }
            }
            .navigationBarTitle("Settings")
        }
    }
}
