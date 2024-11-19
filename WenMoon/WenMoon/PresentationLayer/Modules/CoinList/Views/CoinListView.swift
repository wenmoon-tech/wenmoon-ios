//
//  CoinListView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import SwiftUI

struct CoinListView: View {
    // MARK: - Properties
    @StateObject private var viewModel = CoinListViewModel()
    
    @State private var isEditMode: EditMode = .inactive
    @State private var chartDrawProgress: CGFloat = .zero
    @State private var shouldShowAddCoinView = false
    @State private var showSetPriceAlertConfirmation = false
    @State private var capturedCoin: CoinData?
    @State private var targetPrice: Double?
    @State private var toggleOffCoinID: String?
    
    @State private var selectedCoin: CoinData!
    @State private var shouldShowCoinDetailsView = false
    
    // MARK: - Body
    var body: some View {
        BaseView(errorMessage: $viewModel.errorMessage) {
            NavigationView {
                List {
                    ForEach(viewModel.coins, id: \.self) { coin in
                        makeCoinView(coin)
                    }
                    .onMove(perform: moveCoin)
                    
                    Button(action: {
                        shouldShowAddCoinView.toggle()
                    }) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                            Text("Add Coins")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .listRowSeparator(.hidden)
                    .buttonStyle(.borderless)
                }
                .listStyle(.plain)
                .environment(\.editMode, $isEditMode)
                .animation(.default, value: viewModel.coins)
                .refreshable {
                    Task {
                        await viewModel.fetchMarketData()
                    }
                }
                .navigationTitle("Coins")
            }
        }
        .sheet(isPresented: $shouldShowAddCoinView) {
            AddCoinView(didToggleCoin: handleCoinSelection)
        }
        .sheet(item: $selectedCoin, onDismiss: {
            selectedCoin = nil
        }) { coin in
            CoinDetailsView(coin: coin, chartData: viewModel.chartData[coin.symbol] ?? [:])
                .presentationDetents([.medium])
                .presentationCornerRadius(36)
        }
        .alert("Set Price Alert", isPresented: $showSetPriceAlertConfirmation, actions: {
            TextField("Target Price", value: $targetPrice, format: .number)
                .keyboardType(.decimalPad)
            
            Button("Confirm") {
                if let coin = capturedCoin {
                    Task {
                        await viewModel.setPriceAlert(for: coin, targetPrice: targetPrice)
                        capturedCoin = nil
                        targetPrice = nil
                    }
                }
            }
            
            Button("Cancel", role: .cancel) {
                capturedCoin = nil
                targetPrice = nil
            }
        }) {
            Text("Please enter your target price in USD, and our system will notify you when it is reached")
        }
        .onReceive(NotificationCenter.default.publisher(for: .targetPriceReached)) { notification in
            if let coinID = notification.userInfo?["coinID"] as? String {
                viewModel.toggleOffPriceAlert(for: coinID)
            }
        }
        .task {
            await viewModel.fetchCoins()
            await viewModel.fetchChartData()
            await viewModel.fetchPriceAlerts()
        }
    }
    
    // MARK: - Private Methods
    @ViewBuilder
    private func makeCoinView(_ coin: CoinData) -> some View {
        HStack(spacing: .zero) {
            if let data = coin.imageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .cornerRadius(8)
                    .grayscale(0.4)
            } else {
                ZStack {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 48, height: 48)
                    
                    Text(coin.name.prefix(1))
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .brightness(-0.1)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(coin.symbol.uppercased())
                    .font(.headline)
                
                Text(coin.currentPrice.formattedAsCurrency())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.leading, 16)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                ChartShape(value: coin.priceChangePercentage24H ?? .zero)
                    .trim(from: .zero, to: chartDrawProgress)
                    .stroke(Color.wmPink, lineWidth: 2)
                    .frame(width: 50, height: 10)
                    .onAppear {
                        withAnimation {
                            chartDrawProgress = 1
                        }
                    }
                
                Text(coin.priceChangePercentage24H.formattedAsPercentage())
                    .font(.caption2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedCoin = coin
        }
        .onLongPressGesture {
            isEditMode = .active
        }
        .swipeActions {
            Button(role: .destructive) {
                Task {
                    await viewModel.deleteCoin(coin.id)
                }
            } label: {
                Image(systemName: "heart.slash.fill")
            }
            .tint(.wmPink)
        }
    }
    
    private func moveCoin(from source: IndexSet, to destination: Int) {
        viewModel.coins.move(fromOffsets: source, toOffset: destination)
        viewModel.saveCoinOrder()
    }
    
    private func handleCoinSelection(coin: Coin, shouldAdd: Bool) {
        Task {
            if shouldAdd {
                await viewModel.saveCoin(coin)
                await viewModel.fetchChartData(for: coin.symbol)
            } else {
                await viewModel.deleteCoin(coin.id)
            }
            viewModel.saveCoinOrder()
        }
    }
}

// MARK: - Preview
#Preview {
    CoinListView()
}
