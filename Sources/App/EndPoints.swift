//
//  EndPoints.swift
//  CoffeeAPI
//
//  Created by Christoph Rohde on 20.01.25.
//

public enum EndPoints {
    
    
    enum Coffee {
        case getAll
        case getById(id: String)
        
        
        func url() -> String {
            let baseUrl = "http://127.0.0.1:8080/test/"
            
            switch self {
            case .getAll:
                return "\(baseUrl)/coffees"
            case .getById(let id):
                return "\(baseUrl)/coffee/id/\(id)"
            default:
                return "Unknown Coffee EndPoint"
            }
        }
        
        enum Cake {
            case getAll
            case getById(id: String)
            
            func url() -> String {
                let baseUrl = "http://127.0.0.1:8080/test/"
                
                switch self {
                case .getAll:
                    return "\(baseUrl)/cakes"
                case .getById(let id):
                    return "\(baseUrl)/cake/id/\(id)"
                default:
                    return "Unknown Cake EndPoint"
                }
            }
        }
        
        enum Order {
            case getAll
            case getById(id: String)
            
            func url() -> String {
                let baseUrl = "http://127.0.0.1:8080/test/"
                
                switch self {
                case .getAll:
                    return "\(baseUrl)/orders"
                case .getById(let id):
                    return "\(baseUrl)/order/id/\(id)"
                default:
                    return "Unknown Order EndPoint"
                }
            }
        }
    }
}
