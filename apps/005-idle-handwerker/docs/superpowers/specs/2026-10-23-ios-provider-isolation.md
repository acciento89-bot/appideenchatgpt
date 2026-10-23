# iOS device acceptance boundary

The authorized published update is iOS1.4.0(19), Android3 unchanged. Existing staff-dispatch gameplay, economy, saves, products and production advertising remain intact. The human excludes all real purchase, restore, redemption and rewarded-ad transactions. Native QA therefore requires an explicit development-only provider-disabled launch option before any StoreKit/UMP/ad initialization, polling, purchase/restore or reward grant. It must neither grant nor clear entitlements. Shipping Release ignores the option.

Approaches considered by implementer under existing autonomous authorization: existing screenshot flag is insufficient because StoreKit still starts; removing plugins changes shipping architecture; use a narrowly guarded explicit debug launch option on the existing MonetizationBridge. Choose the last. A pure policy accepts debug-build status plus argument list; production gets these from Godot OS. Cover actual bridge behavior with fake external StoreKit only. No real financial providers during tests.

Native runtime acceptance, scene/export compatibility, own production iOS ad configuration and actual Duo layouts remain separate gates. Never erase the sole retained Duo.
