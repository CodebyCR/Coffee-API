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
            throw Abort(.badRequest, reason: "No 'categorie' Supplied.")
        }
        
        // Bildnamen aus der URL extrahieren
        guard let imageName = req.parameters.get("imageName") else {
            throw Abort(.badRequest, reason: "No 'imageName' supplied.")
        }
        
        // Pfad zum Bild auf dem Server
        let imagePath = "CoffeeAPI/Public/Images/\(category)/Originals/\(imageName)"

        
        print("Image path: \(imagePath)")
        
        // Prüfen, ob die Datei existiert
        guard FileManager.default.fileExists(atPath: imagePath) else {
            throw Abort(.notFound, reason: "Image not found.")
        }
        
        // Bild als Daten laden
        guard let fileData = FileManager.default.contents(atPath: imagePath) else {
            throw Abort(.internalServerError, reason: "Image unreadable.")
        }
        

        // get substring von "." bis ende
        let imageSuffix = imageName.suffix(while: { $0 != "." }).lowercased()

        // Content-Type basierend auf Dateiendung bestimmen
        let contentType = switch imageSuffix {
        case ".jpg", ".jpeg":
            "image/jpeg"
        case ".png":
            "image/png"
        case ".gif":
            "image/gif"
        case ".webp":
            "image/webp"
        default:
            "application/octet-stream" // Fallback für unbekannte Formate
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
