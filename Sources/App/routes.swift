
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
    orders.delete(":id") { req -> HTTPStatus in
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        // In einer realen Anwendung würden Sie hier die Order mit der gegebenen ID aus der Datenbank löschen
        return .ok
    }

    // PUT /test/orders/:id
    orders.put(":id") { req -> Order in
        guard let id = req.parameters.get("id", as: UUID.self) else {
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
    menu.get { _ in
        print("[GET]/test/orders")
        // In einer realen Anwendung würden Sie hier die Daten aus der Datenbank abrufen
        return [
            Coffee(id: UUID(), productNumber: 1, name: "Cappuccino", price: 3.5),
            Coffee(id: UUID(), productNumber: 2, name: "Latte Macchiato", price: 4.8),
            Coffee(id: UUID(), productNumber: 3, name: "Espresso", price: 1.9),
            Coffee(id: UUID(), productNumber: 4, name: "Americano", price: 2.2),
            Coffee(id: UUID(), productNumber: 5, name: "Ice Caffee", price: 3.8),
            Coffee(id: UUID(), productNumber: 6, name: "Caffee Crema", price: 1.8)
        ]
    }

    // incoming get request /test/menu/id={1}
    // GET /test/menu/id/123
    menu.get("id", ":id") { req -> Coffee in
        print("[GET]/test/menu/id")
        guard let id = req.parameters.get("id") else {
            throw Abort(.badRequest)
        }
        print("[GET]/test/menu/id/\(id)")

        // In einer realen Anwendung würden Sie hier die Daten aus der Datenbank abrufen
        return Coffee(id: UUID(), productNumber: 1, name: "Cappuccino", price: 3.5)
    }

    menu.get("txt") { req -> String in
        print("[GET]/test/menu/txt")
        // raw query from sqlite
        guard let db = req.db as? SQLDatabase else {
            print("Database unavailable")
            return "Database unavailable"
        }

        // The underlying database driver is SQL.
        let rawBuilder = db.raw("""
            SELECT json_array(
                json_object(
                    'index_ids', json_group_array(printf('%d', index_id))
                )
            ) as index_ids
            FROM drink;
        """)

        let rows = try await rawBuilder.all()

        // requiered result as json string:
        // [{"index_id":"1"},{"index_id":"2"},{"index_id":"3"},{"index_id":"4"},{"index_id":"5"},{"index_id":"6"}]

        let optionalJson = try rows.first?.decode(column: "index_ids", as: String.self)

        return optionalJson ?? #"[{"index_ids": []}]"#
    }
}

func routes(_ app: Application) throws {
    testOrders(app)

    testMenu(app)
}
