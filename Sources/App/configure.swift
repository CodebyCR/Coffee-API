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
    if let ip = Environment.get("DATABASE_HOSTNAME") {
        app.logger.info("Using IP address from environment: \(ip)")
        app.http.server.configuration.hostname = ip
    }
    else {
        app.logger.warning("No IP address specified, using default '127.0.0.1' aka localhost")
        app.http.server.configuration.hostname = "127.0.0.1"
    }

    // Set Port
    if let port = Environment.get("DATABASE_PORT") {
        app.logger.info("Using port from environment: \(port)")
        app.http.server.configuration.port = Int(port) ?? 8080
    } else {
        app.logger.warning("No port specified, using default port 8080")
        app.http.server.configuration.port = 8080
    }

    // Set DB Path
    if let databasePath = Environment.get("database_path") {
        app.logger.info("Using database path from environment: \(databasePath)")
        let databaseFactory = DatabaseConfigurationFactory.sqlite(.file(databasePath))
        app.databases.use(databaseFactory, as: .sqlite)
    } else {
        app.logger.warning("No database path specified, using default path")
        let databasePath = app.directory.workingDirectory + "CoffeeAPI/Databases/CoffeeLover.sqlite"
        print("Database path: \(databasePath)")
        let databaseFactory = DatabaseConfigurationFactory.sqlite(.file(databasePath))
        app.databases.use(databaseFactory, as: .sqlite)
    }

    // User Database
    


    app.routes.caseInsensitive = true
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))




    // register routes
    try routes(app)
//    print(app.routes.all)
}
