import SwiftUI

struct AuthTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var contentType: UITextContentType? = nil
    var isSecure: Bool = false
    var hasError: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(hasError ? .red : .white.opacity(0.5))
                .frame(width: 20)

            if isSecure {
                SecureField(title, text: $text)
                    .textContentType(contentType)
                    .foregroundStyle(.white)
            } else {
                TextField(title, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(contentType)
                    .foregroundStyle(.white)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(hasError ? Color.red.opacity(0.6) : Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}
