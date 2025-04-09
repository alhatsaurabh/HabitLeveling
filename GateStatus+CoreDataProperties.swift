//
//  GateStatus+CoreDataProperties.swift
//  HabitLeveling
//
//  Created by Saurabh on 03.04.25.
//
//

import Foundation
import CoreData


extension GateStatus {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GateStatus> {
        return NSFetchRequest<GateStatus>(entityName: "GateStatus")
    }

    @NSManaged public var clearConditionDescription: String?
    @NSManaged public var gateRank: String?
    @NSManaged public var gateType: String?
    @NSManaged public var id: UUID?
    @NSManaged public var rewardDescription: String?
    @NSManaged public var status: String?
    @NSManaged public var statusChangeDate: Date?

}

extension GateStatus : Identifiable {

}
