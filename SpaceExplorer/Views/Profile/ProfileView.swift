import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthService
    @StateObject private var vm = ProfileViewModel()
    @State private var isEditingName = false
    @State private var draftName = ""
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A1A").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar + name header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 88, height: 88)
                                Text(initials)
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundStyle(.white)
                            }

                            if isEditingName {
                                HStack {
                                    TextField("Display name", text: $draftName)
                                        .font(.title2.bold())
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.center)
                                        .textInputAutocapitalization(.words)
                                    Button("Save") {
                                        Task { await vm.updateName(draftName) }
                                        isEditingName = false
                                    }
                                    .foregroundStyle(.blue)
                                }
                                .padding(.horizontal, 32)
                            } else {
                                HStack(spacing: 6) {
                                    Text(auth.currentUser?.displayName ?? auth.currentUser?.email ?? "—")
                                        .font(.title2.bold())
                                        .foregroundStyle(.white)
                                    Button { draftName = auth.currentUser?.displayName ?? ""; isEditingName = true } label: {
                                        Image(systemName: "pencil.circle")
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                                }
                            }

                            Text(auth.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(.top, 24)

                        // Stats row
                        HStack(spacing: 0) {
                            StatCell(value: "\(vm.profile?.favoritesCount ?? 0)", label: "Favorites")
                            Divider().frame(height: 40).background(Color.white.opacity(0.1))
                            StatCell(value: "\(vm.historyCount)", label: "History")
                            Divider().frame(height: 40).background(Color.white.opacity(0.1))
                            StatCell(value: vm.memberSince, label: "Member since")
                        }
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                        // Sync section
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                                .font(.headline)
                                .foregroundStyle(.white)

                            Button(action: { Task { await vm.syncFavorites() } }) {
                                HStack {
                                    Text(vm.syncStatus)
                                    Spacer()
                                    if vm.isSyncing { ProgressView().tint(.white) }
                                    else { Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.3)) }
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .foregroundStyle(.white)
                        }
                        .padding(.horizontal)

                        // History section
                        if !vm.recentHistory.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Label("Recent Searches", systemImage: "clock")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Button("Clear", role: .destructive) { Task { await vm.clearHistory() } }
                                        .font(.caption)
                                }
                                ForEach(vm.recentHistory) { entry in
                                    HStack {
                                        Image(systemName: entry.resultType == "mars" ? "globe" : "sparkles")
                                            .foregroundStyle(.white.opacity(0.4))
                                            .frame(width: 20)
                                        Text(entry.query)
                                            .foregroundStyle(.white.opacity(0.8))
                                            .font(.subheadline)
                                        Spacer()
                                        Text(entry.relativeDate)
                                            .foregroundStyle(.white.opacity(0.35))
                                            .font(.caption2)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Logout
                        Button(role: .destructive) { showLogoutConfirm = true } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task { await vm.load() }
            .confirmationDialog("Sign out?", isPresented: $showLogoutConfirm) {
                Button("Sign Out", role: .destructive) { Task { await auth.logout() } }
            }
        }
    }

    private var initials: String {
        let name = auth.currentUser?.displayName ?? auth.currentUser?.email ?? "?"
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Supporting views

private struct StatCell: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold()).foregroundStyle(.white)
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}
