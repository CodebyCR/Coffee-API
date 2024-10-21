//
//  Order.swift
//  CoffeeAPI
//
//  Created by Christoph Rohde on 21.10.24.
//

import Foundation
import Vapor

// Definiere das Order-Modell
struct Order: Content, Identifiable {
    var id: UUID?
    var name: String
    var coffeeName: String
    var total: Double
    var size: String
}
