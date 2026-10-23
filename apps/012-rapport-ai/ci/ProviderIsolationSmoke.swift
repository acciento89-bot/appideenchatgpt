import Foundation
import StoreKit
@main struct ProviderIsolationSmoke {
 @MainActor static func main() async {
  let store = EntitlementStore()
  try? await Task.sleep(nanoseconds: 30_000_000)
  await store.loadProducts()
  await store.refreshEntitlements()
  await store.purchase(Product())
  await store.restore()
  if ProcessInfo.processInfo.environment["EXPECT_PROVIDER_CALLS"] == "1" {
   precondition(!ProviderProbe.calls.isEmpty, "Normal and Release launches must retain provider behavior")
   print("PASS normal/Release provider behavior with synthetic provider")
   return
  }
  precondition(ProviderProbe.calls.isEmpty, "Unexpected provider calls: \(ProviderProbe.calls)")
  precondition(!store.isPro && !store.isLoading && store.products.isEmpty)
  print("PASS zero provider calls on explicitly isolated native QA launch")
 }
}
