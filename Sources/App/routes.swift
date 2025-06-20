
import Fluent
import FluentSQL
import FluentSQLiteDriver
import SQLiteNIO
import Vapor


func configure(_ app: Application) throws {
    // Verwende SQLite als Datenbank
    app.databases.use(.sqlite(.memory), as: .sqlite)



    try routes(app)
}

func routes(_ app: Application) throws {
    // Products
    app.get("test", "coffee", "ids", use: ProductController().getIds)
    app.get("test", "coffee", "id", ":id", use: ProductController().getProductJsonForId)


    // Images
    app.get("test", "images", ":categorie", ":imageName", use: ImageController().getImage)


    // Orders
    app.post("test", "order", "id", ":id", use: OrderController().createOrder)
    app.get("test", "order", "id", ":id", use: OrderController().getJsonForId)


    app.get { req in
        return "Welcome to CoffeeKit"
    }
    
    app.get("docs") { req in
        return "Welcome to CoffeeKit"
    }
}
