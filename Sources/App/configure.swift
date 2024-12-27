import Fluent
import FluentSQLiteDriver
import NIOSSL
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    let databasePath = app.directory.workingDirectory + "Databases/CoffeeLover.sqlite"
    print("Database path: \(databasePath)")
    let databaseFactory = DatabaseConfigurationFactory.sqlite(.file(databasePath))
    app.databases.use(databaseFactory, as: .sqlite)

//    app.migrations.add(CreateTodo())
    // register routes
    try routes(app)
}
