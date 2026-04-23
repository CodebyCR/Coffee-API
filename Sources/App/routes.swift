
import Fluent
import FluentSQL
import FluentSQLiteDriver
import SQLiteNIO
import Vapor
import VaporToOpenAPI

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
        .openAPI(
            tags: "Images",
            summary: "Get Image",
            description: "Fetches a product image by its category (e.g., coffee, cake) and filename. Returns the image file directly."
        )

    // Products (Menu) should be public so they can be loaded on startup
    app.get(databaseRoute, "coffee", "ids", use: productController.getIds)
        .openAPI(
            tags: "Products",
            summary: "Get all product IDs",
            description: "Returns a list of all available product IDs, ordered by category and internal sequence."
        )
    app.get(databaseRoute, "coffee", "id", ":id", use: productController.getProductJsonForId)
        .openAPI(
            tags: "Products",
            summary: "Get product by ID",
            description: "Returns detailed information about a specific product, including name, price, image reference, and metadata like tags."
        )

    // Authentication (Registration, Login, Refresh) are public
    let authGroup = app.grouped(databaseRoute, "authentication")
    authGroup.post("register", use: authentificationController.registration)
        .openAPI(
            tags: "Authentication",
            summary: "Register new user",
            description: "Creates a new user account with a username and password. Returns user details upon success."
        )
    authGroup.post("login", use: authentificationController.login)
        .openAPI(
            tags: "Authentication",
            summary: "Login",
            description: "Authenticates a user and returns a Bearer token and a refresh token."
        )
    authGroup.post("refresh", use: authentificationController.refreshToken)
        .openAPI(
            tags: "Authentication",
            summary: "Refresh Token",
            description: "Invalidates the old refresh token and issues a new pair of access and refresh tokens."
        )

    // Protected Routes (Ordering requires a token)
    let protectedGroup = app.grouped(databaseRoute).grouped(authMiddleware)

    // Orders
    protectedGroup.post("order", "id", ":id", use: orderController.createOrder)
        .openAPI(
            tags: "Orders",
            summary: "Create Order",
            description: "Places a new order for a specific product ID. Requires a valid authentication token.",
            auth: .bearer()
        )
    protectedGroup.get("order", "id", ":id", use: orderController.getJsonForId)
        .openAPI(
            tags: "Orders",
            summary: "Get Order by ID",
            description: "Fetches the details and current status of a specific order.",
            auth: .bearer()
        )
    protectedGroup.get("order", "history", ":before", use: orderController.getHistory)
        .openAPI(
            tags: "Orders",
            summary: "Get Order History",
            description: "Returns a list of past orders for the authenticated user, filtered by a timestamp (before).",
            auth: .bearer()
        )
    
    // WebSocket
    app.webSocket(databaseRoute, "order", "status", ":id", onUpgrade: realTimeOrderController.subscribeToOrderUpdates)
        .openAPI(
            tags: "Orders",
            summary: "Subscribe to Order Updates (WebSocket)",
            description: "Establishes a WebSocket connection to receive real-time updates for a specific order status."
        )

    app.get { _ in
        "☕      Welcome to Coffee-API      ☕"
    }
    .openAPI(
        tags: "General",
        summary: "Welcome Page",
        description: "Returns a simple welcome message."
    )

    // OpenAPI JSON
    app.get("openapi.json") { req -> Response in
        let openAPI = app.routes.openAPI(
            info: InfoObject(
                title: "CoffeeAPI",
                description: "API for Coffee Ordering System",
                version: "1.0.0"
            )
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(openAPI)
        let res = Response(status: .ok, body: .init(data: data))
        res.headers.replaceOrAdd(name: .contentType, value: "application/json; charset=utf-8")
        return res
    }

    // Swagger UI
    app.get("docs") { req in
        RawHTML(html: """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <title>CoffeeAPI - SwaggerUI</title>
            <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css" />
            <style>
                html { box-sizing: border-box; overflow: -moz-scrollbars-vertical; overflow-y: scroll; }
                *, *:before, *:after { box-sizing: inherit; }
                body { margin: 0; background: #fafafa; }
            </style>
        </head>
        <body>
            <div id="swagger-ui"></div>
            <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js" crossorigin></script>
            <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-standalone-preset.js" crossorigin></script>
            <script>
                window.onload = () => {
                    window.ui = SwaggerUIBundle({
                        url: '/openapi.json',
                        dom_id: '#swagger-ui',
                        deepLinking: true,
                        presets: [
                            SwaggerUIBundle.presets.apis,
                            SwaggerUIStandalonePreset
                        ],
                        layout: "StandaloneLayout",
                    });
                };
            </script>
        </body>
        </html>
        """)
    }
}

struct RawHTML: ResponseEncodable {
    let html: String
    func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
        let res = Response(status: .ok, body: .init(string: html))
        res.headers.replaceOrAdd(name: .contentType, value: "text/html; charset=utf-8")
        return request.eventLoop.makeSucceededFuture(res)
    }
}
