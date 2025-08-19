
import Fluent
import FluentSQL
import FluentSQLiteDriver
import SQLiteNIO
import Vapor

private let productController = ProductController()
private let imageController = ImageController()
private let orderController = OrderController()
private let authentificationController = AuthentificationController()
private let mailService = MailController()

func configure(_ app: Application) throws {
    // Verwende SQLite als Datenbank
    app.databases.use(.sqlite(.memory), as: .sqlite)

    try routes(app)
}

func routes(_ app: Application) throws {
    let databaseRoute: PathComponent = "test"

    // Products
    app.get(databaseRoute, "coffee", "ids", use: productController.getIds)
    app.get(databaseRoute, "coffee", "id", ":id", use: productController.getProductJsonForId)

    // Images
    app.get(databaseRoute, "images", ":categorie", ":imageName", use: imageController.getImage)

    // Orders
    app.post(databaseRoute, "order", "id", ":id", use: orderController.createOrder)
    app.get(databaseRoute, "order", "id", ":id", use: orderController.getJsonForId)

    // Authentication
    app.post(databaseRoute, "authentication", "register", use: authentificationController.registration)
    app.post(databaseRoute, "authentication", "login", use: authentificationController.login)

//    // MailService
//    app.post(databaseRoute, "mail", "send", use: mailService.sendMail)

    app.get { _ in
        "Welcome to CoffeeAPI"
    }

    app.get("docs") { _ in
        "Welcome to CoffeeAPI Documentation"
    }
}
