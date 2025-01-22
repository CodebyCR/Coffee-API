
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
    let menu = app.grouped("test", "coffee")

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
                'id', d.id,
                'name', d.name,
                'price', d.price,
                'metadata', json_object(
                'created_at', d.created_at,
                'updated_at', d.updated_at,
                'tag_ids',
                    CASE 
                        WHEN COUNT(dtr.tag_id) = 1 AND dtr.tag_id IS NULL THEN '[]'
                        ELSE json_group_array(dtr.tag_id)
                    END
                )
            ) as drink_json
            FROM drinks d
            LEFT JOIN drinks_tags_relation dtr ON d.id = dtr.drink_id
            WHERE d.id = \(unsafeRaw: id);
        """).all()

        for row in rows {
            return try row.decode(column: "drink_json", as: String.self)
        }

        throw Abort(.notFound)
    }

    menu.get("ids") { req -> String in
        print("[GET] http://127.0.0.1:8080/test/coffee/ids")
        // raw query from sqlite
        guard let db = req.db as? SQLDatabase else {
            print("Database unavailable")
            return "Database unavailable"
        }

        // The underlying database driver is SQL.
        let rawBuilder = db.raw("""
            SELECT
                json_group_array(printf('%d', id)) as ids
            FROM drinks;
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

        newOrder.post("id", ":id") { req -> String in

            guard let id = req.parameters.get("id") else {
                throw Abort(.badRequest)
            }
            print("[POST]http://127.0.0.1:8080/test/order/id=\(id)")

//            guard let db = req.db as? SQLDatabase else {
//                print("Database unavailable")
//                return "Database unavailable"
//            }
//
//            let postData = try req.content.decode(Order.self)
//
//
//            let rawBuilder = db.raw("""
//                INSERT INTO orders (name, coffee_name, total, size)
//                VALUES ('\(postData.name)', '\(postData.coffeeName)', \(bind: postData.total), '\(postData.size)');
//            """)
            return ""

    }


}



func routes(_ app: Application) throws {


    testOrder(app)

    testMenu(app)

    app.get { req in
        // print url request
        let  request = req.url
        print(request)
        // return response
        return "It works!"
    }
}

