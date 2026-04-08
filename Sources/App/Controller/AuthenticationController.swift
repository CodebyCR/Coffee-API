//
//  AuthentificationController.swift
//  CoffeeAPI
//
//  Created by Christoph Rohde on 05.07.25.
//

import Fluent
import FluentSQL
import FluentSQLiteDriver
import Foundation
import SQLiteNIO
import Vapor

struct AuthentificationController: Sendable {
    
    @Sendable
    func registration(req: Request) async throws -> HTTPResponseStatus {
        req.logger.info("Received POST request on /test/authentication/registration")

        print("[ POST ] http://127.0.0.1:8080/test/authentification/register")

        guard let userRegistrationJson = try? req.content.decode([String:String].self) else {
            req.logger.error("Failed to decode user registration JSON.")
            throw Abort(.badRequest, reason: "Invalid registration format.")
        }

        guard let username = userRegistrationJson["name"] else {
            req.logger.error("name is missing in registration JSON.")
            throw Abort(.badRequest, reason: "'name' is required.")
        }

        guard let email = userRegistrationJson["email"] else {
            req.logger.error("'email' is missing in registration JSON.")
            throw Abort(.badRequest, reason: "'email' is required.")
        }

        guard let password = userRegistrationJson["password"] else {
            req.logger.error("Password is missing in registration JSON.")
            throw Abort(.badRequest, reason: "'password' is required.")
        }

        print("Username: \(username), Email: \(email), Password: \(password)")

        guard let (hashedPassword, salt) = try? hashPassword(password: password) else {
            req.logger.error("Failed to hash password.")
            throw Abort(.internalServerError, reason: "Password hashing failed.")
        }

        print("Hashed Password: \(hashedPassword), Salt: \(salt)")

        guard let db = req.db as? SQLDatabase else {
            print("Database unavailable")
            throw Abort(.internalServerError)
        }


        let userDataDbPath = Environment.get("UserData") ?? "/Users/christoph_rohde/Databases/UserData.sqlite"

        let query1 = """
            ATTACH DATABASE $1 AS userData;
        """
        var attachQuery = SQLQueryString(query1)
        attachQuery.appendInterpolation(bind: userDataDbPath)


        let query2 = """
            INSERT INTO userData.users (id, name, email, password, salt)
            VALUES ($1, $2, $3, $4, $5);
        """

        var insertQuery = SQLQueryString(query2)
        insertQuery.appendInterpolation(bind: UUID().uuidString)    // $2 - Unique user ID
        insertQuery.appendInterpolation(bind: username)             // $3 - Username
        insertQuery.appendInterpolation(bind: email)                // $4 - Email
        insertQuery.appendInterpolation(bind: hashedPassword)       // $5 - Hashed Password
        insertQuery.appendInterpolation(bind: salt)                 // $6 - Salt

        req.logger.debug("Executing User Insert Query: \(insertQuery)")
        do {
            print("Step 1")
            try await db.raw(attachQuery).run()
            print("Step 2")
            try await db.raw(insertQuery).run()
            req.logger.info("User registration successful for \(username).")
        } catch {
            //return HTTPResponseStatus.ok
            
            
            // Currently throw an error if the database is already attached.
            req.logger.error("Failed to insert user into database: \(error)")
            throw Abort(.internalServerError, reason: "Database error during registration.")
        }

        return HTTPResponseStatus.ok
    }

    private func hashPassword(password: consuming String) throws -> (hashedPassword: String, salt: String) {
        guard let papper = Environment.get("PEPPER") else {
            print("PEPPER environment variable is not set.")
            throw Abort(.internalServerError, reason: "Server configuration error.")
        }

        let salt = UUID().uuidString
        let hashedPassword = try Bcrypt.hash(papper + password + salt)

        return (hashedPassword, salt)
    }

    @Sendable
    func login(req: Request) async throws -> String {
        req.logger.info("Received POST request on /test/authentication/login")

        print("[POST] http://127.0.0.1:8080/test/authentification/login")

        guard let userLoginJson = try? req.content.decode([String:String].self) else {
            req.logger.error("Failed to decode user registration JSON.")
            throw Abort(.badRequest, reason: "Invalid registration format.")
        }

        guard let email = userLoginJson["email"] else {
            req.logger.error("'email' is missing in registration JSON.")
            throw Abort(.badRequest, reason: "'email' is required.")
        }

        guard let password = userLoginJson["password"] else {
            req.logger.error("Password is missing in registration JSON.")
            throw Abort(.badRequest, reason: "'password' is required.")
        }

        guard let db = req.db as? SQLDatabase else {
            print("Database unavailable")
            throw Abort(.internalServerError)
        }

        // Attach the user data database
        let userDataDbPath = Environment.get("UserData") ?? "/Users/christoph_rohde/Databases/UserData.sqlite"

        let query1 = """
            ATTACH DATABASE $1 AS userData;
        """
        var attachQuery = SQLQueryString(query1)
        attachQuery.appendInterpolation(bind: userDataDbPath)
        req.logger.debug("Executing Attach Query: \(attachQuery)")
        do {
            try await db.raw(attachQuery).run()
            req.logger.info("User data database attached successfully.")
        } catch {
            req.logger.error("Failed to attach user data database: \(error)")
            //throw Abort(.internalServerError, reason: "Database error during login.")
        }

        // get data from userData.users table
        let loginQuery = """
            SELECT
                id,
                password,
                salt
            FROM userData.users
            WHERE email = $1;
        """

        var loginQueryString = SQLQueryString(loginQuery)
        loginQueryString.appendInterpolation(bind: email)
        req.logger.debug("Executing Login Query: \(loginQueryString)")

        guard let loginRows = try? await db.raw(loginQueryString).all() else {
            req.logger.error("Failed to execute login query for email \(email).")
            throw Abort(.internalServerError, reason: "Database error during login.")
        }

        guard let loginRow = loginRows.first else {
            req.logger.error("No user found with email \(email).")
            throw Abort(.unauthorized, reason: "Invalid email or password.")
        }

        guard let userId = try? loginRow.decode(column: "id", as: String.self) else {
            req.logger.error("User ID is missing in the login row.")
            throw Abort(.internalServerError, reason: "Database error during login.")
        }

        guard let storedPassword = try? loginRow.decode(column: "password", as: String.self) else {
            req.logger.error("Password is missing in the login row.")
            throw Abort(.internalServerError, reason: "Database error during login.")
        }
        guard let salt = try? loginRow.decode(column: "salt", as: String.self) else {
            req.logger.error("Salt is missing in the login row.")
            throw Abort(.internalServerError, reason: "Database error during login.")
        }

        guard let papper = Environment.get("PEPPER") else {
            print("PEPPER environment variable is not set.")
            throw Abort(.internalServerError, reason: "Server configuration error.")
        }

        // Check if the hashed password matches the one in the database
        let isPasswordCorrect = try Bcrypt.verify(papper + password + salt, created: storedPassword)

        if !isPasswordCorrect {
            req.logger.error("Incorrect password for user with email \(email).")
            throw Abort(.unauthorized, reason: "Invalid email or password.")
        }

        print("User \(email) logged in successfully with ID: \(userId)")

        let accessToken = generateAccessToken()
        let refreshToken = "rt-\(UUID().uuidString)"
        
        let tokenQuery = """
            INSERT INTO userData.active_tokens (id, user_id, token)
            VALUES ($1, $2, $3);
        """

        var tokenQueryString = SQLQueryString(tokenQuery)
        tokenQueryString.appendInterpolation(bind: UUID().uuidString)
        tokenQueryString.appendInterpolation(bind: userId)
        tokenQueryString.appendInterpolation(bind: refreshToken)

        req.logger.debug("Executing Token Insert Query: \(tokenQueryString)")
        do {
            try await db.raw(tokenQueryString).run()
            req.logger.info("Token generated and stored successfully for user \(email).")
        } catch {
            req.logger.error("Failed to insert token into database: \(error)")
            throw Abort(.internalServerError, reason: "Database error during token generation.")
        }

        return """
            {
                "accessToken" : "\(accessToken)",
                "refreshToken" : "\(refreshToken)",
                "token" : "\(accessToken)"
            }
        """
    }


    @Sendable
    func refreshToken(req: Request) async throws -> String {
        req.logger.info("Received POST request on /test/authentication/refresh")
        
        struct RefreshRequest: Content {
            let refreshToken: String
        }
        
        guard let refreshRequest = try? req.content.decode(RefreshRequest.self) else {
            throw Abort(.badRequest, reason: "Invalid refresh request.")
        }
        
        guard let db = req.db as? SQLDatabase else {
            req.logger.error("Database unavailable")
            throw Abort(.internalServerError)
        }
        
        // Attach the user data database
        let userDataDbPath = Environment.get("UserData") ?? "/Users/christoph_rohde/Databases/UserData.sqlite"
        let attachQuery = SQLQueryString("ATTACH DATABASE $1 AS userData;")
        var attachQueryWithBind = attachQuery
        attachQueryWithBind.appendInterpolation(bind: userDataDbPath)
        
        // Try to attach, ignore if already attached
        _ = try? await db.raw(attachQueryWithBind).run()
        
        // Look up the token
        let lookupQuery = "SELECT user_id FROM userData.active_tokens WHERE token = $1;"
        var lookupQueryString = SQLQueryString(lookupQuery)
        lookupQueryString.appendInterpolation(bind: refreshRequest.refreshToken)
        
        guard let rows = try await db.raw(lookupQueryString).all().first else {
            req.logger.error("Refresh token not found: \(refreshRequest.refreshToken)")
            throw Abort(.unauthorized, reason: "Invalid refresh token.")
        }
        
        let userId = try rows.decode(column: "user_id", as: String.self)
        
        // Generate new tokens
        let newAccessToken = generateAccessToken()
        let newRefreshToken = "rt-\(UUID().uuidString)"
        
        // Update database (replace old refresh token with new one)
        let deleteQuery = "DELETE FROM userData.active_tokens WHERE token = $1;"
        var deleteQueryString = SQLQueryString(deleteQuery)
        deleteQueryString.appendInterpolation(bind: refreshRequest.refreshToken)
        try await db.raw(deleteQueryString).run()
        
        let insertQuery = "INSERT INTO userData.active_tokens (id, user_id, token) VALUES ($1, $2, $3);"
        var insertQueryString = SQLQueryString(insertQuery)
        insertQueryString.appendInterpolation(bind: UUID().uuidString)
        insertQueryString.appendInterpolation(bind: userId)
        insertQueryString.appendInterpolation(bind: newRefreshToken)
        try await db.raw(insertQueryString).run()
        
        return """
            {
                "accessToken" : "\(newAccessToken)",
                "refreshToken" : "\(newRefreshToken)"
            }
        """
    }

    private func generateAccessToken() -> String {
        let header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9" // {"alg":"HS256","typ":"JWT"}
        let exp = Date().addingTimeInterval(3600).timeIntervalSince1970
        let payload: [String: Any] = [
            "exp": exp,
            "iat": Date().timeIntervalSince1970,
            "sub": "user"
        ]
        
        guard let payloadData = try? JSONSerialization.data(withJSONObject: payload),
              let payloadBase64 = payloadData.base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "") as String? else {
            return "invalid.payload.signature"
        }
        
        return "\(header).\(payloadBase64).signature"
    }
    
}
