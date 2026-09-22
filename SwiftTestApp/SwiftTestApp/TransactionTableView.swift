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
    
    @State private var draftID: Transaction.ID? = nil
    @State private var draftError: String? = nil
    
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
    
    private func addDraftRow() {
        let draft = Transaction(id: UUID().uuidString, date: "", description: "", amount: 0.0, category: "")
        transactions.insert(draft, at: transactions.count)
        filteredTransactions = transactions
        selections = [draft.id]
        draftID = draft.id
        draftError = nil
    }
    
    private func tryCommitDraft(_ row: Transaction) {
        guard draftID == row.id else { return }
        
        // Resolve the most recent values from the source of truth
        guard let idx = transactions.firstIndex(where: { $0.id == row.id }) else { return }
        let current = transactions[idx]
        
        // Simple validation – adjust to your schema as needed
        if current.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            draftError = "Description is required"
            return
        }
        if current.date.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            draftError = "Date is required"
            return
        }
        if current.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            draftError = "Category is required"
            return
        }
        if current.amount.isNaN || current.amount == 0 { // choose your rule
            draftError = "Amount must be non-zero"
            return
        }
        
        draftError = nil
        API.postTransaction(current) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    draftID = nil
                }
            case .failure(let err):
                DispatchQueue.main.async {
                    draftError = "Save failed: \(err.localizedDescription)"
                }
            }
        }
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
                        .onChange(of: b.date.wrappedValue) {
                            if draftID != t.id { scheduleUpdate(for: t) }
                        }
                        .onSubmit {
                            if draftID == t.id { tryCommitDraft(t) } else { scheduleUpdate(for: t) }
                        }
                        .appText(.body)
                }
                TableColumn("Description", value: \.description) { (t: Transaction) in
                    let b = binding(for: t)
                    TextField("", text: b.description)
                        .onChange(of: b.date.wrappedValue) {
                            if draftID != t.id { scheduleUpdate(for: t) }
                        }
                        .onSubmit {
                            if draftID == t.id { tryCommitDraft(t) } else { scheduleUpdate(for: t) }
                        }
                        .appText(.body)
                }
                TableColumn("Amount", value: \.amount) { (t: Transaction) in
                    let b = binding(for: t)
                    TextField("Amount", value: b.amount, formatter: formatter)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: b.amount.wrappedValue) {
                            if draftID != t.id { scheduleUpdate(for: t) }
                        }
                        .onSubmit {
                            if draftID == t.id { tryCommitDraft(t) } else { scheduleUpdate(for: t) }
                        }
                        .appText(.body)
                }
                TableColumn("Category", value: \.category) { (t: Transaction) in
                    let b = binding(for: t)
                    TextField("", text: b.category)
                        .onChange(of: b.category.wrappedValue) {
                            if draftID != t.id { scheduleUpdate(for: t) }
                        }
                        .onSubmit {
                            if draftID == t.id { tryCommitDraft(t) } else { scheduleUpdate(for: t) }
                        }
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
        .tableStyle(.inset)
        .navigationTitle("Transactions")
        
        Divider()
        
        HStack {
            TextField("Filter", text: $filter)
                .textFieldStyle(.roundedBorder)     // gives internal insets
                .controlSize(.extraLarge)
                .padding(16)
                .frame(width: 200, alignment: .leading)
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
            Button("Add Transaction") {
                // TODO: implement action
                addDraftRow()
                print("Add Transaction tapped")
            }
            .padding(.trailing)
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .bottom)
        if let draftError {
            Text(draftError)
                .foregroundStyle(.red)
                .font(.footnote)
                .padding([.leading, .bottom])
        }
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
