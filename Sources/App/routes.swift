
import Fluent
import FluentSQL
import FluentSQLiteDriver
import SQLiteNIO
import Vapor

// Konfiguriere die Anwendung
func configure(_ app: Application) throws {
    // Verwende SQLite als Datenbank
    app.databases.use(.sqlite(.memory), as: .sqlite)

    // Registriere die Routen
    try routes(app)
}

// Definiere die Routen
// private func testOrders(_ app: Application) {
//    let orders = app.grouped("test", "orders")
//
//    // GET /test/orders
//    orders.get { _ in
//        // In einer realen Anwendung würden Sie hier die Daten aus der Datenbank abrufen
//        [
//            Order(id: UUID(), name: "John Doe", coffeeName: "Hot Coffee", total: 4.50, size: "Medium"),
//            Order(id: UUID(), name: "Jane Smith", coffeeName: "Latte", total: 5.00, size: "Large")
//        ]
//    }
//
//    // POST /test/orders
//    orders.post { req -> Order in
//        let order = try req.content.decode(Order.self)
//        // In einer realen Anwendung würden Sie hier die Order in der Datenbank speichern
//        return order
//    }
//
//    // DELETE /test/orders/:id
////    orders.delete(":id") { req -> HTTPStatus in
////        guard let id = req.parameters.get("id", as: UUID.self) else {
////            throw Abort(.badRequest)
////        }
////        // In einer realen Anwendung würden Sie hier die Order mit der gegebenen ID aus der Datenbank löschen
////        return .ok
////    }
//
//    // PUT /test/orders/:id
//    orders.put(":id") { req -> Order in
//        guard req.parameters.get("id", as: UUID.self) != nil else {
//            throw Abort(.badRequest)
//        }
//        let updatedOrder = try req.content.decode(Order.self)
//        // In einer realen Anwendung würden Sie hier die Order mit der gegebenen ID in der Datenbank aktualisieren
//        return updatedOrder
//    }
// }

private func testCoffee(_ app: Application) {
    let coffee = app.grouped("test", "coffee")

    // GET /test/orders
    coffee.get { req in
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

    // incoming get request /test/menu/id={1}
    // GET /test/menu/id/123
    coffee.get("id", ":id") { req in

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
                'metadata', json_object(
                'created_at', prod.created_at,
                'updated_at', prod.updated_at,
                'tag_ids',
                    CASE
                        WHEN COUNT(ptr.tag_id) = 1 AND ptr.tag_id IS NULL THEN '[]'
                        ELSE json_group_array(ptr.tag_id)
                    END
                )
            ) as drink_json
            FROM products prod
            LEFT JOIN products_tags_relation ptr ON prod.id = ptr.product_id
            WHERE prod.id = \(unsafeRaw: id);
        """).all()

        for row in rows {
            return try row.decode(column: "drink_json", as: String.self)
        }

        throw Abort(.notFound)
    }

    coffee.get("ids") { req -> String in
        print("[GET] http://127.0.0.1:8080/test/coffee/ids")
        // raw query from sqlite
        guard let db = req.db as? SQLDatabase else {
            print("Database unavailable")
            return "Database unavailable"
        }

        // The underlying database driver is SQL.
        let rawBuilder = db.raw("""
            SELECT
                json_group_array(quote(id)) AS ids
            FROM products
            WHERE category = 'coffee'
            ORDER BY category_number;
        """)

        let rows = try await rawBuilder.all()

        // requiered result as json string:
        // [{"index_id":"1"},{"index_id":"2"},{"index_id":"3"},{"index_id":"4"},{"index_id":"5"},{"index_id":"6"}]

        let optionalJson = try rows.first?.decode(column: "ids", as: String.self)

        return optionalJson ?? "[]"
    }
}

private func testCake(_ app: Application) {
    let coffee = app.grouped("test", "cake")

    // GET /test/orders
    coffee.get { req in
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

    // incoming get request /test/menu/id={1}
    // GET /test/menu/id/123
//    coffee.get("id", ":id") { req in
//
//        guard let id = req.parameters.get("id") else {
//            throw Abort(.badRequest)
//        }
//        print("[GET] http://127.0.0.1:8080/test/cake/id/\(id)")
//
//        guard let db = req.db as? SQLDatabase else {
//            print("Database unavailable")
//            throw Abort(.internalServerError)
//        }
//
//        let rows = try await db.raw("""
//        SELECT
//        json_object(
//            'id', cakes.id,
//            'name', cakes.name,
//            'price', cakes.price,
//            'metadata', json_object(
//            'created_at', cakes.created_at,
//            'updated_at', cakes.updated_at,
//            'tag_ids',
//                CASE
//                    WHEN COUNT(ctr.tag_id) = 1 AND ctr.tag_id IS NULL THEN '[]'
//                    ELSE json_group_array(ctr.tag_id)
//                END
//            )
//        ) as cake_json
//        FROM products
//        LEFT JOIN cakes_tags_relation ctr
//        ON cakes.id = ctr.cake_id
//        WHERE cakes.id = \(unsafeRaw: id);
//        """).all()
//
//        for row in rows {
//            return try row.decode(column: "cake_json", as: String.self)
//        }
//
//        throw Abort(.notFound)
//    }

    coffee.get("ids") { req -> String in
        print("[GET] http://127.0.0.1:8080/test/cake/ids")
        // raw query from sqlite
        guard let db = req.db as? SQLDatabase else {
            print("Database unavailable")
            return "Database unavailable"
        }

        // The underlying database driver is SQL.
        let rawBuilder = db.raw("""
            SELECT
                json_group_array(printf('%d', id)) as ids
            FROM products
            WHERE category = 'cake';
        """)

        let rows = try await rawBuilder.all()

        // requiered result as json string:
        // [{"index_id":"1"},{"index_id":"2"},{"index_id":"3"},{"index_id":"4"},{"index_id":"5"},{"index_id":"6"}]

        let optionalJson = try rows.first?.decode(column: "ids", as: String.self)

        return optionalJson ?? "[]"
    }
}

private func testOrder(_ app: Application) {
    let newOrder = app.grouped("test", "order")

    /// POST to http://127.0.0.1:8080/test/order/id=12323

    newOrder.post("id", ":id") { req -> EventLoopFuture<String> in
        guard let id = req.parameters.get("id") else {
            throw Abort(.badRequest)
        }

        print("[POST] http://127.0.0.1:8080/test/order/id=\(id)")
        guard let newOrder = try? req.content.decode(Order.self) else {
            print("Failed to decode order")
            throw Abort(.badRequest)
        }

        guard let db = req.db as? SQLDatabase else {
            print("Database unavailable")
            return req.eventLoop.makeFailedFuture(Abort(.internalServerError))
        }

        /// Insert new order into database
        return req.db.transaction { _ -> EventLoopFuture<String> in

            // Sichere Parameterbindung mit SQL-Parametern
            let orderInsert = db.raw("""
            INSERT INTO orders (id, user_id, order_date, order_status, payment_option, payment_status)
            VALUES (\(bind: newOrder.id), \(bind: newOrder.userId), \(bind: newOrder.orderDate), \(bind: newOrder.orderStatus), \(bind: newOrder.paymentOption), \(bind: newOrder.paymentStatus))
            """)
            .run()

            // Einfügen der Bestellpositionen
            let itemInserts = newOrder.items.map { item in
                db.raw("""
                INSERT INTO order_items (order_id, product_id, quantity)
                VALUES (\(bind: newOrder.id), \(bind: item.id), \(bind: item.quantity))
                """)
                .run()
            }

            // Alle Operationen zusammenfassen
            return orderInsert.flatMap { _ in
                EventLoopFuture.andAllSucceed(itemInserts, on: req.eventLoop)
                    .map { _ in
                        "Order with id \(id) has been created"
                    }
            }
        }
    }
}

func routes(_ app: Application) throws {
//    testOrder(app)

    testCoffee(app)
    testCake(app)

    app.get { req in
        // print url request
        let request = req.url
        print(request)
        // return response
        return "It works!"
    }
}
