import SwiftUI

struct SettingsView: View {
    @AppStorage(Constants.UserDefaultsKeys.apiKey) private var apiKey = ""
    @AppStorage(Constants.UserDefaultsKeys.hapticEnabled) private var hapticEnabled = true
    @State private var showApiKeyInput = false
    @State private var tempKey = ""
    @State private var showSavedBanner = false

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        NavigationStack {
            List {
                // NASA API Key
                Section {
                    HStack {
                        Label("API Key", systemImage: "key")
                        Spacer()
                        Text(apiKey.isEmpty ? "DEMO_KEY" : "••••\(apiKey.suffix(4))")
                            .font(SpaceTheme.captionFont())
                            .foregroundStyle(SpaceTheme.textSecondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        tempKey = apiKey
                        showApiKeyInput = true
                    }

                    Link(destination: URL(string: "https://api.nasa.gov")!) {
                        Label("Get a Free NASA API Key", systemImage: "arrow.up.right.square")
                            .font(.system(size: 14))
                    }
                    .foregroundStyle(SpaceTheme.accent)
                } header: {
                    Text("NASA API")
                } footer: {
                    Text("DEMO_KEY is rate-limited to 30 req/hour. Your own key allows 1,000/hour.")
                }

                // Preferences
                Section("Preferences") {
                    Toggle(isOn: $hapticEnabled) {
                        Label("Haptic Feedback", systemImage: "waveform.path")
                    }
                    .tint(SpaceTheme.accent)
                }

                // Cache
                Section("Cache") {
                    Button(role: .destructive) {
                        URLCache.shared.removeAllCachedResponses()
                        Task { await ImageCache.shared.removeAll() }
                        HapticFeedback.notification(.success)
                    } label: {
                        Label("Clear Image Cache", systemImage: "trash")
                    }
                }

                // About
                Section("About") {
                    LabeledContent("Version", value: "\(appVersion) (\(buildNumber))")
                    LabeledContent("Data Source", value: "NASA Open APIs")
                    Link(destination: URL(string: "https://api.nasa.gov/#browseAPI")!) {
                        Label("NASA API Docs", systemImage: "doc.text")
                    }
                    .foregroundStyle(SpaceTheme.accent)
                    Link(destination: URL(string: "https://github.com/Aliipou/Space-Explorer")!) {
                        Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    .foregroundStyle(SpaceTheme.accent)
                }
            }
            .scrollContentBackground(.hidden)
            .background(SpaceTheme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showApiKeyInput) {
                APIKeySheet(key: $apiKey, tempKey: $tempKey, onSave: {
                    showSavedBanner = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showSavedBanner = false
                    }
                })
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .overlay(alignment: .bottom) {
                if showSavedBanner {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text("API Key saved")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(), value: showSavedBanner)
        }
    }
}

private struct APIKeySheet: View {
    @Binding var key: String
    @Binding var tempKey: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Enter your free NASA API key to increase rate limits from 30 to 1,000 requests per hour.")
                    .font(SpaceTheme.bodyFont())
                    .foregroundStyle(SpaceTheme.textSecondary)

                TextField("NASA API Key", text: $tempKey)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Spacer()
            }
            .padding(24)
            .background(SpaceTheme.background)
            .navigationTitle("NASA API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        key = tempKey.trimmingCharacters(in: .whitespaces)
                        HapticFeedback.notification(.success)
                        onSave()
                        dismiss()
                    }
                    .tint(SpaceTheme.accent)
                }
            }
        }
    }
}
