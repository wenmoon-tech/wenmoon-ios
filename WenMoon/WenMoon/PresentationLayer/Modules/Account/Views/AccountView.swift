//
//  AccountView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 19.11.24.
//

import SwiftUI

struct AccountView: View {
    // MARK: - Properties
    @StateObject private var viewModel = AccountViewModel()
    @State private var selectedSetting: Setting!
    
    // MARK: - Body
    var body: some View {
        BaseView(errorMessage: $viewModel.errorMessage) {
            VStack(spacing: 16) {
                makeAuthView()
                
                List {
                    ForEach(viewModel.settings) { setting in
                        makeSettingsRow(setting)
                    }
                }
                .listStyle(.plain)
                
                Spacer()
                
                Text("App Version \(Constants.appVersion)")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
            }
        }
        .sheet(item: $selectedSetting, onDismiss: {
            selectedSetting = nil
        }) { setting in
            SelectionView(
                selectedOption: setupSettingsBinding(setting),
                title: setting.type.title,
                options: setting.type.options
            )
            .presentationDetents([.fraction(0.45)])
            .presentationCornerRadius(36)
        }
        .onChange(of: viewModel.isSignedIn) {
            viewModel.fetchSettings()
        }
        .onAppear {
            viewModel.fetchAuthState()
            viewModel.fetchSettings()
        }
    }
    
    // MARK: - Private Methods
    @ViewBuilder
    private func makeAuthView() -> some View {
        if viewModel.isSignedIn {
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 60, height: 60)
                
                Text(viewModel.userName ?? "User")
                    .font(.headline)
            }
            .padding(.top, 48)
            .padding(.bottom, 24)
        } else {
            VStack(spacing: 16) {
                Image("MoonIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                
                Text("Sign into your account")
                    .font(.headline)
                
                Text("Get customized price signals, watchlist sync and more")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                HStack(spacing: 16) {
                    Button(action: {
                        viewModel.signInWithGoogle()
                    }) {
                        ZStack {
                            if viewModel.isGoogleAuthInProgress {
                                ProgressView()
                            } else {
                                Image("GoogleLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .frame(width: 48, height: 48)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    Button(action: {
                        viewModel.signInWithTwitter()
                    }) {
                        ZStack {
                            if viewModel.isTwitterAuthInProgress {
                                ProgressView()
                            } else {
                                Image("TwitterLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .frame(width: 48, height: 48)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.top, 48)
            .padding(.bottom, 24)
        }
    }
    
    @ViewBuilder
    private func makeSettingsRow(_ setting: Setting) -> some View {
        HStack(spacing: 12) {
            Image(systemName: setting.type.icon)
            
            Text(setting.type.title)
                .font(.body)
            
            Spacer()
            
            if let selectedOption = setting.selectedOption {
                Text(selectedOption)
                    .font(.callout)
                    .foregroundColor(.gray)
            }
            
            Image(systemName: "chevron.right")
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundColor(setting.type == .signOut ? .red : .gray)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            if setting.type == .signOut {
                viewModel.signOut()
            } else {
                selectedSetting = setting
            }
        }
        .disabled(setting.type == .privacyPolicy)
        .foregroundColor(setting.type == .signOut ? .red : .primary)
    }
    
    private func setupSettingsBinding(_ setting: Setting) -> Binding<String> {
        Binding(
            get: {
                viewModel.setting(of: setting.type)?.selectedOption ?? ""
            },
            set: { newValue in
                viewModel.updateSetting(of: setting.type, with: newValue)
            }
        )
    }
}
