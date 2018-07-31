//
//  virtualTuristTests.swift
//  virtualTuristTests
//
//  Created by Sergio Costa on 22/07/18.
//  Copyright © 2018 Sergio Costa. All rights reserved.
//

import XCTest

@testable import virtualTurist

class virtualTuristTests: XCTestCase {
    let dataController = DataController(modelName: "virtualTourist")

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        dataController.load()

        addPin(name: "AAA")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func addPin(name: String) {
        let pin = Pin(context: dataController.viewContext)
        pin.name = name
        pin.creationDate = Date()
        pin.latitude = "9595"
        pin.longitude = "5158"
        try? dataController.viewContext.save()
    }
}
