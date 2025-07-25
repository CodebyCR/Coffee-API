//
//  CoffeeRoutesTest.swift
//  CoffeeAPI
//
//  Created by Christoph Rohde on 20.01.25.
//

import XCTVapor
@testable import App

final class CoffeeRoutesTest: XCTestCase {

    func testCoffeeGetById() throws {
        let app = Application(.testing)

        defer { app.shutdown() }
        try configure(app)
        app.databases.use(.sqlite(.memory), as: .sqlite)

        // Registriere die Routen
        try routes(app)

        let fullURL = "test/coffee/id/1"
        let ExpectedResponce = """
        {"id":1,"name":"Cappuccino","price":3.5,"metadata":{"created_at":"2024-11-28 19:45:04","updated_at":"2024-12-27 17:57:37","tag_ids":[null]}}
        """

        try app.test(.GET, fullURL, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, ExpectedResponce)
        })

    }

}
