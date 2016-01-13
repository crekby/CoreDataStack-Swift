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
    
    public class func insertObject(context: NSManagedObjectContext) -> Self? {
        return insert(context)
    }
    
    private class func insert<T>(context: NSManagedObjectContext) -> T? {
        let object = NSEntityDescription.insertNewObjectForEntityForName(NSStringFromClass(self).componentsSeparatedByString(".").last!, inManagedObjectContext: context) as! T
        return object
    }

}
