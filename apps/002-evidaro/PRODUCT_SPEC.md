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
- evidence items
- seals

### Evidence Item
- id
- type
- captured/recorded timestamp
- source/context label
- user note/description
- evidence-record SHA-256
- private original media/file reference where applicable
- original-file SHA-256 where applicable
- optional derived OCR text, recognition timestamp, engine and page count

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
- evidence list with type, timestamp, source, note and record hash
- original media filename + original-media SHA-256 where applicable
- local `Recognize` / `Refresh` text action for images and PDFs
- user-visible derived OCR result/provenance
- add evidence
- seal snapshot
- seal history
- share current integrity manifest

### Add Evidence
Current capture/import layer supports:
- note/observation
- source/context label
- evidence type
- direct camera photo on camera-capable iPhones
- existing photo through PhotosPicker
- Files/PDF import

Original imported/captured bytes are copied into app-private storage and hashed before they become part of the evidence record.

## Integrity model

### Original-media hash
For media-backed evidence, Evidaro computes SHA-256 over the stored original byte stream. OCR never replaces or rewrites these bytes.

### Evidence-record hash
The evidence-record hash covers stable canonical item metadata plus the original-media hash where one exists. Derived OCR output is intentionally excluded so recognition can be refreshed without rewriting the evidence identity.

### Seal hash
The seal hashes a canonical manifest containing stable case identity plus ordered evidence-item identity/hash pairs and original-media hashes.

### Seal semantics
- sealing does not lock the whole case forever
- a seal records a snapshot at that moment
- later evidence can be added
- a new seal represents the newer snapshot
- prior seal hashes remain visible
- derived OCR can be added/refreshed without changing an already-created seal

This avoids pretending the app can stop a user from creating later information while still preserving evidence of what a previous snapshot contained.

## Derived OCR model

Evidaro uses Apple Vision locally for supported images and PDFs.

Rules:
- OCR is derived metadata, never the source of truth
- before recognition, stored original bytes must still match their saved SHA-256
- recognition runs locally; no cloud OCR/upload is required
- recognized text, recognition time, engine and page count are stored separately
- OCR is excluded from original-media SHA-256, evidence-record SHA-256 and snapshot seals
- refreshing OCR cannot silently rewrite an existing sealed evidence snapshot
- the UI identifies OCR as derived text and keeps the original media reachable

## Privacy

v1 is local-first.
- no account required
- no evidence sent to Kamilunavo servers
- no cloud OCR required
- no analytics/ads in the evidence core
- later optional sync must be opt-in and separately threat-modeled

## Safety / legal positioning

Evidaro is a record-keeping tool, not a law firm, not a notary and not a legal-admissibility service. Hashes can help detect later changes to captured content but do not independently prove when a real-world event occurred or guarantee acceptance by a court, insurer, employer or authority.

## Platform

Current technical foundation:
- iPhone
- iOS 17+
- SwiftUI
- SwiftData
- CryptoKit SHA-256
- PhotosUI
- camera capture
- file importer
- PDFKit
- Apple Vision OCR

Next technical layer:
- PDFKit / UIGraphicsPDFRenderer evidence-pack export
- optional location/context metadata
- LocalAuthentication for optional privacy lock
- DE/EN + accessibility hardening

## Monetization

Planned: Freemium + Pro.

Current direction:
- free tier should be genuinely useful
- likely case-count/export limits, not crippled capture
- prefer Lifetime Pro while product remains local-first
- only consider subscription if recurring hosted costs become a real product dependency

No final price is locked in this spec.
