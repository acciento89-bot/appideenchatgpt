# Pass 8 final gate

This file records the dependency-aligned CI boundary for the offline-verifiable `.evpack` pass.

- Pass 7 final head: `84ef850678551e7cb0f22004c05e070adabece9d`
- Pass 7 verified workflow: `32383741929` — SUCCESS
- Pass 7 merge on `main`: `bf3ecf74887c08d52bbadf11a13174c83133b093`
- Pass 8 branch sync merge: `5ec036f849de4dc7a63ef6d9acd82e7d493bc268`
- Required Pass 8 gate: preflight + Xcode Simulator build + persistence + OCR + EN/DE PDF relaunch + `.evpack` valid/tamper/derived-OCR/relaunch + privacy lock + German localization.

Do not mark Pass 8 green or merge PR #32 until the workflow on the exact final branch head succeeds.
