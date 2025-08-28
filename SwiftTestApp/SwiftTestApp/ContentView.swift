//
//  ContentView.swift
//  SwiftTestApp
//
//  Created by Ross Bower on 8/13/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            TransactionTableView()
        }
    }
}

#Preview {
    ContentView()
}
