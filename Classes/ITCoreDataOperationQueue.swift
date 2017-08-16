//
//  ITCoreDataOperationQueue.swift
//  CoreDataStack-Swift
//
//  Created by Aliaksandr Skulin on 1/12/16.
//  Copyright © 2016 Aliaksandr Skulin. All rights reserved.
//

import CoreData

/**
 ITCoreDataOperationQueue class for managing core data operations for 2 NSManagedObjectContexts, one is for main thread, and other is for background.
 You only allowed to make changes to your data in background context.
 Main context is only for fetching data and use it for UI related manipulation.
 Both contexts have same persistence store coordinator.
 And after saving changes in background context, they are merged to main context.
 */
public class ITCoreDataOperationQueue {
    
    /**
     URL to Documents directory in application sandbox.
     */
    public class var applicationDocumentsDirectory: URL {
        get {
            guard let url = URL(string: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]) else {
                fatalError("Documents directory not found")
            }
            return url
        }
    }
    
    internal var model : NSManagedObjectModel? = nil
    internal var readOnlyContext : NSManagedObjectContext? = nil
    internal var changesContext : NSManagedObjectContext? = nil
    internal var loggingLevel : ITLogLevel = .None
    
    
    /**
     Returns initialised database operations queue with given contexts and model. If you don't want to initialise contexts by yourself, you can use method initWithModel:storeName:storeType: declared in Init category
     - parameters:
         - model: core data model
         - managedObjectContext: context with allowed changes
         - readOnlyObjectContext: context only for read only operations
     */
    public init(model: NSManagedObjectModel, managedObjectContext: NSManagedObjectContext, readOnlyObjectContext: NSManagedObjectContext) {
        self.model = model
        self.readOnlyContext = readOnlyObjectContext
        self.changesContext = managedObjectContext
        NotificationCenter.default.addObserver(self, selector: #selector(contextDidSave(notification:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - Public
    
    /**
     Executes given block in read only context.
     - warning: DO NOT USE READ ONLY CONTEXT FOR CHANGES, USE IT ONLY FOR FETCHING.
     - parameters:
         - backgroundOperation: Block for execution.
     */
    public func executeMainThreadOperation(mainThreadOperation: @escaping (_ context: NSManagedObjectContext) -> Void) {
        guard let readOnlyContext = readOnlyContext else {
            return
        }
        readOnlyContext.perform { () -> Void in
            mainThreadOperation(self.readOnlyContext!)
        }
    }

    /**
     Executes given block in background.
     - warning: USE BACKGROUND CONTEXT FOR MAKING CHANGES IN YOUR MODEL, NOT MAIN CONTEXT.
     - parameters:
         - operation: Block for execution.
     */
    public func executeOperation(operation: @escaping (_ context: NSManagedObjectContext) -> Void) {
        guard let changesContext = changesContext else {
            return
        }
        changesContext.perform { () -> Void in
            operation(changesContext)
            do {
                try changesContext.save()
            } catch let error as NSError {
                self.logError(error: error)
            }
        }
    }
    
    /**
     Executes given blocks in background and in read only contexts respectively. Background block should return fetched data or nil.
     - parameters:
         - backgroundOperation: Block for background context execution, use it to fetching and changing your data. return your results from this block.
         - mainThreadOperation: Block for mainThread context execution, result from backgroun operation sending to this block from main context.
     */
    public func executeOperation<T: NSManagedObject>(backgroundOperation: @escaping (_ context: NSManagedObjectContext, _ completion:(_ result: [T]?) -> ()) -> Void, mainThreadOperation: ((_ result: [T]?) -> Void)?) {
        let mainThreadOperationBlock = {(array: [T]?) -> Void in
            if (Thread.isMainThread) {
                mainThreadOperation?(array)
            } else {
                DispatchQueue.main.async {
                    mainThreadOperation?(array)
                }
            }
        }
        var resultArray: [T]?
        self.executeOperation { (context) -> Void in
            backgroundOperation(context, {(result) -> Void in
                resultArray = result;
            })
            if (context.hasChanges) {
                do {
                    try context.save()
                } catch let error as NSError {
                    self.logError(error: error)
                    mainThreadOperationBlock(nil);
                    return;
                }
            }
            guard let resultArray = resultArray else {
                mainThreadOperationBlock(nil)
                return
            }
            if (resultArray.count > 0 && mainThreadOperation != nil) {
                
                let objectIDs = resultArray.map {
                    return $0.objectID
                }
                self.executeMainThreadOperation(mainThreadOperation: { (context) -> Void in
                    guard let entity = resultArray.first?.entity.name else {
                        mainThreadOperationBlock(nil)
                        return
                    }
                    let request = NSFetchRequest<T>(entityName: entity)
                    request.predicate = NSPredicate(format: "SELF IN %@", objectIDs)
                    request.includesSubentities = false
                    var fetchResult: [T]?
                    do {
                        fetchResult = try (context.execute(request) as? NSAsynchronousFetchResult)?.finalResult
                    } catch let error as NSError {
                        self.logError(error: error)
                    }
                    mainThreadOperationBlock(fetchResult)
                })
            } else {
                mainThreadOperationBlock(nil)
            }
        }
    }
    
    //MARK: - Notifications
    
    dynamic fileprivate func contextDidSave(notification: Notification) {
        let context : NSManagedObjectContext = notification.object! as! NSManagedObjectContext
        if (context.isEqual(self.readOnlyContext)) {
            fatalError("Saving read only context is not allowed, use background context")
        } else if (context.isEqual(self.changesContext)) {
            guard let readOnlyContext = readOnlyContext else {
                fatalError("Read only context in nil")
            }
            readOnlyContext.perform({ () -> Void in
                
                if let updated = notification.userInfo?[NSUpdatedObjectsKey] as? [NSManagedObject] {
                    for obj in updated {
                        var mainThreadObject: NSManagedObject? = nil
                        do {
                            mainThreadObject = try readOnlyContext.existingObject(with: obj.objectID)
                        } catch let error as NSError {
                            self.logError(error: error)
                        }
                        mainThreadObject?.willAccessValue(forKey: nil)
                    }
                }
                readOnlyContext.mergeChanges(fromContextDidSave: notification)
                if !readOnlyContext.deletedObjects.isEmpty {
                    do {
                        try readOnlyContext.save()
                    } catch let error as NSError {
                        self.logError(error: error)
                    }
                }
            })
        }
    }
    
}
