# Evidaro — Product Spec v0.1

## Problem

People often need to prove what happened after the moment has passed: a damaged delivery, apartment handover, contractor defect, insurance incident, vehicle condition, administrative exchange or other dispute. Photos, notes, screenshots and documents end up scattered across apps with no coherent timeline or integrity trail.

Evidaro turns one real-world situation into one structured evidence case.

## Product promise

Capture facts while they are fresh, keep the original context reachable, and create a verifiable snapshot you can export later.

## Differentiation

Evidaro is deliberately not:
- a generic cloud document vault
- a receipt tracker
- a return-window tracker
- a legal-advice product
- a blockchain/notary gimmick

The differentiator is the **case timeline + per-item hash + repeatable sealed manifest**.

## Core users

- renters / landlords documenting handovers and defects
- homeowners dealing with contractors or service providers
- consumers documenting damaged or incomplete deliveries
- drivers documenting vehicle condition or incidents
- people preparing insurance claims
- anyone who needs a factual timeline before a complaint/escalation

## Core entities

### Evidence Case
- id
- title
- case type
- created timestamp
- status
- evidence items
- seals

### Evidence Item
- id
- type
- captured/recorded timestamp
- source/context label
- user note/description
- content hash
- later: media/file reference + original-file hash

### Evidence Seal
- id
- created timestamp
- item count
- manifest hash

## MVP UX

### Home
- concise explanation of purpose
- open-case count
- total evidence count
- latest seal count
- list of cases with type, evidence count and last activity
- primary `New Case` action

### New Case
- title
- type
- save

### Case Detail
- timeline header
- evidence list with type, timestamp, source, note and shortened hash
- add evidence
- seal snapshot
- latest seal history
- share current manifest

### Add Evidence
Foundation pass supports:
- note/observation
- source/context label
- evidence type

Next pass adds:
- camera/photo
- existing photo
- Files/PDF

## Integrity model

### Item hash
For the foundation build, the hash covers canonical text metadata for the item. Media intake will extend this to hash original file bytes plus canonical metadata.

### Seal hash
The seal hashes a canonical manifest containing stable case identity plus ordered evidence-item identity/hash pairs.

### Seal semantics
- sealing does not lock the whole case forever
- a seal records a snapshot at that moment
- later evidence can be added
- a new seal represents the newer snapshot
- prior seal hashes remain visible

This avoids pretending the app can stop a user from creating later information while still preserving evidence of what a previous snapshot contained.

## Privacy

v1 is local-first.
- no account required
- no evidence sent to Kamilunavo servers
- no analytics/ads in the evidence core
- later optional sync must be opt-in and separately threat-modeled

## Safety / legal positioning

Evidaro is a record-keeping tool, not a law firm, not a notary and not a legal-admissibility service. Hashes can help detect later changes to captured content but do not independently prove when a real-world event occurred or guarantee acceptance by a court, insurer, employer or authority.

## Platform

Foundation:
- iPhone
- iOS 17+
- SwiftUI
- CryptoKit SHA-256

Next technical layer:
- SwiftData
- PhotosUI / camera capture
- file importer
- PDFKit / UIGraphicsPDFRenderer for export
- Vision for OCR where useful
- LocalAuthentication for optional privacy lock

## Monetization

Planned: Freemium + Pro.

Current direction:
- free tier should be genuinely useful
- likely case-count/export limits, not crippled capture
- prefer Lifetime Pro while product remains local-first
- only consider subscription if recurring hosted costs become a real product dependency

No final price is locked in this spec.