//
//  DatabaseService.swift
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

struct DatabaseService: DatabaseServiceProtocol {
    private let userDataDbPath: String

    init() {
        self.userDataDbPath = Environment.get("UserData") ?? "/Users/christoph_rohde/Databases/UserData.sqlite"
    }

    func attachUserDatabase(_ db: SQLDatabase) async throws {
        let query = "ATTACH DATABASE $1 AS userData;"
        var attachQuery = SQLQueryString(query)
        attachQuery.appendInterpolation(bind: userDataDbPath)

        try await db.raw(attachQuery).run()
    }

    func insertUser(_ user: UserRegistrationRequest, hashedPassword: String, salt: String, db: SQLDatabase) async throws {
        let query = """
            INSERT INTO userData.users (id, name, email, password, salt)
            VALUES ($1, $2, $3, $4, $5);
        """

        var insertQuery = SQLQueryString(query)
        insertQuery.appendInterpolation(bind: UUID().uuidString)
        insertQuery.appendInterpolation(bind: user.name)
        insertQuery.appendInterpolation(bind: user.email)
        insertQuery.appendInterpolation(bind: hashedPassword)
        insertQuery.appendInterpolation(bind: salt)

        try await db.raw(insertQuery).run()
    }

    func findUser(by email: String, db: SQLDatabase) async throws -> (id: String, password: String, salt: String) {
        let query = """
            SELECT id, password, salt
            FROM userData.users
            WHERE email = $1;
        """

        var loginQuery = SQLQueryString(query)
        loginQuery.appendInterpolation(bind: email)

        let rows = try await db.raw(loginQuery).all()

        guard let row = rows.first else {
            throw AuthenticationError.userNotFound
        }

        guard let id = try? row.decode(column: "id", as: String.self),
              let password = try? row.decode(column: "password", as: String.self),
              let salt = try? row.decode(column: "salt", as: String.self) else {
            throw AuthenticationError.databaseError("Failed to decode user data")
        }

        return (id: id, password: password, salt: salt)
    }

    func storeToken(_ token: String, for userId: String, db: SQLDatabase) async throws {
        let query = """
            INSERT INTO userData.active_tokens (id, user_id, token)
            VALUES ($1, $2, $3);
        """

        var tokenQuery = SQLQueryString(query)
        tokenQuery.appendInterpolation(bind: UUID().uuidString)
        tokenQuery.appendInterpolation(bind: userId)
        tokenQuery.appendInterpolation(bind: token)

        try await db.raw(tokenQuery).run()
    }
}
