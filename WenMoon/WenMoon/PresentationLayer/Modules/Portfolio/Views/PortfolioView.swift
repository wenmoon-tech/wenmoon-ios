//
//  PortfolioView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 05.12.24.
//

import SwiftUI

struct PortfolioView: View {
    // MARK: - Properties
    @EnvironmentObject private var viewModel: PortfolioViewModel
    
    @State private var showAddTransactionView = false
    
    @State private var expandedRows: Set<String> = []
    @State private var swipedTransaction: Transaction?
    
    // MARK: - Body
    var body: some View {
        BaseView(errorMessage: $viewModel.errorMessage) {
            NavigationView {
                VStack {
                    makePortfolioHeaderView()
                    makePortfolioContentView()
                }
                .navigationTitle("Portfolio")
            }
        }
        .sheet(isPresented: $showAddTransactionView) {
            AddTransactionView(didAddTransaction: { newTransaction, coin in
                Task {
                    await viewModel.addTransaction(newTransaction, coin)
                }
            })
            .presentationDetents([.medium])
            .presentationCornerRadius(36)
        }
        .sheet(item: $swipedTransaction, onDismiss: {
            swipedTransaction = nil
        }) { transaction in
            if let coinID = transaction.coinID,
               let coin = viewModel.fetchCoin(by: coinID) {
                AddTransactionView(
                    transaction: transaction,
                    mode: .edit,
                    selectedCoin: coin,
                    didEditTransaction: { updatedTransaction in
                        viewModel.editTransaction(updatedTransaction)
                    }
                )
                .presentationDetents([.medium])
                .presentationCornerRadius(36)
            }
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func makePortfolioHeaderView() -> some View {
        VStack(spacing: 8) {
            Text(viewModel.totalValue.formattedAsCurrency())
                .font(.largeTitle).bold()
                .foregroundColor(.wmPink)
            
            HStack {
                Text(viewModel.portfolioChangePercentage.formattedAsPercentage())
                    .font(.footnote).bold()
                    .foregroundColor(.gray)
                
                Text(viewModel.portfolioChangeValue.formattedAsCurrency(includePlusSign: true))
                    .font(.footnote).bold()
                    .foregroundColor(.gray)
                
                Text(viewModel.selectedTimeline.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .animation(.easeInOut, value: viewModel.selectedTimeline)
            .onTapGesture {
                viewModel.toggleSelectedTimeline()
            }
        }
        .padding(.vertical, 32)
    }
    
    @ViewBuilder
    private func makePortfolioContentView() -> some View {
        let groupedTransactions = viewModel.groupedTransactions
        VStack {
            if groupedTransactions.isEmpty {
                makeAddTransactionButton()
                Spacer()
                PlaceholderView(text: "No transactions yet")
                Spacer()
            } else {
                List {
                    ForEach(groupedTransactions, id: \.coin.id) { group in
                        makeTransactionsSummaryView(for: group, isExpanded: expandedRows.contains(group.coin.id))
                            .onTapGesture {
                                withAnimation {
                                    toggleRowExpansion(for: group.coin.id)
                                }
                                viewModel.triggerImpactFeedback()
                            }
                        
                        if expandedRows.contains(group.coin.id) {
                            makeExpandedTransactionsView(for: group)
                        }
                    }
                    makeAddTransactionButton()
                }
                .listStyle(.plain)
                .refreshable {
                    viewModel.fetchPortfolios()
                }
            }
        }
        .animation(.easeInOut, value: groupedTransactions)
    }
    
    @ViewBuilder
    private func makeAddTransactionButton() -> some View {
        Button {
            showAddTransactionView = true
        } label: {
            HStack {
                Image(systemName: "slider.horizontal.3")
                Text("Add Transaction")
            }
            .frame(maxWidth: .infinity)
        }
        .listRowSeparator(.hidden)
        .buttonStyle(.borderless)
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func makeTransactionsSummaryView(for group: CoinTransactions, isExpanded: Bool) -> some View {
        HStack(spacing: 16) {
            CoinImageView(
                imageData: group.coin.imageData,
                placeholderText: group.coin.symbol,
                size: 36
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.coin.symbol)
                    .font(.subheadline).bold()
                
                Text(group.totalQuantity.formattedAsQuantity())
                    .font(.caption).bold()
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(group.totalValue.formattedAsCurrency())
                .font(.footnote).bold()
            
            Image(systemName: "chevron.up")
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundColor(.gray)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
        }
        .listRowSeparator(.hidden)
        .swipeActions {
            Button(role: .destructive) {
                viewModel.deleteTransactions(for: group.coin.id)
            } label: {
                Image("trash")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func makeExpandedTransactionsView(for group: CoinTransactions) -> some View {
        Group {
            ForEach(group.transactions.keys.sorted(by: { $0 > $1 }), id: \.self) { date in
                Section(date.formatted(as: .dateOnly)) {
                    ForEach(group.transactions[date] ?? [], id: \.id) { transaction in
                        makeTransactionView(group.coin, transaction)
                            .swipeActions {
                                Button(role: .destructive) {
                                    viewModel.deleteTransaction(transaction.id)
                                } label: {
                                    Image("trash")
                                }
                                
                                Button {
                                    swipedTransaction = transaction.copy()
                                } label: {
                                    Image("pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
                .listRowSeparator(.hidden)
            }
        }
    }
    
    @ViewBuilder
    private func makeTransactionView(_ coin: CoinData, _ transaction: Transaction) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.type.rawValue)
                    .font(.subheadline).bold()
                
                Text(transaction.pricePerCoin.formattedAsCurrency())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    let isDeductiveTransaction = viewModel.isDeductiveTransaction(transaction.type)
                    Text(transaction.quantity.formattedAsQuantity(includeMinusSign: isDeductiveTransaction))
                    Text(coin.symbol)
                }
                .font(.footnote).bold()
                
                Text(transaction.totalCost.formattedAsCurrency())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func toggleRowExpansion(for key: String) {
        if expandedRows.contains(key) {
            expandedRows.remove(key)
        } else {
            expandedRows.insert(key)
        }
    }
}

// MARK: - Previews
struct PortfolioView_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioView()
    }
}
