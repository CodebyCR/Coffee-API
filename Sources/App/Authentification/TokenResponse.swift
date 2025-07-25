//
//  TokenResponse.swift
//  CoffeeAPI
//
//  Created by Christoph Rohde on 25.07.25.
//

import Fluent
import Foundation
import Vapor

struct TokenResponse: Content {
    let token: String
}
