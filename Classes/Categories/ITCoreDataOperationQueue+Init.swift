//
//  ITCoreDataOperationQueue+Init.swift
//  CoreDataStack-Swift
//
//  Created by Aliaksandr Skulin on 1/12/16.
//  Copyright © 2016 Aliaksandr Skulin. All rights reserved.
//

import CoreData

extension ITCoreDataOperationQueue {
    
    convenience public init(model: NSManagedObjectModel, storeURL: URL, storeType: String) {
        let storeCoordinator: NSPersistentStoreCoordinator = ITCoreDataOperationQueue.newPersistenceStoreCoordinator(model: model, storeURL: storeURL, storeType: storeType)
        
        let backgroundManagedObjectContext: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundManagedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        backgroundManagedObjectContext.persistentStoreCoordinator = storeCoordinator
        backgroundManagedObjectContext.name = "ITDatabaseManager.BackgroundQueue"
        
        let mainManagedObjectContext: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainManagedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        mainManagedObjectContext.persistentStoreCoordinator = storeCoordinator
        mainManagedObjectContext.name = "ITDatabaseManager.MainQueue"
        
        self.init(model: model, managedObjectContext: backgroundManagedObjectContext, readOnlyObjectContext: mainManagedObjectContext)
    }
    
    convenience public init(model: NSManagedObjectModel, storeName: String, storeType: String) {
        let storeURL = URL(fileURLWithPath: ITCoreDataOperationQueue.applicationDocumentsDirectory.appendingPathComponent(storeName).path)
        self.init(model: model, storeURL: storeURL, storeType: storeType)
    }
    
    private class func newPersistenceStoreCoordinator(model: NSManagedObjectModel, storeURL: URL, storeType: String) -> NSPersistentStoreCoordinator {
        let persistentStoreCoordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel:model)
        
        do {
            let exist = (try? ITCoreDataOperationQueue.persistentStoreExists(url: storeURL)) ?? false
            if (exist == false) {
                if (!ITCoreDataOperationQueue.isModelCompatible(model: model, url: storeURL, storeType: storeType)) {
                    print("[ITCoreDataOperationQueue]: Merge is needed")
                }
            }
            
            try persistentStoreCoordinator.addPersistentStore(ofType: storeType, configurationName: nil, at: storeURL, options: self.storeOptions())
        } catch let error as NSError {
            print("[ITCoreDataOperationQueue]: Errorr adding persistence store: \(error)")
        }
        return persistentStoreCoordinator
    }
    
    //MARK: - Helpers
    
    private class func persistentStoreExists(url: URL) throws -> Bool {
        return try url.checkResourceIsReachable()
    }
    
    private class func isModelCompatible(model: NSManagedObjectModel, url: URL, storeType: String) -> Bool {
        let exist: Bool = (try? ITCoreDataOperationQueue.persistentStoreExists(url: url)) ?? false
        if (!exist) {
            return false
        }
        guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: storeType, at: url, options: self.storeOptions()) else {
            return false
        }
        
        let compatible: Bool = model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        return compatible
    }
    
    private class func storeOptions() -> [String : Any] {
        return [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true]
    }
    
}
