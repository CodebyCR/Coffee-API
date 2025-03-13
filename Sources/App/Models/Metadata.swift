//
//  Metadata.swift
//  CoffeeAPI
//
//  Created by Christoph Rohde on 11.03.25.
//

import Foundation
import Vapor

public struct Metadata: Sendable, Codable, Hashable, CustomDebugStringConvertible, Content {
    let createdAt: Date
    let updatedAt: Date
    // let tagIds: [String]
    public var debugDescription: String {
        return "Metadata: createdAt=\(createdAt), updatedAt=\(updatedAt)"
    }

    // MARK: - Codable

    public init() {
        createdAt = Date()
        updatedAt = Date()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // sqlite3 date format
        let sqlite3DateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = sqlite3DateFormat
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        createdAt = dateFormatter.date(from: createdAtString) ?? Date()
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()
        // tagIds = try container.decode([String].self, forKey: .tagIds)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        // try container.encode(tagIds, forKey: .tagIds)
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case tagIds = "tag_ids"
    }
}
