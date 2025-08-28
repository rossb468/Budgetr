//
//  FruitListView.swift
//  SwiftTestApp
//
//  Created by Ross Bower on 8/13/25.
//

import SwiftUI
import Combine

struct TransactionTableView: View {
    @State private var transactions: [Transaction] = []
    @State private var sortOrder: [KeyPathComparator<Transaction>] = [
        .init(\.date, order: .reverse) // newest first by default (string date)
    ]
    @State private var isLoading = false
    @State private var loadError: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            if isLoading && transactions.isEmpty {
                ProgressView("Loading transactions…")
                    .padding()
            }

            Table($transactions, sortOrder: $sortOrder) {
                TableColumn("Date") { (t: Binding<Transaction>) in
                    TextField("Date", text: t.date)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                TableColumn("Description") { (t: Binding<Transaction>) in
                    TextField("Description", text: t.description)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                TableColumn("Category") { (t: Binding<Transaction>) in
                    TextField("Category", text: t.category)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                TableColumn("Amount") { (t: Binding<Transaction>) in
                    TextField("Amount", text: Binding(
                        get: { String(t.amount) },
                        set: { t.amount = Double($0) ?? t.amount }
                    ))
                }
            }
            .frame(minHeight: 300)
            .onChange(of: sortOrder) { oldValue, newValue in
                transactions.sort(using: newValue)
            }
            .overlay(alignment: .topLeading) {
                if let loadError { Text(loadError).foregroundStyle(.red).padding(8) }
            }
            .task { await loadTransactions() }
            .refreshable { await loadTransactions() }
        }
        .navigationTitle("Transactions")
    }

    // MARK: - Data
    @MainActor
    private func loadTransactions() async {
        isLoading = true
        loadError = nil
        await withCheckedContinuation { cont in
            API.fetchTransactions { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let txns):
                        self.transactions = txns
                    case .failure(let error):
                        self.loadError = "Failed to load: \(error.localizedDescription)"
                    }
                    self.isLoading = false
                    cont.resume()
                }
            }
        }
    }
}

struct FruitListView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionTableView();
    }
}
