# Kamilunavo Trace — Product Spec v0.3

## Identity

Public release name: **Kamilunavo Trace**

Historical internal names:
- `ProofVault` — retired
- `Evidaro` — retired as public brand; may remain in internal project paths, migration keys and deterministic CI fixtures

Release identifiers:
- Bundle ID: `de.kamilunavo.trace`
- Lifetime Pro product: `de.kamilunavo.trace.pro.lifetime`
- iPhone / iOS 17+

Public-name web/App Store research reduces obvious collision risk but is not legal trademark clearance.

## Problem

People often need to prove what happened after the moment has passed: a damaged delivery, apartment handover, contractor defect, insurance incident, vehicle condition, administrative exchange or other dispute. Photos, notes, screenshots and documents end up scattered across apps with no coherent timeline or integrity trail.

Kamilunavo Trace turns one real-world situation into one structured evidence case.

## Product promise

> Capture facts while they are fresh. Trace integrity later.

Keep original context reachable, create repeatable integrity snapshots, export a readable evidence pack and let another person verify a portable evidence bundle without a Kamilunavo server.

## Differentiation

Kamilunavo Trace is deliberately not:
- a generic cloud document vault
- a receipt/return tracker
- a legal-advice product
- a notary service
- a blockchain gimmick

The differentiator is the **verifiable original chain**:

**original bytes -> original SHA-256 -> evidence-record SHA-256 -> snapshot seals -> derived OCR -> localized PDF + offline-verifiable `.evpack`**

## Core users

- renters / landlords documenting handovers and defects
- homeowners dealing with contractors or service providers
- consumers documenting damaged/incomplete deliveries
- drivers documenting vehicle condition/incidents
- people preparing insurance claims
- people documenting workplace or administrative events

## Core loop

**Create case -> Capture evidence -> Hash -> Review timeline -> Seal snapshot -> Export/share -> Verify received bundle locally**

A seal records a snapshot at that moment. Later evidence may be added and sealed again; prior seal values remain visible.

## Evidence model

### Evidence Case
- id
- title
- stable raw case type
- created timestamp
- evidence items
- seal history

### Evidence Item
- id
- stable raw evidence type
- recorded timestamp
- source/context
- factual user note
- evidence-record SHA-256
- private original media reference where applicable
- original-media SHA-256 where applicable
- optional derived OCR text/provenance

### Evidence Seal
- id
- created timestamp
- item count
- manifest SHA-256

## Intake

- factual note/observation
- source/context
- direct iPhone camera photo
- PhotosPicker image
- Files/PDF import

Original captured/imported bytes are copied into app-private storage and hashed before becoming part of the evidence record.

## Integrity model

### Original media
SHA-256 is computed over stored original bytes. OCR never replaces or rewrites the original.

### Evidence record
The record hash covers stable canonical factual fields plus the original-media hash where present. Derived OCR is excluded.

### Snapshot seal
The seal hashes a canonical manifest containing stable case identity plus ordered evidence identities/hashes/original-media hashes.

### OCR
Apple Vision runs locally. OCR is derived metadata, is visibly labelled, may be refreshed and must not rewrite original-media SHA-256, record SHA-256 or existing seals.

## PDF evidence pack

The localized PDF includes:
- Kamilunavo Trace branding
- case identity/timeline
- full original-media and record SHA-256 values
- clearly labelled derived OCR
- image/PDF previews rendered from verified originals
- snapshot-seal history
- integrity/legal boundary

Before export, stored originals and record hashes are rechecked. The PDF is a derived presentation, not the source of truth.

## Offline `.evpack`

`.evpack` v1 is a deterministic JSON-based portable format. The historical format identifier `de.kamilunavo.evidaro.evpack` remains stable for v1 compatibility even though the public app is now Kamilunavo Trace.

It carries stable factual fields, original media bytes as Base64, recorded media/record hashes, seal history and derived OCR metadata.

The local verifier:
- rejects unsupported format/version
- re-hashes embedded original bytes
- recomputes evidence-record hashes
- verifies historical seals against the represented evidence prefix
- reports current manifest SHA-256 and bundle SHA-256
- reports concrete integrity issues
- does not silently import received evidence into canonical app data

Changing factual evidence without matching integrity anchors must fail verification. Changing only derived OCR must not invalidate original integrity.

## Privacy

v1 is local-first:
- no account required
- no evidence sent to Kamilunavo servers
- no cloud OCR
- received `.evpack` verification requires no network
- no analytics/ads in the evidence core
- optional future sync must be opt-in and separately threat-modelled

Privacy Lock uses device-owner authentication and is independent of evidence hashes/source bytes.

## Trust / legal boundary

Kamilunavo Trace is a record-keeping and integrity-verification tool, not a law firm, not a notary and not a legal-admissibility service. Hashes and portable-bundle verification can help detect changes that no longer match recorded internal anchors, but do not independently prove when a real-world event occurred, who authored an original, or guarantee acceptance by a court, insurer, employer or authority.

A self-contained unsigned v1 `.evpack` is not an external trust anchor: a party capable of deliberately rewriting content and recomputing all self-contained anchors is outside what this format alone can independently disprove.

## Free / Lifetime Pro

### Free
- up to **3 cases**
- notes/photos/files/camera capture
- original-media SHA-256
- evidence-record SHA-256
- snapshot seals
- local OCR
- original sharing
- text manifest sharing
- Privacy Lock
- **verify received `.evpack` bundles for free**

### Kamilunavo Trace Pro — Lifetime
- unlimited cases
- unlimited verified PDF evidence-pack exports
- unlimited `.evpack` verification-bundle exports
- one-time purchase; no subscription

Launch-price direction: **14.99 EUR** in the German storefront, with Apple storefront pricing applied elsewhere.

Core integrity checks are not the paid product. Pro sells scale and rich export capability.

## StoreKit boundary

StoreKit 2 entitlement rules:
- verified transactions only
- `Transaction.currentEntitlements` is authoritative for recovered Pro access
- `Transaction.updates` handles live updates
- `Transaction.unfinished` handles interrupted-purchase recovery
- `AppStore.sync()` is used only for explicit Restore Purchases
- the local `.storekit` configuration is test data, not evidence that the real App Store Connect IAP exists

## Release boundary

Automated gates cover source wiring, simulator build, persistence, SHA integrity, OCR, DE/EN PDFs, `.evpack` tamper/derived-OCR behavior, Privacy Lock lifecycle and localization.

A public release still requires the signed TestFlight physical gate in `PHYSICAL_QA.md`, especially:
- real camera/permission UX
- real iPhone OCR
- Face ID/Touch ID/passcode
- DE/EN visual review
- VoiceOver + largest Dynamic Type
- real TestFlight Lifetime purchase/relaunch/restore
- PDF and `.evpack` round trip

Canonical Apple setup/runbook: `APP_STORE_CONNECT_RELEASE.md`.
