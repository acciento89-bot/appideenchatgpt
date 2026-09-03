import StoreKit
import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var entitlements: EntitlementStore
    @Environment(\.dismiss) private var dismiss
    private let privacyURL = URL(string: "https://kamilunavo.com/privacy")!
    private let standardEULAURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Image(systemName: "doc.text.fill.viewfinder")
                        .font(.system(size: 48))
                        .foregroundStyle(CraftTheme.orange)
                        .frame(width: 104, height: 104)
                        .background(CraftTheme.surface, in: RoundedRectangle(cornerRadius: 28))
                    Text("Rapport AI Pro").font(.largeTitle.bold())
                    Text("Unbegrenzt professionelle Rapporte für deinen Betrieb.").font(.title3).foregroundStyle(CraftTheme.textMuted).multilineTextAlignment(.center)

                    CraftCard {
                        VStack(alignment: .leading, spacing: 13) {
                            benefit("Unbegrenzt KI-Rapporte", icon: "infinity")
                            benefit("Firmenlogo und Kontaktdaten im PDF", icon: "building.2")
                            benefit("Alle Gewerke und Rapport-Stile", icon: "wrench.and.screwdriver")
                            benefit("Rapporte lokal speichern und teilen", icon: "square.and.arrow.up")
                        }
                    }

                    if entitlements.isPro {
                        Label("Pro ist aktiv", systemImage: "checkmark.seal.fill").font(.headline).foregroundStyle(CraftTheme.cyan)
                    } else if entitlements.products.isEmpty && entitlements.isLoading {
                        ProgressView("Angebote werden geladen …")
                    } else {
                        ForEach(entitlements.products, id: \.id) { product in
                            Button {
                                Task { await entitlements.purchase(product) }
                            } label: {
                                HStack(spacing: 14) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(product.displayName)
                                            .font(.headline)
                                            .multilineTextAlignment(.leading)
                                            .lineLimit(2)
                                        if let period = product.subscription?.subscriptionPeriod {
                                            Text(period.unit == .year ? "Jährlich kündbar" : "Monatlich kündbar").font(.caption)
                                        }
                                    }
                                    Spacer()
                                    Text(product.displayPrice)
                                        .font(.headline)
                                        .fixedSize(horizontal: true, vertical: false)
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(entitlements.isLoading)
                        }
                    }

                    Button("Käufe wiederherstellen") { Task { await entitlements.restore() } }
                        .buttonStyle(.bordered)
                        .tint(CraftTheme.cyan)
                    Text("Abonnements verlängern sich automatisch, sofern sie nicht mindestens 24 Stunden vor Ablauf gekündigt werden. Verwaltung über deine Apple-ID.")
                        .font(.caption2).foregroundStyle(CraftTheme.textMuted).multilineTextAlignment(.center)
                    HStack(spacing: 18) {
                        Link("Datenschutz", destination: privacyURL)
                        Link("Nutzungsbedingungen", destination: standardEULAURL)
                    }
                    .font(.caption)
                    .foregroundStyle(CraftTheme.cyan)
                }
                .padding(20)
            }
            .background(CraftTheme.background.ignoresSafeArea())
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Schließen") { dismiss() } } }
            .alert("StoreKit", isPresented: Binding(get: { entitlements.errorMessage != nil }, set: { if !$0 { entitlements.errorMessage = nil } })) {
                Button("OK", role: .cancel) { entitlements.errorMessage = nil }
            } message: { Text(entitlements.errorMessage ?? "") }
        }
    }

    private func benefit(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon).foregroundStyle(.white)
    }
}
