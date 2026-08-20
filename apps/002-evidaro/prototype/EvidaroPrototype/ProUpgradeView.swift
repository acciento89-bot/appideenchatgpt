import SwiftUI

struct ProUpgradeView: View {
    @ObservedObject var entitlement: EntitlementStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "point.3.connected.trianglepath.dotted")
                            .font(.system(size: 42, weight: .semibold))
                            .accessibilityHidden(true)
                        Text("pro.title")
                            .font(.largeTitle.bold())
                        Text("pro.subtitle")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        ProFeatureRow(symbol: "folder.badge.plus", key: "pro.feature_cases")
                        ProFeatureRow(symbol: "doc.richtext", key: "pro.feature_pdf")
                        ProFeatureRow(symbol: "checkmark.shield", key: "pro.feature_bundle")
                        ProFeatureRow(symbol: "arrow.trianglehead.2.clockwise.rotate.90", key: "pro.feature_once")
                    }

                    if entitlement.isPro {
                        Label("pro.active", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    } else {
                        Button {
                            Task { await entitlement.purchaseLifetime() }
                        } label: {
                            HStack {
                                if entitlement.isLoading {
                                    ProgressView()
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("pro.buy_lifetime")
                                        .font(.headline)
                                    Text(entitlement.displayPrice)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title2)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(entitlement.isLoading)

                        Button("pro.restore") {
                            Task { await entitlement.restorePurchases() }
                        }
                        .frame(maxWidth: .infinity)
                        .disabled(entitlement.isLoading)
                    }

                    if let message = entitlement.lastErrorMessage, !message.isEmpty {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Text("pro.trust_boundary")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(22)
            }
            .navigationTitle("pro.navigation")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { dismiss() }
                }
            }
            .task { await entitlement.load() }
        }
    }
}

private struct ProFeatureRow: View {
    let symbol: String
    let key: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .frame(width: 28)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(key)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
