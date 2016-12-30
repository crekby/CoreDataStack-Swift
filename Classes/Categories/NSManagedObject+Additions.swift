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
        return insert(context: context)
    }
    
    private class func insert<T: NSManagedObject>(context: NSManagedObjectContext) -> T? {
        guard let object = NSEntityDescription.insertNewObject(forEntityName: String(describing: T.self), into: context) as? T else {
            fatalError()
        }
        return object
    }

}
