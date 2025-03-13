//
//  MenuCategory.swift
//  CoffeeAPI
//
//  Created by Christoph Rohde on 11.03.25.
//

import Foundation
import Vapor

public enum MenuCategory: String, CaseIterable, Identifiable, Hashable, Codable, Sendable, Content {
    case coffee = "Coffee"
    case cake = "Cake"
    case tea = "Tea"
    case snacks = "Snacks"

    public var id: Self { self }
}

extension MenuCategory: CustomDebugStringConvertible {
    public var debugDescription: String {
        rawValue
    }
}

public extension MenuCategory {
    static func get(by name: String) -> Self? {
        allCases.first { $0.rawValue == name }
    }
}
