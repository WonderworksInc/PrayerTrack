//
//  ContentView.swift
//  Bookworm
//
//  Created by Ben on 3/14/20.
//  Copyright © 2020 Ben. All rights reserved.
//

import LocalAuthentication
import SwiftUI

extension View
{
    func obfuscate(if obfuscate: Bool, unlockAction: @escaping () -> Void) -> some View
    {
        return ZStack
        {
            if obfuscate
            {
                // In the background, have the app's normal view, significantly blurred.
                self.blur(radius: 8, opaque: true)

                // Overlay "Unlock Prayers" on it to identify the app for the viewer and to give a button to unlock.
                Button(
                    action: unlockAction,
                    label: {Text("Unlock\nPrayers").multilineTextAlignment(.center).font(.title)})
                // Spread the "Prayer" title view over the whole screen to intercept gestures.
                .frame(minWidth: 0, idealWidth: .greatestFiniteMagnitude, maxWidth: .infinity, minHeight: 0, idealHeight: .greatestFiniteMagnitude, maxHeight: .infinity, alignment: .center)
                // The background is to intercept touches so that the user can't use the app.  Color.clear doesn't work;
                // that's functionally as well as visually transparent.  Any other color (e.g., yellow here) with an opacity
                // of 0 does not show up but is present, intercepting the gestures.
                .background(Color.yellow.opacity(0))
            }
            else
            {
                // The view is not obfucated; return this view.
                self
            }
        }
    }
}

struct ContentView: View
{
    @Environment(\.managedObjectContext) var moc
    @State private var selectedTabIndex = 0
    @State private var showingCalendar = false
    @State private var isLocked = true
    @State private var receivedDidBecomeActiveNotification = false
    @State private var isActive = false

    @State private var rkmanager: RKManager = RKManager(
        calendar: Calendar.current,
        minimumDate: Date(),
        maximumDate: Date(),
        mode: 0)
    @FetchRequest(
        entity: PrayerEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \PrayerEntity.titleAttribute, ascending: true)]
    ) var prayers: FetchedResults<PrayerEntity>
    @FetchRequest(
        entity: DateEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \DateEntity.dateAttribute, ascending: true)]
    ) var dates: FetchedResults<DateEntity>
    
    @FetchRequest(
        entity: SettingsEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \SettingsEntity.sortPrayersByAttribute, ascending: true)]
    ) var settingsList: FetchedResults<SettingsEntity>

    var body: some View
    {
        // ENSURE THE SETTINGS EXIST.
        if self.settingsList.isEmpty
        {
            let settings = SettingsEntity(context: self.moc)
            settings.showArchivedPrayersAttribute = ShowArchivedPrayersOption.showNonArchivedOnly.rawValue
            settings.sortPrayersByAttribute = SortPrayersByOption.person.rawValue
            settings.requireUnlockingAttribute = false

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
        }
        
        return TabView(selection: $selectedTabIndex)
        {
            PrayerListView()
            .tabItem({
                Image(systemName: "text.bubble.fill")
                Text("Prayers")
            })
            .tag(0)

            PersonListView()
            .tabItem({
                Image(systemName: "person.3")
                Text("People")
            })
            .tag(1)

            TagListView()
            .tabItem({
                Image(systemName: "tag")
                Text("Tags")
            })
            .tag(2)
            
//          if (!dates.isEmpty)
//          {
            // For an unknown reason, the RKViewController presents three tabs.  Wrapping it in a VStack
            // solves the problem and also makes the weekdays appear at the top.
            //VStack{getCalendarView()}
            
            //Text("test")

//                }
            PrayerListViewSelected(rkmanager: self.$rkmanager, showingCalendar: $showingCalendar)
            .sheet(isPresented: $showingCalendar, content: {self.getCalendarView()})
            .tabItem({
                Image(systemName: "calendar")
                Text("Dates")
            })
            .tag(3)

            SettingsView()
            .tabItem({
                Image(systemName: "gear")
                Text("Settings")
            })
            .tag(4)
        }
        .obfuscate(if: !self.isActive && self.settingsList[0].requireUnlockingAttribute, unlockAction: {
            self.receivedDidBecomeActiveNotification = true
            self.authenticate()

            self.isActive = !self.isLocked})
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification))
        { _ in
            if self.isLocked && !self.receivedDidBecomeActiveNotification
            {
                /// \todo Look in debugger; setting to true does nothing?!
                self.receivedDidBecomeActiveNotification = true
                self.authenticate()
            }

            self.isActive = !self.isLocked
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification))
        { _ in
            self.isActive = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification))
        { _ in

            if self.moc.hasChanges
            {
                do
                {
                    try self.moc.save()
                    self.moc.refreshAllObjects()
                }
                catch
                {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }

            self.receivedDidBecomeActiveNotification = false
            self.isLocked = true
        }
    }

    func authenticate()
    {
        if !self.settingsList[0].requireUnlockingAttribute
        {
            self.isLocked = false
            self.isActive = true
            return
        }

        let context = LAContext()
        //var error: NSError?
        let reason = "Unlock your prayers."
        let reply: (Bool, Error?) -> Void = {success, authenticationError in
            DispatchQueue.main.async
            {
                if success
                {
                    self.isLocked = false
                    self.isActive = true
                }
            }
        }

        /// \todo Do not use deviceOwnerAuthenticationWithBiometrics because that prevents manual passcode fallback
        ///     in case biometrics fail.
//        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
//        {
//            context.evaluatePolicy(
//                .deviceOwnerAuthenticationWithBiometrics,
//                localizedReason: reason,
//                reply: reply)
//        }
//        else
//        {
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason,
                reply: reply)
        //}
    }

    func getCalendarView() -> RKViewController
    {
        rkmanager.minimumDate = dates.first?.date ?? Date()

        // Unknown why a date next month is required to show this month.  For example,
        // if last date is April 8, then April won't show unless the RKManager's maximumDate
        // is in May.
        let last_date = dates.last?.date ?? Date()
        let some_day_next_month_after_last_date = Calendar.current.date(byAdding: .month, value: 1, to: last_date)!
        rkmanager.maximumDate = some_day_next_month_after_last_date
        
        rkmanager.disabledDates = []
        
        let any_dates = !dates.isEmpty
        if any_dates
        {
            var disabled_date = Date()
            for index in 0..<dates.count
            {
                let is_last_prayed_on_date = (index == (dates.count - 1))
                if is_last_prayed_on_date
                {
                    break;
                }

                disabled_date = dates[index].date.nextDay
                while ((disabled_date < dates[index + 1].date) && (disabled_date.ymd != dates[index+1].date.ymd))
                {
                    rkmanager.disabledDates.append(disabled_date)
                    disabled_date = disabled_date.nextDay
                }
            }

            disabled_date = last_date.nextDay
            while (disabled_date <= some_day_next_month_after_last_date)
            {
                rkmanager.disabledDates.append(disabled_date)
                disabled_date = disabled_date.nextDay
            }

        }
        
        return RKViewController(isPresented: self.$showingCalendar, rkManager: rkmanager)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension Date {
    var nextDay: Date {
        let ONE_DAY_IN_SECONDS = TimeInterval(60*60*24)
        return self.addingTimeInterval(ONE_DAY_IN_SECONDS)
    }
}
