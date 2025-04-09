//
//  HabitLog+CoreDataProperties.swift
//  HabitLeveling
//
//  Created by Saurabh on 04.04.25.
//
//

import Foundation
import CoreData


extension HabitLog {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HabitLog> {
        return NSFetchRequest<HabitLog>(entityName: "HabitLog")
    }

    @NSManaged public var completionDate: Date?
    @NSManaged public var habitID: UUID?

}

extension HabitLog : Identifiable {

}
