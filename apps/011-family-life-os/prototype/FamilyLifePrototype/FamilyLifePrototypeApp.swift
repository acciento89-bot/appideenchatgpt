import SwiftUI

@main
struct FamilyLifePrototypeApp: App {
    var body: some Scene {
        WindowGroup {
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-familyProReviewScreenshot") {
                FamilyProReviewScreenshotView()
            } else {
                HostedCompleteV1View()
            }
#else
            HostedCompleteV1View()
#endif
        }
    }
}

#if DEBUG
private struct FamilyProReviewScreenshotView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Family Pro", systemImage: "sparkles")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.indigo)
                        Text("Mehr KI-Importe, Automationen, Speicher und Verlauf für die ganze Familie.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        ReviewFeature(icon: "wand.and.stars", text: "Mehr KI-gestützte Importe")
                        ReviewFeature(icon: "bolt.badge.clock", text: "Erweiterte Familien-Automationen")
                        ReviewFeature(icon: "externaldrive", text: "Zusätzlicher Speicher")
                        ReviewFeature(icon: "clock.arrow.circlepath", text: "Erweiterter Verlauf")
                    }
                    .padding(18)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 18))

                    VStack(spacing: 12) {
                        ReviewPlanCard(
                            title: "Family Pro Monatlich",
                            subtitle: "Monatliche Abrechnung über Apple",
                            badge: nil
                        )
                        ReviewPlanCard(
                            title: "Family Pro Jährlich",
                            subtitle: "Jährliche Abrechnung über Apple",
                            badge: "Jahresabo"
                        )
                    }

                    Button("Käufe wiederherstellen") {}
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Family Pro ist ein automatisch verlängerndes Abonnement. Kauf, Abrechnung, Verlängerung und Kündigung werden über Apple abgewickelt.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 18) {
                            Text("Datenschutz")
                            Text("Nutzungsbedingungen")
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.indigo)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct ReviewFeature: View {
    let icon: String
    let text: String

    var body: some View {
        Label(text, systemImage: icon)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ReviewPlanCard: View {
    let title: String
    let subtitle: String
    let badge: String?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(.indigo)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                    if let badge {
                        Text(badge)
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.indigo.opacity(0.12), in: Capsule())
                            .foregroundStyle(.indigo)
                    }
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.quaternary, lineWidth: 1)
        }
    }
}
#endif
