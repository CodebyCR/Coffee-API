//
//  UserRegistrationRequest.swift
//  CoffeeAPI
//
//  Created by Christoph Rohde on 25.07.25.
//

import Fluent
import Foundation
import Vapor

// MARK: - DTOs
struct UserRegistrationRequest: Content {
    let name: String
    let email: String
    let password: String
}
