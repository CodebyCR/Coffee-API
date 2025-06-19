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
        req.logger.info("Received POST request on /test/order")

        //        guard let id = req.parameters.get("id") else {
        //            throw Abort(.badRequest)
        //        }

        // 1. Decode the incoming Order object from the request body
        let newOrder: Order // Explicit type annotation helps clarity
        do {
            newOrder = try req.content.decode(Order.self)
            req.logger.debug("Decoded Order: \(newOrder.debugDescription)")
        } catch {
            req.logger.error("Failed to decode Order: \(error)")
            throw Abort(.badRequest, reason: "Invalid Order format: \(error.localizedDescription)")
        }

        // 2. Get database connections (assuming db1 for orders, db2 for items)
        guard let sqlDb1 = req.db(.sqlite) as? any SQLDatabase, // DB for 'orders' table
              let sqlDb2 = req.db(.sqlite) as? any SQLDatabase // DB for 'ordered_items' table
        else {
            req.logger.critical("Database connections not available or don't support raw SQL.")
            throw Abort(.internalServerError, reason: "Database configuration error.")
        }
        req.logger.info("Database connections obtained.")

        // --- ATOMICITY WARNING ---
        // Operations across db1 and db2 are NOT atomic. Failure during item insertion
        // will leave the order in db1 without corresponding items in db2.
        // Consider Sagas, Outbox pattern, or single DB if atomicity is critical.
        // ---

        do {
            let insertOrderSQL = """
            INSERT INTO orders (id, user_id, order_date, order_status, payment_option, payment_status)
            VALUES ($1, $2, $3, $4, $5, $6);
            """

            // 1. Basis-Query erstellen
            var orderQuery = SQLQueryString(insertOrderSQL)
            // 2. Binds AN DIE QUERY anhängen (in der Reihenfolge $1, $2, ...)
            orderQuery.appendInterpolation(bind: newOrder.id.uuidString) // $1
            orderQuery.appendInterpolation(bind: newOrder.userId.uuidString) // $2
            orderQuery.appendInterpolation(bind: newOrder.orderDate) // $3
            orderQuery.appendInterpolation(bind: newOrder.orderStatus) // $4
            orderQuery.appendInterpolation(bind: newOrder.paymentOption) // $5
            orderQuery.appendInterpolation(bind: newOrder.paymentStatus) // $6

            // 3. Fertige Query an raw().run() übergeben
            req.logger.debug("Executing Order Insert")
            try await sqlDb1.raw(orderQuery).run()

            req.logger.info("Successfully inserted order into DB1 with ID \(newOrder.id.uuidString).")

            // --- KORRIGIERTER TEIL 2: OrderItem Insert (innerhalb der Schleife) ---
            let insertItemSQLBase = """
            INSERT INTO ordered_items (id, order_id, item_id, item_quantity)
            VALUES ($1, $2, $3, $4);
            """

            req.logger.debug("Preparing to insert \(newOrder.items.count) items into ordered_items table.")

            for item in newOrder.items {
                // 1. Basis-Query für dieses Item erstellen
                var itemQuery = SQLQueryString(insertItemSQLBase)
                // 2. Binds AN DIE QUERY anhängen (in der Reihenfolge $1, $2, ...)
                itemQuery.appendInterpolation(bind: UUID().uuidString) // $1: id (PK)
                itemQuery.appendInterpolation(bind: newOrder.id.uuidString) // $2: order_id (FK -> Order ID)
                itemQuery.appendInterpolation(bind: item.id.uuidString.lowercased()) // $3: item_id (FK -> Product ID)
                itemQuery.appendInterpolation(bind: Int(item.quantity)) // $4: item_quantity

                // Debugging: Zeige die SQL-Query und die Binds an

                req.logger.debug("Item Insert SQL: \(insertItemSQLBase)")
                //                req.logger.debug("Executing Item Insert: \(itemQuery.sql) with binds: \(itemQuery.binds)")
                // 3. Fertige Query an raw().run() übergeben
                try await sqlDb2.raw(itemQuery).run()
                req.logger.debug("Inserted item with product ID \(item.id.uuidString) for order \(newOrder.id.uuidString)")
            }
            req.logger.info("Successfully inserted \(newOrder.items.count) items into DB2 for order \(newOrder.id.uuidString).")

            return .created

        } catch {
            req.logger.error("Generic Error during order processing: \(error)")
            throw Abort(.internalServerError, reason: "Failed to process order: \(error.localizedDescription)")
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

        let rows = try await db.raw("""
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
            WHERE o.id = '\(unsafeRaw: id)'
            GROUP BY o.id;
        """).all()

        for row in rows {
            return try row.decode(column: "order_json", as: String.self)
        }

        throw Abort(.notFound)
    }

}
