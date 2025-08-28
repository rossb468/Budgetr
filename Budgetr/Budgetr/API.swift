import Foundation

struct Transaction: Identifiable, Codable {
    var id: String
    var date: String
    var description: String
    var amount: Double
    var category: String
}

class API {
    static let baseURL = "https://www.cs.drexel.edu/~rb468/api"

    static func fetchTransactions(completion: @escaping (Result<[Transaction], Error>) -> Void) {
        let url = URL(string: "\(baseURL)/getTransactions.php")!
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { return }
            do {
                let transactions = try JSONDecoder().decode([Transaction].self, from: data)
                completion(.success(transactions))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    static func postTransaction(_ transaction: Transaction, completion: @escaping (Result<Void, Error>) -> Void) {
        var req = URLRequest(url: URL(string: "\(baseURL)/addTransaction.php")!)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(transaction)
        URLSession.shared.dataTask(with: req) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            completion(.success(()))
        }.resume()
    }

    static func deleteTransaction(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        var req = URLRequest(url: URL(string: "\(baseURL)/deleteTransaction.php")!)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(["id": id])
        URLSession.shared.dataTask(with: req) { _, _, error in
            if let error = error { completion(.failure(error)); return }
            completion(.success(()))
        }.resume()
    }

    static func updateTransaction(_ transaction: Transaction, completion: @escaping (Result<Void, Error>) -> Void) {
        var req = URLRequest(url: URL(string: "\(baseURL)/updateTransaction.php")!)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(transaction)
        URLSession.shared.dataTask(with: req) { _, _, error in
            if let error = error { completion(.failure(error)); return }
            completion(.success(()))
        }.resume()
    }
}//
//  API.swift
//  Budgetr
//
//  Created by Ross Bower on 7/20/25.
//

