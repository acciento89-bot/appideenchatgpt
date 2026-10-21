#!/usr/bin/env python3
"""Write deterministic synthetic .evpack fixtures; never reads customer data.

Canonical strings mirror the existing v1 verifier format. Run the Swift fixture
check or import into the app to establish actual verifier acceptance.
"""
import hashlib
import json
import pathlib
import sys


def sha(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def item(identity, note, time):
    result = {
        "id": identity, "kindRawValue": "Observation", "recordedAtCanonical": time,
        "source": "Synthetic on-device QA", "note": note,
    }
    result["contentHash"] = sha("\n".join([
        "kind=Observation", "recordedAt=" + time, "source=" + result["source"],
        "note=" + note, "mediaHash=none",
    ]))
    return result


def packet(items, exported):
    return {
        "format": "de.kamilunavo.trace.evpack", "version": 1,
        "exportedAtCanonical": exported,
        "caseID": "11111111-1111-4111-8111-111111111111",
        "title": "Trace synthetic comparison QA", "kindRawValue": "Property",
        "createdAtCanonical": "50.0", "items": items, "seals": [],
    }


def seal(document, identity, time):
    lines = ["caseID=" + document["caseID"], "title=" + document["title"],
             "kind=" + document["kindRawValue"], "createdAt=" + document["createdAtCanonical"]]
    lines.extend("item=" + i["id"] + "|" + i["recordedAtCanonical"] + "|" + i["contentHash"] + "|none"
                 for i in document["items"])
    return {"id": identity, "createdAtCanonical": time, "itemCount": len(document["items"]),
            "manifestHash": sha("\n".join(lines))}


def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: generate-native-fixtures.py OUTPUT_DIRECTORY")
    output = pathlib.Path(sys.argv[1]); output.mkdir(parents=True, exist_ok=True)
    first = "22222222-2222-4222-8222-222222222222"
    baseline = packet([item(first, "Baseline synthetic observation", "100.0")], "200.0")
    baseline["seals"] = [seal(baseline, "55555555-5555-4555-8555-555555555555", "150.0")]
    candidate = packet([item(first, "Candidate synthetic corrected observation", "100.0"),
                        item("33333333-3333-4333-8333-333333333333", "Synthetic added observation", "101.0")], "300.0")
    candidate["items"][0].update({"recognizedText": "Synthetic derived OCR", "recognizedTextAtCanonical": "210.0",
                                   "recognizedTextEngine": "Synthetic QA", "recognizedTextPageCount": 1})
    candidate["seals"] = [seal(candidate, "66666666-6666-4666-8666-666666666666", "250.0")]
    manifest = {"syntheticOnly": True, "actualAppVerifierAcceptance": "PENDING Swift fixture check/native import",
                "expected": {"baselineItems": 1, "candidateItems": 2, "added": 1, "removed": 0,
                             "modifiedOriginalRecords": 1, "metadataOnlyRecords": 0, "unchanged": 0,
                             "addedSeals": 1, "removedSeals": 1}, "files": {}}
    for name, document in [("Trace-QA-Baseline.evpack", baseline), ("Trace-QA-Candidate.evpack", candidate)]:
        data = (json.dumps(document, ensure_ascii=False, sort_keys=True, indent=2) + "\n").encode("utf-8")
        (output/name).write_bytes(data)
        manifest["files"][name] = {"sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data),
                                   "manifestSHA256": document["seals"][0]["manifestHash"]}
    (output/"fixtures.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("Wrote two synthetic Trace packets and expected results to", output)


if __name__ == "__main__":
    main()
