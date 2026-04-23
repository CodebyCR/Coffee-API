
import Fluent
import FluentSQL
import FluentSQLiteDriver
import SQLiteNIO
import Vapor

private let productController = ProductController()
private let imageController = ImageController()
private let orderController = OrderController()
private let authentificationController = AuthentificationController()
private let realTimeOrderController = RealTimeOrderController()

func configure(_ app: Application) throws {
    // Verwende SQLite als Datenbank
    app.databases.use(.sqlite(.memory), as: .sqlite)

    try routes(app)
}

func routes(_ app: Application) throws {
    let databaseRoute: PathComponent = "test"
    let authMiddleware = AuthenticationMiddleware()

    // Public Routes
    // Images are typically public for simple apps
    app.get(databaseRoute, "images", ":categorie", ":imageName", use: imageController.getImage)

    // Products (Menu) should be public so they can be loaded on startup
    app.get(databaseRoute, "coffee", "ids", use: productController.getIds)
    app.get(databaseRoute, "coffee", "id", ":id", use: productController.getProductJsonForId)

    // Authentication (Registration, Login, Refresh) are public
    let authGroup = app.grouped(databaseRoute, "authentication")
    authGroup.post("register", use: authentificationController.registration)
    authGroup.post("login", use: authentificationController.login)
    authGroup.post("refresh", use: authentificationController.refreshToken)

    // Protected Routes (Ordering requires a token)
    let protectedGroup = app.grouped(databaseRoute).grouped(authMiddleware)

    // Orders
    protectedGroup.post("order", "id", ":id", use: orderController.createOrder)
    protectedGroup.get("order", "id", ":id", use: orderController.getJsonForId)
    protectedGroup.get("order", "history", ":before", use: orderController.getHistory)
    
    // WebSocket
    app.webSocket(databaseRoute, "order", "status", ":id", onUpgrade: realTimeOrderController.subscribeToOrderUpdates)

    app.get { _ in
        "☕      Welcome to Coffee-API      ☕"
    }

    app.get("docs") { _ in
        "☕      Welcome to Coffee-API      ☕"
    }
}
