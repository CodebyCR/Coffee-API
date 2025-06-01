//
//  File.swift
//  CoffeeAPI
//
//  Created by Christoph Rohde on 24.05.25.
//

import Fluent
import FluentSQL
import FluentSQLiteDriver
import Foundation
import SQLiteNIO
import Vapor

public struct ProductController: Sendable {
    @Sendable func getIds(req: Request) async throws -> String {
        print("[GET] http://127.0.0.1:8080/test/coffee/ids")
        // raw query from sqlite
        guard let db = req.db as? SQLDatabase else {
            print("Database unavailable")
            return "Database unavailable"
        }

        // The underlying database driver is SQL.
        let rawBuilder = db.raw("""
            SELECT json_group_array(quote(id) ORDER BY category, category_number) AS ids
            FROM products
        """)

        let rows = try await rawBuilder.all()

        // requiered result as json string:
        // [{"index_id":"1"},{"index_id":"2"},{"index_id":"3"},{"index_id":"4"},{"index_id":"5"},{"index_id":"6"}]

        let optionalJson = try rows.first?.decode(column: "ids", as: String.self)

        return optionalJson ?? "[]"
    }

    @Sendable func getProductJsonForId(req: Request) async throws -> String {
        guard let id = req.parameters.get("id") else {
            throw Abort(.badRequest)
        }
        print("[GET] http://127.0.0.1:8080/test/coffee/id/\(id)")

        guard let db = req.db as? SQLDatabase else {
            print("Database unavailable")
            throw Abort(.internalServerError)
        }

        let rows = try await db.raw("""
            SELECT
            json_object(
                'id', prod.id,
                'category', prod.category,
                'category_number', prod.category_number,
                'name', prod.name,
                'price', prod.price,
                'image_name', prod.original_image_name,
                'metadata', json_object(
                'created_at', prod.created_at,
                'updated_at', prod.updated_at,
                'tag_ids',
                    CASE
                        WHEN COUNT(ptr.tag_id) = 1 AND ptr.tag_id IS NULL THEN '[]'
                        ELSE json_group_array(ptr.tag_id)
                    END
                )
            ) as product_json
            FROM products prod
            LEFT JOIN products_tags_relation ptr ON prod.id = ptr.product_id
            WHERE prod.id = \(unsafeRaw: id);
        """).all()

        for row in rows {
            return try row.decode(column: "product_json", as: String.self)
        }

        throw Abort(.notFound)
    }

    @Sendable func getCoffeeProductsJson(req: Request) async throws -> String {
        print("[GET]/test/coffee")
        // In einer realen Anwendung würden Sie hier die Daten aus der Datenbank abrufen

        guard let db = req.db as? SQLDatabase else {
            print("Database unavailable")
            throw Abort(.internalServerError)
        }

        let rows = try await db.raw("""
        SELECT json_group_array(
          json_object(
            'id', index_id, 
            'name', name, 
            'price', price, 
            'date', creation_date
          )
        ) AS drink_list
        FROM products
        WHERE category = 'coffee'
        order by category_number;
        """).all()

        for row in rows {
            return try row.decode(column: "drink_list", as: String.self)
        }

        throw Abort(.notFound)
    }

    @Sendable func getCakeProductsJson(req: Request) async throws -> String {
        print("[GET]/test/cake")
        // In einer realen Anwendung würden Sie hier die Daten aus der Datenbank abrufen

        guard let db = req.db as? SQLDatabase else {
            print("Database unavailable")
            throw Abort(.internalServerError)
        }

        let rows = try await db.raw("""
        SELECT json_group_array(
          json_object(
            'id', index_id, 
            'name', name, 
            'price', price, 
            'date', creation_date
          )
        ) AS cake_list
        FROM products
        WHERE category = 'cake';
        """).all()

        for row in rows {
            return try row.decode(column: "cake_list", as: String.self)
        }

        throw Abort(.notFound)
    }
}
