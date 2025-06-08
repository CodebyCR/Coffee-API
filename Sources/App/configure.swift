import Fluent
import FluentSQLiteDriver
import NIOSSL
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    let databasePath = app.directory.workingDirectory + "CoffeeAPI/Databases/CoffeeLover.sqlite"
    print("Database path: \(databasePath)")
    let databaseFactory = DatabaseConfigurationFactory.sqlite(.file(databasePath))
    app.databases.use(databaseFactory, as: .sqlite)


    // register routes
    try routes(app)
}
