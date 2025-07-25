//
//  UserLoginRequest.swift
//  CoffeeAPI
//
//  Created by Christoph Rohde on 25.07.25.
//

import Fluent
import Foundation
import SQLiteNIO
import Vapor

struct UserLoginRequest: Content {
    let email: String
    let password: String
}
