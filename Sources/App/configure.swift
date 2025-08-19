import Fluent
import FluentSQLiteDriver
import NIOSSL
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    let envPath = app.directory.workingDirectory.appending(".env")
    if FileManager.default.fileExists(atPath: envPath) {
        app.logger.info("Loading environment variables from \(envPath)")
//        try app.environment.arguments = try Environment.
    } else {
        app.logger.warning("No .env file found at \(envPath), using default environment variables")
    }

    // Set IP
    if let ip = Environment.get("--hostname") {
        app.logger.info("Using IP address from environment: \(ip)")
        app.http.server.configuration.hostname = ip

    } else {
        app.logger.warning("No IP address specified, using default '127.0.0.1' aka localhost")
        app.http.server.configuration.hostname = "127.0.0.1"
    }

    // Set Port
    if let port = Environment.get("--port") {
        app.logger.info("Using port from environment: \(port)")
        app.http.server.configuration.port = Int(port) ?? 8080
    } else {
        app.logger.warning("No port specified, using default port 8080")
        app.http.server.configuration.port = 8080
    }

    // Set DB Path
    guard let databasePath = Bundle.module.path(forResource: "CoffeeLover", ofType: "sqlite") else {
        app.logger.error("Database file not found in bundle")
        return
    }

    app.logger.info("Database path from bundle: \(databasePath)")
    let databaseFactory = DatabaseConfigurationFactory.sqlite(.file(databasePath))
    app.databases.use(databaseFactory, as: .sqlite)

    // User Database

    app.routes.caseInsensitive = true
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // Mail Configuration
//    app.smtp.configuration.host = "smtp.server"
    app.smtp.configuration.hostname =  "smtp.gmail.com"
    app.smtp.configuration.port = 587 // attention no secure connection
    app.smtp.configuration.signInMethod = .credentials(username: "johndoe", password: "passw0rd")
    app.smtp.configuration.secure = .startTls // .ssl

    // register routes
    try routes(app)
//    print(app.routes.all)
    app.logger.info("☕      Welcome to Coffee-API!      ☕")

    app.logger.info("Access the API at: http://\(app.http.server.configuration.hostname):\(app.http.server.configuration.port)")
}
