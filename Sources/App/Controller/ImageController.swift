//
//  File.swift
//  CoffeeAPI
//
//  Created by Christoph Rohde on 24.05.25.
//

import Foundation
import Vapor

public struct ImageController: Sendable {
    // Vorhandenes Bild über GET-Request ausliefern
    @Sendable func getImage(req: Request) async throws -> Response {
        print("[GET] http://127.0.0.1:8080/test/images/\(req.parameters.get("categorie") ?? "")/\(req.parameters.get("imageName") ?? "")")
        
        // Kategorie aus der URL extrahieren
        guard let category = req.parameters.get("categorie") else {
            throw Abort(.badRequest, reason: "Keine Kategorie angegeben")
        }
        
        // Bildnamen aus der URL extrahieren
        guard let imageName = req.parameters.get("imageName") else {
            throw Abort(.badRequest, reason: "Kein Bildname angegeben")
        }
        
        // Pfad zum Bild auf dem Server
        let imagePath = "CoffeeAPI/Public/Images/\(category)/Originals/\(imageName)"

        
        print("Image path: \(imagePath)")
        
        // Prüfen, ob die Datei existiert
        guard FileManager.default.fileExists(atPath: imagePath) else {
            throw Abort(.notFound, reason: "Bild nicht gefunden")
        }
        
        // Bild als Daten laden
        guard let fileData = FileManager.default.contents(atPath: imagePath) else {
            throw Abort(.internalServerError, reason: "Fehler beim Lesen der Bilddatei")
        }
        
        // Content-Type basierend auf Dateiendung bestimmen
        let contentType: String
        if imageName.hasSuffix(".jpg") || imageName.hasSuffix(".jpeg") {
            contentType = "image/jpeg"
        } else if imageName.hasSuffix(".png") {
            contentType = "image/png"
        } else if imageName.hasSuffix(".gif") {
            contentType = "image/gif"
        } else if imageName.hasSuffix(".webp") {
            contentType = "image/webp"
        } else {
            contentType = "application/octet-stream" // Fallback
        }

        // Response mit Bild erstellen
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: contentType)
        
        return Response(
            status: .ok,
            headers: headers,
            body: .init(data: fileData)
        )
    }
}
