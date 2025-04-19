
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
    let products = app.grouped("test", "coffee")

    // GET /test/orders
    products.get { req in
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
    products.get("id", ":id") { req in

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

    products.get("ids") { req -> String in
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
            ORDER BY category, category_number;
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
    let testOrderGroup = app.grouped("test", "order")

    // POST /test/order
    testOrderGroup.post("id", ":id") { req async throws -> HTTPStatus in
        req.logger.info("Received POST request on /test/order")

        guard let id = req.parameters.get("id") else {
            throw Abort(.badRequest)
        }

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
            let orderDateString = isoDateFormatter.string(from: newOrder.orderDate) // TODO: Check format

            // 1. Basis-Query erstellen
            var orderQuery = SQLQueryString(insertOrderSQL)
            // 2. Binds AN DIE QUERY anhängen (in der Reihenfolge $1, $2, ...)
            orderQuery.appendInterpolation(bind: newOrder.id.uuidString) // $1
            orderQuery.appendInterpolation(bind: newOrder.userId.uuidString) // $2
            orderQuery.appendInterpolation(bind: orderDateString) // $3
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
}

// HIER DEFINIEREN: Außerhalb der Funktion, aber in der Datei
let isoDateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    // Wähle die Optionen, die dem Format entsprechen, das du in der DB speichern möchtest.
    // .withInternetDateTime ist ein gängiges Format (z.B. "2023-10-27T10:30:00Z")
    // .withFractionalSeconds fügt Millisekunden hinzu, falls benötigt.
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

func routes(_ app: Application) throws {
    testOrder(app)

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
