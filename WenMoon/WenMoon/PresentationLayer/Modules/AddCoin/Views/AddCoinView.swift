//
//  AddCoinView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import SwiftUI

struct AddCoinView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddCoinViewModel()
    
    @State private var searchText = ""
    
    private(set) var didToggleCoin: ((Coin, Bool) -> Void)?
    
    // MARK: - Body
    var body: some View {
        BaseView(errorMessage: $viewModel.errorMessage) {
            NavigationView {
                ZStack {
                    List {
                        ForEach(viewModel.coins, id: \.self) { coin in
                            makeCoinView(coin)
                                .task {
                                    await viewModel.fetchCoinsOnNextPageIfNeeded(coin)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .navigationTitle("Add Coins")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Close") {
                                dismiss()
                            }
                        }
                    }
                    .searchable(text: $searchText, placement: .toolbar, prompt: "e.g. Bitcoin")
                    .scrollDismissesKeyboard(.immediately)
                    
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
            }
        }
        .onChange(of: searchText) { _, query in
            Task {
                await viewModel.handleSearchInput(query)
            }
        }
        .task {
            await viewModel.fetchCoins()
        }
        .onAppear {
            viewModel.fetchSavedCoins()
        }
    }
    
    // MARK: - Private Methods
    @ViewBuilder
    private func makeCoinView(_ coin: Coin) -> some View {
        ZStack(alignment: .leading) {
            Text(coin.marketCapRank.formattedOrNone())
                .font(.caption2)
                .foregroundColor(.gray)
            
            ZStack(alignment: .trailing) {
                HStack(spacing: .zero) {
                    Text(coin.name + " (" + coin.symbol.uppercased() + ")")
                        .font(.headline)
                        .frame(maxWidth: 240, alignment: .leading)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Spacer()
                }
                
                Toggle("", isOn: Binding<Bool>(
                    get: { viewModel.isCoinSaved(coin) },
                    set: { isSaved in
                        didToggleCoin?(coin, isSaved)
                        viewModel.toggleSaveState(for: coin)
                    }
                ))
                .tint(.wmPink)
                .scaleEffect(0.85)
                .padding(.trailing, -28)
            }
            .padding([.top, .bottom], 4)
            .padding(.leading, 36)
        }
    }
}

// MARK: - Preview
#Preview {
    AddCoinView(
        didToggleCoin: { coin, isSaved in
            print("Toggled \(coin.name): \(isSaved)")
        }
    )
}
