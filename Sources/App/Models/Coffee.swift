//
//  Coffee.swift
//  CoffeeAPI
//
//  Created by Christoph Rohde on 21.10.24.
//
import Foundation
import Vapor

struct Coffee: Content, Identifiable {
    let id: UUID
    let productNumber: UInt16
    let name: String
    let price: Float64
}
