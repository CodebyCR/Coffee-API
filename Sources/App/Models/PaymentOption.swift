//
//  PaymentOption.swift
//  CoffeeAPI
//
//  Created by Christoph Rohde on 11.03.25.
//
import Foundation
import Vapor

public enum PaymentOption: String, CaseIterable, Sendable, Codable, Content {
    case applePay = "ApplePay"
    case cash = "Cash"

    public static func get(by name: String) -> Self? {
        allCases.first { $0.rawValue == name }
    }
}
