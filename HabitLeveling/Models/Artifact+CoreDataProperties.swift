//
//  Artifact+CoreDataProperties.swift
//  HabitLeveling
//
//  Created by Saurabh on 04.04.25.
//
//

import Foundation
import CoreData


extension Artifact {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Artifact> {
        return NSFetchRequest<Artifact>(entityName: "Artifact")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var desc: String?
    @NSManaged public var imageName: String?
    @NSManaged public var rarity: String?
    @NSManaged public var statBoostType: String?
    @NSManaged public var statBoostValue: Double
    @NSManaged public var acquisitionCondition: String?
    @NSManaged public var userInstances: UserArtifact?

}

extension Artifact : Identifiable {

}
