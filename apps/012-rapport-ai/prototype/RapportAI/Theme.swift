import SwiftUI

enum CraftTheme {
    static let background = Color(red: 0.025, green: 0.075, blue: 0.11)
    static let surface = Color(red: 0.045, green: 0.16, blue: 0.23)
    static let surfaceRaised = Color(red: 0.06, green: 0.23, blue: 0.33)
    static let cyan = Color(red: 0.12, green: 0.72, blue: 0.92)
    static let orange = Color(red: 1.0, green: 0.52, blue: 0.08)
    static let textMuted = Color(red: 0.68, green: 0.78, blue: 0.83)
}

struct CraftCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(CraftTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(CraftTheme.cyan.opacity(0.35), lineWidth: 1)
                    )
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [CraftTheme.orange, CraftTheme.orange.opacity(0.78)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
    }
}
