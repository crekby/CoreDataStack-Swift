//
//  ITCoreDataOperationQueue+NSFRC.swift
//  CoreDataStack-Swift
//
//  Created by Aliaksandr Skulin on 1/12/16.
//  Copyright © 2016 Aliaksandr Skulin. All rights reserved.
//

import UIKit
import CoreData

extension ITCoreDataOperationQueue {
    
    @available(iOS 3.0, *)
    public func newController<T: NSFetchRequestResult>(request: NSFetchRequest<T>, keyPath: String?, delegate: NSFetchedResultsControllerDelegate? = nil) -> NSFetchedResultsController<T>? {
        assert(request.sortDescriptors!.count > 0, "NSFetchedResultController requres sort descriptors.")
        assert(request.resultType == .managedObjectResultType, "NSFetchedResultController requires NSManagedObject Result Type")
    
        guard let readOnlyContext = readOnlyContext else {
            fatalError("Read only context is nil")
        }
        let controller = NSFetchedResultsController<T>(fetchRequest: request, managedObjectContext: readOnlyContext, sectionNameKeyPath: keyPath, cacheName: nil)
        controller.delegate = delegate
        
        do {
            try controller.performFetch()
        } catch let error as NSError {
            self.logError(error: error)
            return nil;
        }
        return controller
    }

    @available(iOS 3.0, *)
    public func newController<T: NSFetchRequestResult>(request: NSFetchRequest<T>, delegate: NSFetchedResultsControllerDelegate? = nil) -> NSFetchedResultsController<T>? {
        return self.newController(request: request, keyPath: nil, delegate: delegate)
    }
    
}
