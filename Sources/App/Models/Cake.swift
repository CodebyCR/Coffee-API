import Foundation
import Vapor

struct Cake: Content, Identifiable {
    var id: UInt16
    let name: String
    let price: Float64
    let date: Date
}