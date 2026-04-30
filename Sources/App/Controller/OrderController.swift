//
//  OrderController.swift
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

public struct OrderController: Sendable {
    @Sendable func createOrder(req: Request) async throws -> HTTPResponseStatus {
        guard let urlId = req.parameters.get("id") else {
            req.logger.error("Missing ID in URL parameter")
            throw Abort(.badRequest, reason: "Order ID in URL is required.")
        }
        
        req.logger.info("Received POST request on /test/order/id/\(urlId)")

        // 1. Decode the incoming Order object from the request body
        let newOrder: Order // Explicit type annotation helps clarity
        do {
            newOrder = try req.content.decode(Order.self)
            req.logger.debug("Decoded Order: \(newOrder.debugDescription)")
        } catch {
            req.logger.error("Failed to decode Order: \(error)")
            throw Abort(.badRequest, reason: "Invalid Order format: \(error.localizedDescription)")
        }

        // 2. Get database connection
        guard let sqlDb = req.db(.sqlite) as? any SQLDatabase else {
            req.logger.critical("Database connection not available or doesn't support raw SQL.")
            throw Abort(.internalServerError, reason: "Database configuration error.")
        }
        
        let userId = newOrder.userId.uuidString
        req.logger.info("Database connection obtained. Processing order for user: \(userId)")

        // 2.1 Attach UserData database
        let userDataDbPath = Environment.get("UserData") ?? "/Volumes/Code/UserData.sqlite"
        let attachQuery = "ATTACH DATABASE $1 AS userData;"
        var attachQueryString = SQLQueryString(attachQuery)
        attachQueryString.appendInterpolation(bind: userDataDbPath)
        
        do {
            try await sqlDb.raw(attachQueryString).run()
            req.logger.info("User data database attached successfully.")
        } catch {
            // Ignore error if already attached, but log other issues
            req.logger.debug("Attach info: \(error.localizedDescription)")
        }

        // Check if user exists in local database
        let userCheckQuery = "SELECT id FROM users WHERE id = $1;"
        var userCheckQueryString = SQLQueryString(userCheckQuery)
        userCheckQueryString.appendInterpolation(bind: userId)
        
        do {
            let userRows = try await sqlDb.raw(userCheckQueryString).all()
            if userRows.isEmpty {
                req.logger.info("User \(userId) not found in local users table. Checking in userData...")
                
                let remoteUserCheckQuery = "SELECT id, name, email FROM userData.users WHERE id = $1;"
                var remoteUserCheckQueryString = SQLQueryString(remoteUserCheckQuery)
                remoteUserCheckQueryString.appendInterpolation(bind: userId)
                
                let remoteRows = try await sqlDb.raw(remoteUserCheckQueryString).all()
                if let remoteUser = remoteRows.first {
                    let name = (try? remoteUser.decode(column: "name", as: String.self)) ?? "User"
                    let email = (try? remoteUser.decode(column: "email", as: String.self)) ?? ""
                    
                    req.logger.info("Syncing user \(userId) from userData to local users table.")
                    let syncQuery = "INSERT INTO users (id, name, email) VALUES ($1, $2, $3);"
                    var syncQueryString = SQLQueryString(syncQuery)
                    syncQueryString.appendInterpolation(bind: userId)
                    syncQueryString.appendInterpolation(bind: name)
                    syncQueryString.appendInterpolation(bind: email)
                    try await sqlDb.raw(syncQueryString).run()
                } else {
                    req.logger.error("User with ID \(userId) not found in userData either.")
                    throw Abort(.badRequest, reason: "User not found. Please register or log in again.")
                }
            }
        } catch let abort as Abort {
            throw abort
        } catch {
            req.logger.error("Failed to check for or sync user: \(error)")
            throw Abort(.internalServerError, reason: "Database error during user validation.")
        }

        do {
            let insertOrderSQL = """
            INSERT INTO orders (id, user_id, order_date, order_status, payment_option, payment_status)
            VALUES ($1, $2, $3, $4, $5, $6);
            """

            // 1. Basis-Query erstellen
            var orderQuery = SQLQueryString(insertOrderSQL)
            // 2. Binds AN DIE QUERY anhängen
            orderQuery.appendInterpolation(bind: urlId) // $1
            orderQuery.appendInterpolation(bind: userId) // $2
            orderQuery.appendInterpolation(bind: newOrder.orderDate.timeIntervalSince1970) // $3
            orderQuery.appendInterpolation(bind: newOrder.orderStatus) // $4
            orderQuery.appendInterpolation(bind: newOrder.paymentOption) // $5
            orderQuery.appendInterpolation(bind: newOrder.paymentStatus) // $6

            req.logger.debug("Executing Order Insert for ID: \(urlId)")
            try await sqlDb.raw(orderQuery).run()

            req.logger.info("Successfully inserted order into orders table.")

            let insertItemSQLBase = """
            INSERT INTO ordered_items (id, order_id, item_id, item_quantity)
            VALUES ($1, $2, $3, $4);
            """

            for item in newOrder.items {
                let productId = item.id.uuidString.lowercased()
                
                // Check if product exists
                let productCheckQuery = "SELECT id FROM products WHERE id = $1;"
                var productCheckQueryString = SQLQueryString(productCheckQuery)
                productCheckQueryString.appendInterpolation(bind: productId)
                
                let productRows = try await sqlDb.raw(productCheckQueryString).all()
                if productRows.isEmpty {
                    req.logger.error("Product with ID \(productId) not found in products table.")
                    throw Abort(.badRequest, reason: "Product with ID \(productId) does not exist.")
                }

                var itemQuery = SQLQueryString(insertItemSQLBase)
                itemQuery.appendInterpolation(bind: UUID().uuidString) // $1: id (PK)
                itemQuery.appendInterpolation(bind: urlId) // $2: order_id
                itemQuery.appendInterpolation(bind: productId) // $3: item_id
                itemQuery.appendInterpolation(bind: Int(item.quantity)) // $4: item_quantity

                try await sqlDb.raw(itemQuery).run()
                req.logger.debug("Inserted item with product ID \(productId) for order \(urlId)")
            }
            req.logger.info("Successfully inserted \(newOrder.items.count) items for order \(urlId).")

            return .created

        } catch {
            req.logger.error("Error during order processing: \(error)")
            // Provide more detail if it's a constraint violation
            let reason = "Failed to process order: \(error.localizedDescription)"
            throw Abort(.internalServerError, reason: reason)
        }
    }

    @Sendable func getJsonForId(req: Request) async throws -> String {
        guard let id = req.parameters.get("id") else {
            throw Abort(.badRequest)
        }
        print("[GET] http://127.0.0.1:8080/test/order/id/\(id)")

        guard let db = req.db as? SQLDatabase else {
            print("Database unavailable")
            throw Abort(.internalServerError)
        }

        var query = SQLQueryString("""
            SELECT
                json_object(
                    'id', o.id,
                    'user_id', o.user_id,
                    'order_date', o.order_date,
                    'order_status', o.order_status,
                    'payment_option', o.payment_option,
                    'payment_status', o.payment_status,
                    'items', json_group_array(
                            json_object(
                                'id', oi.item_id,
                                'quantity', oi.item_quantity
                            )
                    )
                ) as order_json
            FROM orders o
            LEFT JOIN ordered_items oi ON o.id = oi.order_id
            WHERE o.id = $1
            GROUP BY o.id;
        """)
        query.appendInterpolation(bind: id)

        let rows = try await db.raw(query).all()

        for row in rows {
            return try row.decode(column: "order_json", as: String.self)
        }

        throw Abort(.notFound)
    }

    
    @Sendable func getHistory(req: Request) async throws -> String {
        guard let before = req.parameters.get("before") else {
            throw Abort(.badRequest)
        }
        print("[GET] http://127.0.0.1:8080/test/order/history/\(before)")

        guard let db = req.db as? SQLDatabase else {
            print("Database unavailable")
            throw Abort(.internalServerError)
        }

        var query = SQLQueryString("""
            SELECT
                json_group_array(json(order_json)) AS order_json
            FROM (
                SELECT
                    order_json
                FROM ORDER_JSON_VIEW
                WHERE order_date < $1
                LIMIT 20
            );
        """)
        query.appendInterpolation(bind: Double(before) ?? 0.0)

        let rows = try await db.raw(query).all()

        for row in rows {
            return try row.decode(column: "order_json", as: String.self)
        }

        throw Abort(.notFound)
    }
}
