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
    
    public func clearAllEntities(completion:(() -> Void)?) {
        self.changesContext!.performBlock { () -> Void in
            let allEntities: NSArray = self.model!.entities
            allEntities.enumerateObjectsUsingBlock({ (entityDescription, idx, stop) -> Void in
                let request: NSFetchRequest = NSFetchRequest(entityName: entityDescription.name)
                let results: NSArray
                do {
                    results = try self.changesContext!.executeFetchRequest(request)
                } catch let error as NSError {
                    self.logError(error)
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
            } catch let error as NSError {
                self.logError(error)
            }
            if (completion != nil) {
                completion!()
            }
        }
    }

}
