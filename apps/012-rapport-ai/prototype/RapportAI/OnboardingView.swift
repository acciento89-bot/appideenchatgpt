import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var page = 0

    var body: some View {
        ZStack {
            CraftTheme.background.ignoresSafeArea()
            VStack(spacing: 22) {
                TabView(selection: $page) {
                    onboardingPage(icon: "waveform.and.mic", eyebrow: "SCHNELL ERFASST", title: "Sprich wie auf der Baustelle", text: "Diktiere frei oder tippe Stichpunkte. Rapport AI macht daraus einen klaren Arbeitsbericht.").tag(0)
                    onboardingPage(icon: "wrench.and.screwdriver.fill", eyebrow: "FÜR ALLE GEWERKE", title: "Dein Handwerk, dein Rapport", text: "Elektro, SHK, Maler, Tischler, Dach, Bau, Hausmeisterservice und weitere Gewerke.").tag(1)
                    onboardingPage(icon: "checkmark.shield.fill", eyebrow: "DU ENTSCHEIDEST", title: "Prüfen, bearbeiten, teilen", text: "Die KI erfindet keine Fakten. Du kontrollierst den Text, speicherst ihn lokal und teilst ihn als PDF.").tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button(page == 2 ? "Rapport AI starten" : "Weiter") {
                    if page < 2 { withAnimation { page += 1 } } else { isPresented = false }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 22)
            }
            .padding(.vertical, 28)
        }
    }

    private func onboardingPage(icon: String, eyebrow: String, title: String, text: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(CraftTheme.orange)
                .frame(width: 122, height: 122)
                .background(CraftTheme.surface, in: RoundedRectangle(cornerRadius: 32))
                .overlay(RoundedRectangle(cornerRadius: 32).stroke(CraftTheme.cyan.opacity(0.45)))
            Text(eyebrow).font(.caption.bold()).tracking(1.4).foregroundStyle(CraftTheme.cyan)
            Text(title).font(.largeTitle.bold()).multilineTextAlignment(.center)
            Text(text).font(.title3).foregroundStyle(CraftTheme.textMuted).multilineTextAlignment(.center).padding(.horizontal, 30)
            Spacer()
        }
        .foregroundStyle(.white)
    }
}

