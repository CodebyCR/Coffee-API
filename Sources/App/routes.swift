
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
private func testOrders(_ app: Application) {
    let orders = app.grouped("test", "orders")

    // GET /test/orders
    orders.get { _ in
        // In einer realen Anwendung würden Sie hier die Daten aus der Datenbank abrufen
        [
            Order(id: UUID(), name: "John Doe", coffeeName: "Hot Coffee", total: 4.50, size: "Medium"),
            Order(id: UUID(), name: "Jane Smith", coffeeName: "Latte", total: 5.00, size: "Large")
        ]
    }

    // POST /test/orders
    orders.post { req -> Order in
        let order = try req.content.decode(Order.self)
        // In einer realen Anwendung würden Sie hier die Order in der Datenbank speichern
        return order
    }

    // DELETE /test/orders/:id
//    orders.delete(":id") { req -> HTTPStatus in
//        guard let id = req.parameters.get("id", as: UUID.self) else {
//            throw Abort(.badRequest)
//        }
//        // In einer realen Anwendung würden Sie hier die Order mit der gegebenen ID aus der Datenbank löschen
//        return .ok
//    }

    // PUT /test/orders/:id
    orders.put(":id") { req -> Order in
        guard req.parameters.get("id", as: UUID.self) != nil else {
            throw Abort(.badRequest)
        }
        let updatedOrder = try req.content.decode(Order.self)
        // In einer realen Anwendung würden Sie hier die Order mit der gegebenen ID in der Datenbank aktualisieren
        return updatedOrder
    }
}

private func testMenu(_ app: Application) {
    let menu = app.grouped("test", "menu")

    // GET /test/orders
    menu.get { req in
        print("[GET]/test/orders")
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
        FROM drink;
        """).all()

        for row in rows {
            return try row.decode(column: "drink_list", as: String.self)
        }

        throw Abort(.notFound)
    }

    // incoming get request /test/menu/id={1}
    // GET /test/menu/id/123
    menu.get("id", ":id") { req in
        print("[GET]/test/menu/id")
        guard let id = req.parameters.get("id") else {
            throw Abort(.badRequest)
        }
        print("[GET]/test/menu/id/\(id)")

        guard let db = req.db as? SQLDatabase else {
            print("Database unavailable")
            throw Abort(.internalServerError)
        }

        let rows = try await db.raw("""
        SELECT json_object(
          'id', index_id, 
          'name', name, 
          'price', price, 
          'date', creation_date
        ) AS drink_json
        FROM drink
        WHERE index_id = \(unsafeRaw: id);
        """).all()

        for row in rows {
            return try row.decode(column: "drink_json", as: String.self)
        }

        throw Abort(.notFound)
    }

    menu.get("index_ids") { req -> String in
        print("[GET]/test/menu/txt")
        // raw query from sqlite
        guard let db = req.db as? SQLDatabase else {
            print("Database unavailable")
            return "Database unavailable"
        }

        // The underlying database driver is SQL.
        let rawBuilder = db.raw("""
        SELECT
            json_group_array(printf('%d', index_id)) as index_ids
        FROM drink;
        """)

        let rows = try await rawBuilder.all()

        // requiered result as json string:
        // [{"index_id":"1"},{"index_id":"2"},{"index_id":"3"},{"index_id":"4"},{"index_id":"5"},{"index_id":"6"}]

        let optionalJson = try rows.first?.decode(column: "index_ids", as: String.self)

        return optionalJson ?? "[]"
    }
}

func routes(_ app: Application) throws {
    testOrders(app)

    testMenu(app)
}
