//
//  ITCoreDataOperationQueue+Clear.swift
//  CoreDataStack-Swift
//
//  Created by Aliaksandr Skulin on 1/12/16.
//  Copyright © 2016 Aliaksandr Skulin. All rights reserved.
//

import CoreData

extension ITCoreDataOperationQueue {
    
    public func clearAllEntities(completion:(() -> Void)?) {
        guard let model = model else {
            fatalError("Model is nil")
        }
        guard let changesContext = changesContext else {
            return
        }
        changesContext.perform { () -> Void in
            let allEntities = model.entities
            for entityDescription in allEntities {
                guard let name = entityDescription.name else {
                    continue
                }
                let request: NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: name)
                let results: [NSManagedObject]?
                do {
                    results = try (changesContext.execute(request) as? NSAsynchronousFetchResult)?.finalResult
                } catch let error as NSError {
                    self.logError(error: error)
                    completion?()
                    return
                }
                for object in results ?? [] {
                    self.changesContext!.delete(object)
                }
            }
            do {
                try changesContext.save()
            } catch let error as NSError {
                self.logError(error: error)
            }
            completion?()
        }
    }

}
