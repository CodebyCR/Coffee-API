//
//  TokenServiceProtocol.swift
//  CoffeeAPI
//
//  Created by Christoph Rohde on 25.07.25.
//

import Foundation


// MARK: - Token Service
protocol TokenServiceProtocol {
    func generateToken() -> String
}
