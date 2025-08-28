//
//  Transaction.swift
//  SwiftTestApp
//
//  Created by Ross Bower on 8/15/25.
//

struct Transaction: Identifiable, Codable {
    var id: String
    var date: String
    var description: String
    var amount: Double
    var category: String
}
