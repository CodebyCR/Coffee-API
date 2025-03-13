//
//  OrderItem.swift
//  CoffeeAPI
//
//  Created by Christoph Rohde on 12.03.25.
//
import Foundation

public struct OrderItem {
    public let id: UUID
    public let quantity: UInt8
}

// MARK: - Codable

extension OrderItem: Codable {
    enum CodingKeys: String, CodingKey {
        case quantity
        case productId = "product_id"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        quantity = try container.decode(UInt8.self, forKey: .quantity)
        id = try container.decode(UUID.self, forKey: .productId)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(quantity, forKey: .quantity)
    }
}

// MARK: - Identifiable

extension OrderItem: Identifiable {}

// MARK: - Sendable

extension OrderItem: Sendable {}

// MARK: - CustomDebugStringConvertible

extension OrderItem: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        OrderItem:
            id=\(id),
            quantity=\(quantity)
        """
    }
}

// MARK: - Content

import Vapor
extension OrderItem: Content {}
