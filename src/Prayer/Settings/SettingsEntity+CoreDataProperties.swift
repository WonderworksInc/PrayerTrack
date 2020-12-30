//
//  SettingsEntity+CoreDataProperties.swift
//  Prayer
//
//  Created by Ben on 4/4/20.
//  Copyright © 2020 Ben. All rights reserved.
//
//

import Foundation
import CoreData

extension SettingsEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SettingsEntity> {
        return NSFetchRequest<SettingsEntity>(entityName: "SettingsEntity")
    }

    @NSManaged public var showArchivedPrayersAttribute: Int16
    @NSManaged public var sortPrayersByAttribute: Int16
    @NSManaged public var requireUnlockingAttribute: Bool
}

extension SettingsEntity: Comparable
{
    public static func == (left: SettingsEntity, right: SettingsEntity) -> Bool
    {
        if (left.showArchivedPrayersAttribute != right.showArchivedPrayersAttribute) {return false}
        if (left.sortPrayersByAttribute != right.sortPrayersByAttribute) {return false}
        if (left.requireUnlockingAttribute != right.requireUnlockingAttribute) {return false}
        return true
    }
    
    public static func < (left: SettingsEntity, right: SettingsEntity) -> Bool
    {
        if (left.showArchivedPrayersAttribute != right.showArchivedPrayersAttribute) {return left.showArchivedPrayersAttribute < right.showArchivedPrayersAttribute}
        if (left.sortPrayersByAttribute != right.sortPrayersByAttribute) {return left.sortPrayersByAttribute < right.sortPrayersByAttribute}
        if (left.requireUnlockingAttribute != right.requireUnlockingAttribute) {return left.requireUnlockingAttribute}
        return false
    }
}
