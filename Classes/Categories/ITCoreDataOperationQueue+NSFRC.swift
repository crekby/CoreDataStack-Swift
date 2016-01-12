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
    
    func newController(request: NSFetchRequest, keyPath: String?, delegate: NSFetchedResultsControllerDelegate?) -> NSFetchedResultsController? {
        assert(request.sortDescriptors!.count > 0, "NSFetchedResultController requres sort descriptors.")
        assert(request.resultType == .ManagedObjectResultType, "NSFetchedResultController requires NSManagedObject Result Type")
        
        let controller: NSFetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.readOnlyContext!, sectionNameKeyPath: keyPath, cacheName: nil)
        controller.delegate = delegate
        
        do {
            try controller.performFetch()
        } catch {
            self.logError("Error fetching request: \(request)")
            return nil;
        }
        return controller
    }

    func newController(request: NSFetchRequest, delegate: NSFetchedResultsControllerDelegate?) -> NSFetchedResultsController? {
        return self.newController(request, keyPath: nil, delegate: delegate)
    }
    
}
