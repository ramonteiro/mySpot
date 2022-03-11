//
//  CoreDataManager.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/21/22.
//

import Foundation
import CoreData

class CoreDataManager: ObservableObject {
    let container: NSPersistentContainer
    
    init() {
        
        ValueTransformer.setValueTransformer(UIImageTransformer(), forName: NSValueTransformerName("UIImageTransformer"))
        
        container = NSPersistentContainer(name: "Spots")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to init core data \(error)")
            }
        }
        
        self.container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
}
