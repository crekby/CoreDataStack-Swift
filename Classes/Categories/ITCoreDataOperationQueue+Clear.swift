//
//  ITCoreDataOperationQueue+Clear.swift
//  CoreDataStack-Swift
//
//  Created by Aliaksandr Skulin on 1/12/16.
//  Copyright © 2016 Aliaksandr Skulin. All rights reserved.
//

import UIKit
import CoreData

extension ITCoreDataOperationQueue {
    
    func clearAllEntities(completion:(() -> Void)?) {
        self.changesContext!.performBlock { () -> Void in
            let allEntities: NSArray = self.model!.entities
            allEntities.enumerateObjectsUsingBlock({ (entityDescription, idx, stop) -> Void in
                let request: NSFetchRequest = NSFetchRequest(entityName: entityDescription.name)
                let results: NSArray
                do {
                    results = try self.changesContext!.executeFetchRequest(request)
                } catch {
                    self.logError("Error fetching request: \(request)")
                    if (completion != nil) {
                        completion!()
                    }
                    return
                }
                for (object) in results {
                    self.changesContext!.delete(object)
                }
            })
            do {
                try self.changesContext!.save()
            } catch {
                self.logError("Error saving context: \(self.changesContext)")
            }
            if (completion != nil) {
                completion!()
            }
        }
    }

}
