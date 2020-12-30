//
//  TagEntity+CoreDataProperties.swift
//  Prayer
//
//  Created by Ben on 4/4/20.
//  Copyright © 2020 Ben. All rights reserved.
//
//

import Foundation
import CoreData


extension TagEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TagEntity> {
        return NSFetchRequest<TagEntity>(entityName: "TagEntity")
    }

    @NSManaged public var idAttribute: UUID?
    @NSManaged public var titleAttribute: String?
    @NSManaged public var prayersRelationship: NSSet?

    public var id: UUID{
        get{idAttribute ?? UUID()}
        set{idAttribute = newValue}
    }
    
    public var title: String{
        get{titleAttribute ?? ""}
        set{titleAttribute = newValue}
    }
    
    public var prayers: [PrayerEntity] {
        let prayers = prayersRelationship as? Set<PrayerEntity> ?? []
        return prayers.sorted(by: {$0 < $1})
    }
}

extension TagEntity: Comparable
{
    public static func == (left: TagEntity, right: TagEntity) -> Bool
    {
        return left.id == right.id
    }
    
    public static func < (left: TagEntity, right: TagEntity) -> Bool
    {
        if (left.titleAttribute != right.titleAttribute) {return left.titleAttribute < right.titleAttribute}
        return left.id < right.id
    }
}

// MARK: Generated accessors for prayersRelationship
extension TagEntity {

    @objc(addPrayersRelationshipObject:)
    @NSManaged public func addToPrayersRelationship(_ value: PrayerEntity)

    @objc(removePrayersRelationshipObject:)
    @NSManaged public func removeFromPrayersRelationship(_ value: PrayerEntity)

    @objc(addPrayersRelationship:)
    @NSManaged public func addToPrayersRelationship(_ values: NSSet)

    @objc(removePrayersRelationship:)
    @NSManaged public func removeFromPrayersRelationship(_ values: NSSet)

}
