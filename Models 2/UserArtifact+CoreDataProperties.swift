//
//  UserArtifact+CoreDataProperties.swift
//  HabitLeveling
//
//  Created by Saurabh on 04.04.25.
//
//

import Foundation
import CoreData


extension UserArtifact {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserArtifact> {
        return NSFetchRequest<UserArtifact>(entityName: "UserArtifact")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var acquiredDate: Date?
    @NSManaged public var isEquipped: Bool
    @NSManaged public var profile: UserProfile?
    @NSManaged public var artifact: Artifact?

}

extension UserArtifact : Identifiable {

}
