import SwiftUI

struct ContentView: View {
    @State private var transactions: [Transaction] = []
    @State private var description: String = ""
    @State private var amount: Double = 0
    @State private var category: String = ""
    @State private var date: String = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: HStack {
                        Text("Date").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Description").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Category").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Amount").frame(maxWidth: .infinity, alignment: .trailing)
                    }) {
                        ForEach(transactions) { t in
                            HStack {
                                EditableTextField(text: .constant(t.date))
                                EditableTextField(text: .constant(t.description))
                                EditableTextField(text: .constant(t.category))
                                EditableTextField(text: .constant(String(format: "%.2f", t.amount)))
                            }
                        }
                        .onDelete(perform: deleteTransaction)
                    }
                }
                .onAppear {
                    API.fetchTransactions { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let data):
                                print("✅ Got transactions: \(data.count)")
                                self.transactions = data
                            case .failure(let error):
                                print("❌ Fetch failed: \(error)")
                            }
                        }
                    }
                }
                
                // Input controls
                VStack {
                    TextField("Date", text: $date)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Description", text: $description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        #if os(iOS)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        #else
                    TextField("Amount", value: $amount, format:.number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        #endif
                    TextField("Category", text: $category)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Add Transaction") {
                        let newTx = Transaction(
                            id: UUID().uuidString,
                            date: date,
                            description: description,
                            amount: amount,
                            category: category)
                        API.postTransaction(newTx) { _ in }
                        transactions.append(newTx)
                    }
                }
                .padding()
            }
            .navigationTitle("Budgetr")
        }
    }
    
    func deleteTransaction(at offsets: IndexSet) {
        for index in offsets {
            let tx = transactions[index]
            API.deleteTransaction(id: tx.id) { _ in }
        }
        transactions.remove(atOffsets: offsets)
    }
}
