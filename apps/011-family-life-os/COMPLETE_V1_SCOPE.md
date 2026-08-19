# Family Life OS — Complete v1 integration scope

Status: IN IMPLEMENTATION
Branch: `agent/family-life-os-complete-v1`

This pass turns the current hosted prototype into the complete product v1 defined by `PRODUCT_SPEC.md` and `UX_SCREEN_SPEC.md`, excluding only explicit non-goals.

## Included

- hosted auth + invite acceptance
- household/member management
- realtime refresh of shared state
- photo/camera/screenshot capture
- PDF/document capture
- direct/pasted text capture
- voice recording + transcription
- private Storage source files
- OCR for image/PDF text recovery
- server-side structured extraction with deterministic no-secret fallback
- review-before-confirmation trust boundary
- source provenance / original source viewer
- retry + archive source lifecycle
- agenda + week Plan
- manual plan create/edit/delete
- completion persistence
- optimistic conflict/version protection
- activity history foundation
- notification preferences + local reminder scheduling
- app lock with device biometrics
- StoreKit 2 Family Pro surface + restore
- offline snapshot cache foundation
- share-extension target/source intake
- release/privacy permission descriptions
- internal TestFlight diagnostics retained only for internal testing

## Explicit non-goals retained

- family chat/social network
- live GPS
- calling/video
- bank/budget integration
- meal/recipe engine
- automatic mailbox surveillance
- autonomous booking/calling
- medical advice

## Release rule

Do not upload the complete build until iOS compile, device Release build and database migration/test gates are green. Internal TestFlight remains the intended discovery environment for runtime/device integration bugs.
