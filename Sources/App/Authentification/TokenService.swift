//
//  TokenService.swift
//  CoffeeAPI
//
//  Created by Christoph Rohde on 25.07.25.
//

import Foundation

struct TokenService: TokenServiceProtocol {
    func generateToken() -> String {
        "cl-\(UUID().uuidString)"
    }
}
