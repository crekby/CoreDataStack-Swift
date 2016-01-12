//
//  ITCoreDataOperationQueue+Init.swift
//  CoreDataStack-Swift
//
//  Created by Aliaksandr Skulin on 1/12/16.
//  Copyright © 2016 Aliaksandr Skulin. All rights reserved.
//

import UIKit
import CoreData

extension ITCoreDataOperationQueue {
    
    convenience init(model: NSManagedObjectModel, storeName: String, storeType: String) {
        let storeCoordinator: NSPersistentStoreCoordinator = self.newPersistenceStoreCoordinator(model, storeName: storeName, storeType: storeType)
        
        let backgroundManagedObjectContext: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        backgroundManagedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        backgroundManagedObjectContext.persistentStoreCoordinator = storeCoordinator
        backgroundManagedObjectContext.name = "ITDatabaseManager.BackgroundQueue"
        
        let mainManagedObjectContext: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        mainManagedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        mainManagedObjectContext.persistentStoreCoordinator = storeCoordinator
        mainManagedObjectContext.name = "ITDatabaseManager.MainQueue"
        
        self.init(model: model, managedObjectContext: backgroundManagedObjectContext, readOnlyObjectContext: mainManagedObjectContext)
    }
    
    private func newPersistenceStoreCoordinator(model: NSManagedObjectModel, storeName: String, storeType: String) -> NSPersistentStoreCoordinator {
        let persistentStoreCoordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel:model)
        let storeURL: NSURL = (ITCoreDataOperationQueue.applicationDocumentsDirectory()?.URLByAppendingPathComponent(storeName)
        )!
        let error: NSErrorPointer
        let exist: Bool = self.persistentStoreExists(storeURL, errorPointer: error)
        
        if (exist) {
            let compatible = self.isModelCompatible(model, url: storeURL, storeType: storeType)
            if (!compatible) {
                //TODO: add logging
            }
        }
        do {
            try persistentStoreCoordinator.addPersistentStoreWithType(storeType, configuration: nil, URL: storeURL, options: self.storeOptions())
        } catch {
            //TODO: add logging
        }
        return persistentStoreCoordinator
    }

    //MARK: - Helpers
    
    private func persistentStoreExists(url: NSURL, errorPointer: NSErrorPointer) -> Bool {
        let resourceIsReachable: Bool = url.checkResourceIsReachableAndReturnError(errorPointer)
        return resourceIsReachable
    }

    private func isModelCompatible(model: NSManagedObjectModel, url: NSURL, storeType: String) -> Bool {
        let error: NSErrorPointer
        let exist: Bool = self.persistentStoreExists(url, errorPointer: error)
        if (!exist) {
            return false
        }
        let metadata: NSDictionary?
        do {
            metadata = try NSPersistentStoreCoordinator.metadataForPersistentStoreOfType(storeType, URL: url, options: self.storeOptions())
        } catch {
            // TODO: add logging
            return false
        }
        
        if (metadata == nil) {
            return false
        }
        
        let compatible: Bool = model.isConfiguration(nil, compatibleWithStoreMetadata: metadata! as! [String : AnyObject])
        return compatible
    }
    
    private func storeOptions() -> [NSObject : AnyObject] {
        return [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true]
    }

}
