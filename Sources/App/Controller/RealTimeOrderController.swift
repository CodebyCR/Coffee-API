//
//  File.swift
//  CoffeeAPI
//
//  Created by Christoph Rohde on 25.10.25.
//

import Fluent
import FluentSQL
import FluentSQLiteDriver
import Foundation
import SQLiteNIO
import Vapor

public struct RealTimeOrderController: Sendable {
    /// use a websocket and the order id to identify to get the order status in real time
    /// - Parameters:
    ///  - orderId: the order id
    @Sendable
    public func subscribeToOrderUpdates(req: Request, websocket: WebSocket) async {
        guard let orderId = req.parameters.get("id") else {
            do {
                try await websocket.send("Error: Missing orderId parameter")
                print("Found no order id in request")
            } catch {
                print("Failed to send error message: \(error)")
            }
            return
        }

        print("Client subscribed to order updates for orderId: \(orderId)")

        // Simulate sending order status updates every 5 seconds
        let statuses = ["Order Received", "Preparing", "Ready for Pickup", "Completed"]
        for status in statuses {
            do {
                try await Task.sleep(nanoseconds: 5 * 1_000_000_000) // 5 seconds
                let message = "Order \(orderId) status update: \(status)"
                try await websocket.send(message)
                print("Sent to client: \(message)")
            } catch {
                print("Failed to send message: \(error)")
                break
            }
        }

        print("Client unsubscribed from order updates for orderId: \(orderId)")
        try? await websocket.close()
    }
}
