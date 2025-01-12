//
//  CoinSelectionView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import SwiftUI

struct CoinSelectionView: View {
    // MARK: - Nested Types
    enum Mode {
        case toggle
        case selection
    }
    
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CoinSelectionViewModel()
    @State private var searchText = ""
    
    private let mode: Mode
    private let didToggleCoin: ((Coin, Bool) -> Void)?
    private let didSelectCoin: ((Coin) -> Void)?
    
    // MARK: - Initializers
    init(
        mode: Mode = .toggle,
        didToggleCoin: ((Coin, Bool) -> Void)? = nil,
        didSelectCoin: ((Coin) -> Void)? = nil
    ) {
        self.mode = mode
        self.didToggleCoin = didToggleCoin
        self.didSelectCoin = didSelectCoin
    }
    
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
                    .navigationTitle(mode == .toggle ? "Select Coins" : "Select Coin")
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
    
    // MARK: - Subviews
    @ViewBuilder
    private func makeCoinView(_ coin: Coin) -> some View {
        ZStack(alignment: .leading) {
            Text(coin.marketCapRank.formattedOrNone())
                .font(.caption2)
                .foregroundColor(.gray)
            
            ZStack(alignment: .trailing) {
                HStack(spacing: 12) {
                    CoinImageView(
                        imageURL: coin.image,
                        placeholderText: coin.symbol,
                        size: 36
                    )
                    
                    Text(coin.symbol.uppercased())
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                if mode == .toggle {
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
                } else if mode == .selection {
                    Image(systemName: "chevron.right")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                }
            }
            .padding([.top, .bottom], 4)
            .padding(.leading, 36)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if mode == .selection {
                didSelectCoin?(coin)
                dismiss()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    CoinSelectionView(
        didToggleCoin: { coin, isSaved in
            print("Toggled \(coin.name): \(isSaved)")
        },
        didSelectCoin: { coin in
            print("Selected coin: \(coin.name)")
        }
    )
}