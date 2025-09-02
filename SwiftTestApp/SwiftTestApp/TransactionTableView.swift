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
    @State private var filteredTransactions: [Transaction] = []
    @State private var sortOrder: [KeyPathComparator<Transaction>] = [
        .init(\.date, order: .reverse) // newest first by default (string date)
    ]
    @State private var selections = Set<Transaction.ID>()
    @State private var isLoading = false
    @State private var loadError: String? = nil
    @State private var pendingSaves: [Transaction.ID: DispatchWorkItem] = [:]
    @State private var filter = "";
    
    let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()
    
    private func binding(for row: Transaction) -> Binding<Transaction> {
        guard let idx = transactions.firstIndex(where: { $0.id == row.id }) else {
            return .constant(row) // non-editable fallback
        }
        return $transactions[idx]
    }
    
    private func scheduleUpdate(for row: Transaction) {
        guard let index = transactions.firstIndex(where: { $0.id == row.id }) else { return }
        let current = transactions[index]

        pendingSaves[row.id]?.cancel()
        let work = DispatchWorkItem {
            API.updateTransaction(current) { result in
                switch result {
                case .success: break
                case .failure(let err): print("Update failed for \(current.id): \(err)")
                }
            }
        }
        pendingSaves[row.id] = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLoading && transactions.isEmpty {
                ProgressView("Loading transactions…")
                    .padding()
            }
            Table(of: Transaction.self, selection: $selections, sortOrder: $sortOrder) {
                TableColumn(Text("Date"), value: \.date) { (t: Transaction) in
                    let b = binding(for: t)
                    TextField("", text: b.date)
                        .onChange(of: b.date.wrappedValue) { scheduleUpdate(for: t) }
                        .onSubmit { scheduleUpdate(for: t) }
                        .appText(.body)
                }
                TableColumn("Description", value: \.description) { (t: Transaction) in
                    let b = binding(for: t)
                    TextField("", text: b.description)
                        .onChange(of: b.description.wrappedValue) { scheduleUpdate(for: t) }
                        .onSubmit { scheduleUpdate(for: t) }
                        .appText(.body)
                }
                TableColumn("Amount", value: \.amount) { (t: Transaction) in
                    let b = binding(for: t)
                    TextField("Amount", value: b.amount, formatter: formatter)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: b.amount.wrappedValue) { scheduleUpdate(for: t) }
                        .onSubmit { scheduleUpdate(for: t) }
                        .appText(.body)
                }
                TableColumn("Category", value: \.category) { (t: Transaction) in
                    let b = binding(for: t)
                    TextField("", text: b.category)
                        .onChange(of: b.category.wrappedValue) { scheduleUpdate(for: t) }
                        .onSubmit { scheduleUpdate(for: t) }
                        .appText(.body)
                }
            } rows: {
                ForEach(filteredTransactions) { t in
                    TableRow(t)
                }
            }
            .frame(minHeight: 300)
            .onChange(of: sortOrder) { oldValue, newValue in
                filteredTransactions.sort(using: newValue)
            }
            .overlay(alignment: .topLeading) {
                if let loadError { Text(loadError).foregroundStyle(.red).padding(8) }
            }
            .task { await loadTransactions() }
            .refreshable { await loadTransactions() }
        }
        .navigationTitle("Transactions")
        
        HStack {
            TextField("Filter", text: $filter)
                .frame(width: 200, alignment: .leading)
                .padding()
                .onChange(of: filter) {
                    if filter.isEmpty {
                        filteredTransactions = transactions
                    }
                    else {
                        let lower = filter.lowercased()
                        filteredTransactions = transactions.filter {
                            $0.description.lowercased().contains(lower) ||
                            $0.category.lowercased().contains(lower) ||
                            $0.date.lowercased().contains(lower) ||
                            String($0.amount).lowercased().contains(lower)
                        }
                    }
                }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .bottom)
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
                        self.filteredTransactions = self.transactions
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
