//
//  ITCoreDataOperationQueue.swift
//  CoreDataStack-Swift
//
//  Created by Aliaksandr Skulin on 1/12/16.
//  Copyright © 2016 Aliaksandr Skulin. All rights reserved.
//

import UIKit
import CoreData

public class ITCoreDataOperationQueue: NSObject {
    
    internal var model : NSManagedObjectModel? = nil
    internal var readOnlyContext : NSManagedObjectContext? = nil
    internal var changesContext : NSManagedObjectContext? = nil
    internal var loggingLevel : ITLogLevel = .None
    
    public init(model: NSManagedObjectModel!, managedObjectContext: NSManagedObjectContext!, readOnlyObjectContext: NSManagedObjectContext!) {
        super.init()
        self.model = model
        self.readOnlyContext = readOnlyObjectContext
        self.changesContext = managedObjectContext
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "contextDidSave:", name: NSManagedObjectContextDidSaveNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //MARK: - Class Methods
    
    public class func applicationDocumentsDirectory() -> NSURL? {
        return NSURL(string: NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0])
    }
    
    //MARK: - Public
    
    public func executeMainThreadOperation(mainThreadOperation: (context: NSManagedObjectContext) -> Void) {
        self.readOnlyContext!.performBlock { () -> Void in
            mainThreadOperation(context: self.readOnlyContext!)
        }
    }

    public func executeOperation(operation: (context: NSManagedObjectContext) -> Void) {
        self.changesContext!.performBlock { () -> Void in
            operation(context: self.changesContext!)
            do {
                try self.changesContext!.save()
            } catch {
                self.logError("Error saving context: \(self.changesContext)")
            }
        }
    }
    
    public func executeOperation(backgroundOperation: (context: NSManagedObjectContext) -> NSArray, mainThreadOperation: ((result: NSArray?) -> Void)?) {
        let mainThreadOperationBlock = {(array: NSArray?) -> Void in
            if (mainThreadOperation != nil) {
                if (NSThread.isMainThread()) {
                    mainThreadOperation!(result: array)
                } else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        mainThreadOperation!(result: array)
                    })
                }
            }
        }
        var result: NSArray?
        self.executeOperation { (context) -> Void in
            result = backgroundOperation(context: context)
            if (context.hasChanges) {
                do {
                    try context.save()
                } catch {
                    self.logError("Error saving context: \(context)")
                    mainThreadOperationBlock(nil);
                    return;
                }
            }
            if (result == nil) {
                mainThreadOperationBlock(nil)
                return
            }
            if (result!.count > 0 && mainThreadOperation != nil) {
                let objectIDs : NSArray = result!.valueForKey("objectID") as! NSArray
                self.executeMainThreadOperation({ (context) -> Void in
                    let entity: String = (result!.firstObject as! NSManagedObject).entity.name!
                    let request: NSFetchRequest = NSFetchRequest(entityName: entity)
                    request.predicate = NSPredicate(format: "SELF IN %@", objectIDs)
                    request.includesSubentities = false
                    var fetchResult: NSArray? = nil
                    do {
                        fetchResult = try context.executeFetchRequest(request)
                    } catch {
                        self.logError("Error fetching request: \(request)")
                    }
                    mainThreadOperationBlock(fetchResult)
                })
            } else {
                mainThreadOperationBlock(nil)
            }
        }
    }
    
    //MARK: - Notifications
    
    @objc private func contextDidSave(notification: NSNotification) {
        let context : NSManagedObjectContext = notification.object! as! NSManagedObjectContext
        if (context.isEqual(self.readOnlyContext)) {
            assert(false, "Saving read only context is not allowed, use background context")
        } else if (context.isEqual(self.changesContext)) {
            self.readOnlyContext!.performBlock({ () -> Void in
                if (self.readOnlyContext!.hasChanges) {
                    self.readOnlyContext!.rollback()
                }
                let updated: NSArray? = (notification.userInfo! as NSDictionary).valueForKey(NSUpdatedObjectsKey) as? NSArray
                if (updated != nil) {
                    for (obj) in updated! {
                        var mainThreadObject: NSManagedObject? = nil
                        do {
                            mainThreadObject = try self.readOnlyContext!.existingObjectWithID((obj as! NSManagedObject).objectID)
                        } catch {
                            self.logError("Error fetching existing object: \(obj)")
                        }
                        mainThreadObject!.willAccessValueForKey(nil)
                    }
                }
                self.readOnlyContext!.mergeChangesFromContextDidSaveNotification(notification)
            })
        }
    }
    
}
