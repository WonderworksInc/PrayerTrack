//
//  PersonEntity+CoreDataProperties.swift
//  Prayer
//
//  Created by Ben on 3/28/20.
//  Copyright © 2020 Ben. All rights reserved.
//
//

import Foundation
import CoreData


extension PersonEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PersonEntity> {
        return NSFetchRequest<PersonEntity>(entityName: "PersonEntity")
    }

    @NSManaged public var idAttribute: UUID?
    @NSManaged public var nameAttribute: String?
    @NSManaged public var prayersRelationship: NSSet?
    
    public var id: UUID{
        get{idAttribute ?? UUID()}
        set{idAttribute = newValue}
    }
    
    public var name: String{
        get{nameAttribute ?? "Unknown name"}
        set{nameAttribute = newValue}
    }

    public var prayers: [PrayerEntity] {
        let prayers = prayersRelationship as? Set<PrayerEntity> ?? []
        return prayers.sorted(by: {$0 < $1})
    }
}

extension PersonEntity: Comparable
{
    public static func == (left: PersonEntity, right: PersonEntity) -> Bool
    {
        return left.id == right.id
    }
    
    public static func < (left: PersonEntity, right: PersonEntity) -> Bool
    {
        if (left.nameAttribute != right.nameAttribute) {return left.nameAttribute < right.nameAttribute}
        return left.id < right.id
    }
}

extension UUID
{
    static func < (left: UUID, right: UUID) -> Bool
    {
        if (left.uuid.0 != right.uuid.0) {return left.uuid.0 < right.uuid.0}
        if (left.uuid.1 != right.uuid.1) {return left.uuid.1 < right.uuid.1}
        if (left.uuid.2 != right.uuid.2) {return left.uuid.2 < right.uuid.2}
        if (left.uuid.3 != right.uuid.3) {return left.uuid.3 < right.uuid.3}
        if (left.uuid.4 != right.uuid.4) {return left.uuid.4 < right.uuid.4}
        if (left.uuid.5 != right.uuid.5) {return left.uuid.5 < right.uuid.5}
        if (left.uuid.6 != right.uuid.6) {return left.uuid.6 < right.uuid.6}
        if (left.uuid.7 != right.uuid.7) {return left.uuid.7 < right.uuid.7}
        if (left.uuid.8 != right.uuid.8) {return left.uuid.8 < right.uuid.8}
        if (left.uuid.9 != right.uuid.9) {return left.uuid.9 < right.uuid.9}
        if (left.uuid.10 != right.uuid.10) {return left.uuid.10 < right.uuid.10}
        if (left.uuid.11 != right.uuid.11) {return left.uuid.11 < right.uuid.11}
        if (left.uuid.12 != right.uuid.12) {return left.uuid.12 < right.uuid.12}
        if (left.uuid.13 != right.uuid.13) {return left.uuid.13 < right.uuid.13}
        if (left.uuid.14 != right.uuid.14) {return left.uuid.14 < right.uuid.14}
        if (left.uuid.15 != right.uuid.15) {return left.uuid.15 < right.uuid.15}
        
        return false
    }
}

// MARK: Generated accessors for prayersRelationship
extension PersonEntity {

    @objc(addPrayersRelationshipObject:)
    @NSManaged public func addToPrayersRelationship(_ value: PrayerEntity)

    @objc(removePrayersRelationshipObject:)
    @NSManaged public func removeFromPrayersRelationship(_ value: PrayerEntity)

    @objc(addPrayersRelationship:)
    @NSManaged public func addToPrayersRelationship(_ values: NSSet)

    @objc(removePrayersRelationship:)
    @NSManaged public func removeFromPrayersRelationship(_ values: NSSet)

}
