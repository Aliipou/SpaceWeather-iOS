import SwiftUI

struct AuthGateView: View {
    @EnvironmentObject private var auth: AuthService
    @State private var showRegister = false

    var body: some View {
        if auth.isAuthenticated {
            ContentView()
        } else if showRegister {
            RegisterView(onLogin: { showRegister = false })
        } else {
            LoginView(onRegister: { showRegister = true })
        }
    }
}
