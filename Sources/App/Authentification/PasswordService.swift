//
//  PasswordService.swift
//  CoffeeAPI
//
//  Created by Christoph Rohde on 25.07.25.
//

import Fluent
import FluentSQL
import FluentSQLiteDriver
import Foundation
import SQLiteNIO
import Vapor

struct PasswordService: PasswordServiceProtocol {
    private let pepper: String

    init() throws {
        guard let pepper = Environment.get("PEPPER") else {
            throw AuthenticationError.configurationError("PEPPER environment variable is not set")
        }
        self.pepper = pepper
    }

    func hashPassword(_ password: String) throws -> (hashedPassword: String, salt: String) {
        let salt = UUID().uuidString
        let hashedPassword = try Bcrypt.hash(pepper + password + salt)
        return (hashedPassword, salt)
    }

    func verifyPassword(_ password: String, against hashedPassword: String, salt: String) throws -> Bool {
        try Bcrypt.verify(pepper + password + salt, created: hashedPassword)
    }
}
