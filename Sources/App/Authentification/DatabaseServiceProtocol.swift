//
//  DatabaseServiceProtocol.swift
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

// MARK: - Database Service
protocol DatabaseServiceProtocol {
    func attachUserDatabase(_ db: SQLDatabase) async throws
    func insertUser(_ user: UserRegistrationRequest, hashedPassword: String, salt: String, db: SQLDatabase) async throws
    func findUser(by email: String, db: SQLDatabase) async throws -> (id: String, password: String, salt: String)
    func storeToken(_ token: String, for userId: String, db: SQLDatabase) async throws
}
