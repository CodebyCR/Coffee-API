import Fluent
import Vapor
import FluentSQLiteDriver

// Konfiguriere die Anwendung
func configure(_ app: Application) throws {
    // Verwende SQLite als Datenbank
    app.databases.use(.sqlite(.memory), as: .sqlite)

    // Registriere die Routen
    try routes(app)
}

// Definiere die Routen
fileprivate func testOrders(_ app: Application) {
    let orders = app.grouped("test", "orders")
    
    // GET /test/orders
    orders.get { req in
        // In einer realen Anwendung würden Sie hier die Daten aus der Datenbank abrufen
        return [
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

fileprivate func testMenu(_ app: Application) {
    let menu = app.grouped("test", "menu")

    // GET /test/orders
    menu.get { req in
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


}

func routes(_ app: Application) throws {
    testOrders(app)

    testMenu(app)
}
