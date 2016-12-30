//
//  CoreDataStack_SwiftTests.swift
//  CoreDataStack-SwiftTests
//
//  Created by Aliaksandr Skulin on 1/12/16.
//  Copyright © 2016 Aliaksandr Skulin. All rights reserved.
//

import XCTest
import CoreData

@testable import CoreDataStack

class CoreDataStack_SwiftTests: XCTestCase {
    
    var databaseQueue: ITCoreDataOperationQueue!
    
    override func setUp() {
        super.setUp()
        let storeName: String = NSStringFromSelector(self.invocation!.selector)
        let modelURL = Bundle(for: CoreDataStack_SwiftTests.self).url(forResource: "TestModel", withExtension: "momd")
        self.databaseQueue = ITCoreDataOperationQueue(model: NSManagedObjectModel(contentsOf: modelURL!)!, storeName: storeName, storeType: NSInMemoryStoreType)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    

    func testThatBackroundContextReturnObjectInMainContext() {
        let expextation = self.expectation(description: "Wait expectation")
    
        self.databaseQueue.executeOperation(backgroundOperation: { (context, completion) -> Void in
            let object: TestEntity? = TestEntity.insertObject(context: context)
            if (object == nil) {
                return completion(nil)
            } else {
                return completion([object!])
            }
        }) { (result) -> Void in
            let object: TestEntity = result!.first as! TestEntity;
            XCTAssertNotNil(object);
            XCTAssert(object.managedObjectContext!.concurrencyType == .mainQueueConcurrencyType, "returned object is not in main context");
            expextation.fulfill()
        }
        self.waitForExpectations(timeout: 5, handler: nil)
    }
}
