//
//  CoffeeModel.swift
//  CoffeeAPI
//
//  Created by Christoph Rohde on 11.03.25.
//

import Foundation

public struct Product {
    public let id: UUID
    public let category: String
    public let categoryNumber: UInt16
    public let name: String
    public let price: Float64
    public let metadata: Metadata
}

// MARK: - default init

public extension Product {
    init() {
        id = UUID()
        category = "Coffee"
        categoryNumber = 1
        name = "Caffee"
        price = 3.20
        metadata = Metadata()
    }
}

// MARK: - Identifiable

extension Product: Identifiable {}

// MARK: - Sendable

extension Product: Sendable {}

// MARK: - CustomStringConvertible

extension Product: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        CoffeeModel:
            id=\(id),
            category=\(category),
            categoryNumber=\(categoryNumber),
            name=\(name),
            price=\(price),
            metadata=\(metadata)
        """
    }
}

// MARK: - Codable

extension Product: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case category
        case categoryNumber = "category_number"
        case name
        case price
        case metadata

        enum MetadataKeys: String, CodingKey {
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case tagIds = "tag_ids"
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        category = try container.decode(String.self, forKey: .category)
        categoryNumber = try container.decode(UInt16.self, forKey: .categoryNumber)
        name = try container.decode(String.self, forKey: .name)
        price = try container.decode(Float64.self, forKey: .price)
        metadata = try container.decode(Metadata.self, forKey: .metadata)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(price, forKey: .price)

        var metadataContainer = container.nestedContainer(keyedBy: Metadata.CodingKeys.self, forKey: .metadata)
        try metadataContainer.encode(metadata.createdAt, forKey: .createdAt)
        try metadataContainer.encode(metadata.updatedAt, forKey: .updatedAt)

        // try metadataContainer.encode(metadata.tagIds, forKey: .tagIds)
    }
}

// MARK: - Hashable

extension Product: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
//        hasher.combine(category)
//        hasher.combine(categoryNumber)
        hasher.combine(name)
//        hasher.combine(price)
//        hasher.combine(metadata)
    }
}

// MARK: - Equatable

extension Product: Equatable {
    public static func == (lhs: Product, rhs: Product) -> Bool {
        lhs.id == rhs.id
    }
}
