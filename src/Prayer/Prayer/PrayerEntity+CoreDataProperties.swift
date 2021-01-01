//
//  PrayerEntity+CoreDataProperties.swift
//  Prayer
//
//  Created by Ben on 3/29/20.
//  Copyright © 2020 Ben. All rights reserved.
//
//

import Foundation
import CoreData


extension PrayerEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PrayerEntity> {
        return NSFetchRequest<PrayerEntity>(entityName: "PrayerEntity")
    }

    @NSManaged public var answerDescriptionAttribute: String?
    @NSManaged public var answeredAffirmativelyAttribute: Bool
    @NSManaged public var answeredAttribute: Bool
    @NSManaged public var archivedAttribute: Bool
    @NSManaged public var descriptionAttribute: String?
    @NSManaged public var idAttribute: UUID?
    @NSManaged public var titleAttribute: String?
    
    @NSManaged public var dateAnsweredRelationship: DateEntity?
    @NSManaged public var datesPrayedRelationship: NSSet?
    @NSManaged public var personRelationship: PersonEntity?
    @NSManaged public var tagsRelationship: NSSet?
    
    public var id: UUID{
        get{idAttribute ?? UUID()}
        set{idAttribute = newValue}
    }
    
    public var title: String{
        get{titleAttribute ?? ""}
        set{titleAttribute = newValue}
    }
    
    public var descriptionText: String{
        get{descriptionAttribute ?? ""}
        set{descriptionAttribute = newValue}
    }
    
    public var datesPrayed: [DateEntity] {
        let dates = datesPrayedRelationship as? Set<DateEntity> ?? []
        return dates.sorted {$0.date < $1.date}
    }
    
    public var tags: [TagEntity] {
        let tags = tagsRelationship as? Set<TagEntity> ?? []
        return tags.sorted {$0.title < $1.title}
    }
}

extension PrayerEntity: Comparable
{
    public static func == (left: PrayerEntity, right: PrayerEntity) -> Bool
    {
        return left.id == right.id
    }
    
    public static func < (left: PrayerEntity, right: PrayerEntity) -> Bool
    {
        if (left.titleAttribute != right.titleAttribute) {return left.titleAttribute < right.titleAttribute}
        if (left.personRelationship != right.personRelationship) {return left.personRelationship < right.personRelationship}
        return left.id < right.id
    }
}

// MARK: Generated accessors for datesPrayedRelationship
extension PrayerEntity {

    @objc(addDatesPrayedRelationshipObject:)
    @NSManaged public func addToDatesPrayedRelationship(_ value: DateEntity)

    @objc(removeDatesPrayedRelationshipObject:)
    @NSManaged public func removeFromDatesPrayedRelationship(_ value: DateEntity)

    @objc(addDatesPrayedRelationship:)
    @NSManaged public func addToDatesPrayedRelationship(_ values: NSSet)

    @objc(removeDatesPrayedRelationship:)
    @NSManaged public func removeFromDatesPrayedRelationship(_ values: NSSet)
}

// MARK: Generated accessors for tagsRelationship
extension PrayerEntity {

    @objc(addTagsRelationshipObject:)
    @NSManaged public func addToTagsRelationship(_ value: TagEntity)

    @objc(removeTagsRelationshipObject:)
    @NSManaged public func removeFromTagsRelationship(_ value: TagEntity)

    @objc(addTagsRelationship:)
    @NSManaged public func addToTagsRelationship(_ values: NSSet)

    @objc(removeTagsRelationship:)
    @NSManaged public func removeFromTagsRelationship(_ values: NSSet)
}

// MARK: Utilities
func deletePrayer(prayer: PrayerEntity)
{
    let moc = prayer.managedObjectContext!

    for prayed_on_date in prayer.datesPrayed
    {
        prayer.removeFromDatesPrayedRelationship(prayed_on_date)
        deleteDateIfEmtpy(date: prayed_on_date)
    }
    
    if let answered_date = prayer.dateAnsweredRelationship
    {
        deleteDateIfEmtpy(date: answered_date)
    }
    
    moc.delete(prayer)

    // 2020-12-29
    // If the if moc.hasChanges block is executed, the try moc.save() call crashes the program
    // because of a simultaneous access to a memory location that has to be protected.  I don't
    // know why.  This appears to fix it, but I'm sure it's not the right way to go about this.
    return

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
