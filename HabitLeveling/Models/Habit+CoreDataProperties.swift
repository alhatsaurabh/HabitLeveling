//
//  Habit+CoreDataProperties.swift
//  HabitLeveling
//
//  Created by Saurabh on 04.04.25.
//
//

import Foundation
import CoreData


extension Habit {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Habit> {
        return NSFetchRequest<Habit>(entityName: "Habit")
    }

    @NSManaged public var category: String?
    @NSManaged public var creationDate: Date?
    @NSManaged public var cue: String?
    @NSManaged public var frequency: String?
    @NSManaged public var habitDescription: String?
    @NSManaged public var id: UUID?
    @NSManaged public var isTwoMinuteVersion: Bool
    @NSManaged public var lastCompletedDate: Date?
    @NSManaged public var name: String?
    @NSManaged public var notificationTime: Date?
    @NSManaged public var statCategory: String?
    @NSManaged public var streak: Int64
    @NSManaged public var xpValue: Int64

}

extension Habit : Identifiable {

}
