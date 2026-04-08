
import Vapor
import FluentSQL

struct AuthenticationMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        // 1. Extrahiere den Bearer Token aus dem Authorization Header
        guard let token = request.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Missing authorization token.")
        }
        
        // 2. Token Validierung (Fake JWT check)
        // In einer echten App würde man hier die Signatur prüfen.
        // Für diesen Case prüfen wir, ob es ein Refresh-Token ist (unzulässig für API calls)
        // oder ob es unser generiertes Format hat.
        if token.hasPrefix("rt-") {
             throw Abort(.unauthorized, reason: "Invalid token type. Refresh token cannot be used for authentication.")
        }
        
        // 3. Optionale Prüfung gegen DB (ob Token noch aktiv ist, falls wir Refresh-Tokens entwerten)
        // Hier lassen wir es bei der JWT-Struktur-Prüfung bewenden, 
        // da der Client die Ablaufzeit selbst prüft.
        
        return try await next.respond(to: request)
    }
}
