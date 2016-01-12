//
//  NSManagedObject+Additions.swift
//  CoreDataStack-Swift
//
//  Created by Aliaksandr Skulin on 1/12/16.
//  Copyright © 2016 Aliaksandr Skulin. All rights reserved.
//

import UIKit
import CoreData

extension NSManagedObject {
    
    class func insertObject(context: NSManagedObjectContext) -> NSManagedObject? {
        let object: NSManagedObject? = NSEntityDescription.insertNewObjectForEntityForName(NSStringFromClass(self), inManagedObjectContext: context)
        return object
    }

}
