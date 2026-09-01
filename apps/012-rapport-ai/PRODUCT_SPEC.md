# Rapport AI — MVP Product Spec

Status: working title / implementation started

## Product promise

Turn a rough German tradesperson voice note into a clear, professional work report in under one minute.

## Core loop

1. Select the trade and enter customer, location and object/system.
2. Dictate or type what happened on site.
3. Generate a factual professional report.
4. Review and edit every word.
5. Save locally or share as PDF.

## MVP guardrails

- The app never invents measurements, materials, faults or completed work.
- Generated text is always editable and must be reviewed by the technician.
- Reports are stored locally on the device.
- Speech recognition uses Apple's on-device/system speech APIs where available.
- AI calls go through a server-side endpoint; no OpenAI key ships in the app.

## Initial monetization

- Free: 5 AI reports per month, unlimited manual drafts.
- Pro: unlimited AI reports, company logo/templates and PDF branding options.
- Product and pricing are not locked until real device and willingness-to-pay tests.
