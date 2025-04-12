//
//  UserProfile+CoreDataProperties.swift
//  HabitLeveling
//
//  Created by Saurabh on 04.04.25.
//
//

import Foundation
import CoreData


extension UserProfile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProfile> {
        return NSFetchRequest<UserProfile>(entityName: "UserProfile")
    }

    @NSManaged public var essenceCoreState: String?
    @NSManaged public var job: String?
    @NSManaged public var lastLoginDate: Date?
    @NSManaged public var level: Int64
    @NSManaged public var manaCrystals: Int64
    @NSManaged public var title: String?
    @NSManaged public var totalManaSpent: Int64
    @NSManaged public var xp: Int64

}

extension UserProfile : Identifiable {

}
