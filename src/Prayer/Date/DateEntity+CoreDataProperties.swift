//
//  DateEntity+CoreDataProperties.swift
//  Prayer
//
//  Created by Ben on 3/28/20.
//  Copyright © 2020 Ben. All rights reserved.
//
//

import Foundation
import CoreData


extension DateEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DateEntity> {
        return NSFetchRequest<DateEntity>(entityName: "DateEntity")
    }

    @NSManaged public var dateAttribute: Date?
    @NSManaged public var prayersAnsweredRelationship: NSSet?
    @NSManaged public var prayersPrayedRelationship: NSSet?

    public var date: Date{
        get{dateAttribute ?? Date()}
        set{dateAttribute = newValue}
    }

    public var prayersAnswered: [PrayerEntity] {
        let prayers = prayersAnsweredRelationship as? Set<PrayerEntity> ?? []
        return prayers.sorted(by: {$0 < $1})
    }
    
    public var prayersPrayed: [PrayerEntity] {
        let prayers = prayersPrayedRelationship as? Set<PrayerEntity> ?? []
        return prayers.sorted(by: {$0 < $1})
    }
}

extension DateEntity: Comparable
{
    public static func == (left: DateEntity, right: DateEntity) -> Bool
    {
        return left.date == right.date
    }
    
    public static func < (left: DateEntity, right: DateEntity) -> Bool
    {
        return left.date < right.date
    }
}

// MARK: Generated accessors for prayersRelationship
extension DateEntity {

    @objc(addPrayersAnsweredRelationshipObject:)
    @NSManaged public func addToPrayersAnsweredRelationship(_ value: PrayerEntity)

    @objc(removePrayersAnsweredRelationshipObject:)
    @NSManaged public func removeFromPrayersAnsweredRelationship(_ value: PrayerEntity)

    @objc(addPrayersAnsweredRelationship:)
    @NSManaged public func addToPrayersAnsweredRelationship(_ values: NSSet)

    @objc(removePrayersAnsweredRelationship:)
    @NSManaged public func removeFromPrayersAnsweredRelationship(_ values: NSSet)
    
    @objc(addPrayersPrayedRelationshipObject:)
    @NSManaged public func addToPrayersPrayedRelationship(_ value: PrayerEntity)

    @objc(removePrayersPrayedRelationshipObject:)
    @NSManaged public func removeFromPrayersPrayedRelationship(_ value: PrayerEntity)

    @objc(addPrayersPrayedRelationship:)
    @NSManaged public func addToPrayersPrayedRelationship(_ values: NSSet)

    @objc(removePrayersPrayedRelationship:)
    @NSManaged public func removeFromPrayersPrayedRelationship(_ values: NSSet)

}

// MARK: Utilities
func deleteDateIfEmtpy(date: DateEntity)
{
    let date_used = !date.prayersPrayed.isEmpty || !date.prayersAnswered.isEmpty
    if !date_used
    {
        guard let date_moc = date.managedObjectContext
        else
        {
            fatalError("Date has no managed object context.")
        }

        date_moc.delete(date)
        /*if date_moc.hasChanges
        {
            do
            {
                try date_moc.save(); date_moc.refreshAllObjects()
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
