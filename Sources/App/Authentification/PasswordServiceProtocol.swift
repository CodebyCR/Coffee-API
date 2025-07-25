//
//  PasswordServiceProtocol.swift
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

// MARK: - Password Service
protocol PasswordServiceProtocol {
    func hashPassword(_ password: String) throws -> (hashedPassword: String, salt: String)
    func verifyPassword(_ password: String, against hashedPassword: String, salt: String) throws -> Bool
}
