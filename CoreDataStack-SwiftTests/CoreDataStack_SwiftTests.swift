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
        let modelURL = NSBundle(forClass: CoreDataStack_SwiftTests.self).URLForResource("TestModel", withExtension: "momd")
        self.databaseQueue = ITCoreDataOperationQueue(model: NSManagedObjectModel(contentsOfURL: modelURL!)!, storeName: storeName, storeType: NSInMemoryStoreType)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    

    func testThatBackroundContextReturnObjectInMainContext() {
        let expextation: XCTestExpectation = self.expectationWithDescription("Wait expectation")
        self.databaseQueue.executeOperation({ (context, completion) -> Void in
            let object: TestEntity? = TestEntity.insertObject(context)
            if (object == nil) {
                return completion(result: nil)
            } else {
                return completion(result: [object!])
            }
        }) { (result) -> Void in
            let object: TestEntity = result!.firstObject as! TestEntity;
            XCTAssertNotNil(object);
            XCTAssert(object.managedObjectContext!.concurrencyType == .MainQueueConcurrencyType, "returned object is not in main context");
            expextation.fulfill()
        }
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }
}
