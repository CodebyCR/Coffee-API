////
////  AuthentificationController.swift
////  CoffeeAPI
////
////  Created by Christoph Rohde on 25.07.25.
////
//
//import Fluent
//import FluentSQL
//import FluentSQLiteDriver
//import Foundation
//import SQLiteNIO
//import Vapor
//
//// MARK: - Authentication Controller
//public struct AuthentificationController {
//    private let databaseService: DatabaseServiceProtocol
//    private let passwordService: PasswordServiceProtocol
//    private let tokenService: TokenServiceProtocol
//
//    init(
//        databaseService: DatabaseServiceProtocol = DatabaseService(),
//        passwordService: PasswordServiceProtocol? = nil,
//        tokenService: TokenServiceProtocol = TokenService()
//    ) throws {
//        self.databaseService = databaseService
//        self.passwordService = passwordService ?? (try! PasswordService())
//        self.tokenService = tokenService
//    }
//
//    func registration(req: Request) async throws -> HTTPResponseStatus {
//        req.logger.info("Processing user registration request")
//
//        let userRequest = try req.content.decode(UserRegistrationRequest.self)
//
//        guard let db = req.db as? SQLDatabase else {
//            req.logger.error("Database unavailable")
//            throw AuthenticationError.databaseError("Database connection failed")
//        }
//
//        do {
//            let (hashedPassword, salt) = try passwordService.hashPassword(userRequest.password)
//
//            try await databaseService.attachUserDatabase(db)
//            try await databaseService.insertUser(userRequest, hashedPassword: hashedPassword, salt: salt, db: db)
//
//            req.logger.info("User registration successful for \(userRequest.name)")
//            return .ok
//
//        } catch let error as AuthenticationError {
//            req.logger.error("Registration failed: \(error.reason)")
//            throw error
//        } catch {
//            req.logger.error("Registration failed with unexpected error: \(error)")
//            throw AuthenticationError.databaseError("Registration failed")
//        }
//    }
//
//     func login(req: Request) async throws -> TokenResponse {
//        req.logger.info("Processing user login request")
//
//        let loginRequest = try req.content.decode(UserLoginRequest.self)
//
//        guard let db = req.db as? SQLDatabase else {
//            req.logger.error("Database unavailable")
//            throw AuthenticationError.databaseError("Database connection failed")
//        }
//
//        do {
//            try await databaseService.attachUserDatabase(db)
//
//            let userData = try await databaseService.findUser(by: loginRequest.email, db: db)
//
//            let isPasswordCorrect = try passwordService.verifyPassword(
//                loginRequest.password,
//                against: userData.password,
//                salt: userData.salt
//            )
//
//            guard isPasswordCorrect else {
//                req.logger.error("Invalid password for user: \(loginRequest.email)")
//                throw AuthenticationError.invalidCredentials
//            }
//
//            let token = tokenService.generateToken()
//            try await databaseService.storeToken(token, for: userData.id, db: db)
//
//            req.logger.info("User login successful for: \(loginRequest.email)")
//            return TokenResponse(token: token)
//
//        } catch let error as AuthenticationError {
//            req.logger.error("Login failed: \(error.reason)")
//            throw error
//        } catch {
//            req.logger.error("Login failed with unexpected error: \(error)")
//            throw AuthenticationError.databaseError("Login failed")
//        }
//    }
//}
