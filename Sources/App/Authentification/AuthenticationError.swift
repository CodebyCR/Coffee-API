//
//  AuthenticationError.swift
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

// MARK: - Custom Errors
enum AuthenticationError: Error, AbortError {
    case invalidCredentials
    case userNotFound
    case databaseError(String)
    case configurationError(String)

    var status: HTTPResponseStatus {
        switch self {
        case .invalidCredentials, .userNotFound:
            return .unauthorized
        case .databaseError, .configurationError:
            return .internalServerError
        }
    }

    var reason: String {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password."
        case .userNotFound:
            return "User not found."
        case .databaseError(let message):
            return "Database error: \(message)"
        case .configurationError(let message):
            return "Server configuration error: \(message)"
        }
    }
}
