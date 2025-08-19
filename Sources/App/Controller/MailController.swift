//
//  MailController.swift
//  CoffeeAPI
//
//  Created by Christoph Rohde on 05.07.25.
//

import Foundation
import Smtp
import Vapor

public struct MailController: Sendable {
    init() {}

    public func sendConfirmAccountMail(to email: String, username name: String, token: String, request: Request) async throws {
        let from = EmailAddress(address: "no-reply@coffeelover.com", name: "Coffee Lover")
        let to = EmailAddress(address: "iich@live.de", name: name)

        let subject = "Confirm your Coffee Lover account"

        let body = """
        <html>
        <head>
            <title>Confirm your Coffee Lover account</title>
        </head>
        <body>
            <h1>Confirm your account</h1>
            <p>Click the link below to confirm your account:</p>
            <a href="https://example.com/confirm?token=\(token)">Confirm Account</a>
            <p>If you did not create an account, you can ignore this email.</p>
        </body>
        </html>
        """

        guard let mail = try? Email(
            from: from,
            to: [to],
            subject: subject,
            body: body,
            isBodyHtml: true
        ) else {
            throw Abort(.internalServerError, reason: "Failed to create email")
        }

        request.smtp.send(mail).map { result in
            switch result {
            case .success:
                print("Email has been sent")
            case .failure(let error):
                print("Email has not been sent: \(error)")

            }
        }
    }
}
