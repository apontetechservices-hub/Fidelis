#!/usr/bin/env python3
"""Transcribes the addendum verification renders with whisper WORD
TIMESTAMPS (the same cached openai-whisper setup as
tool/word_timing_whisper.py) and saves the transcripts + word timings as
JSON — the pronunciations on the record.

Usage: python3 tool/addendum_transcribe.py <rendersDir>
"""
import json
import os
import sys

import whisper


def main():
    renders_dir = sys.argv[1]
    manifest = json.load(open(os.path.join(renders_dir, "manifest.json")))
    model = whisper.load_model("medium.en")
    out = {"tool": "openai-whisper word_timestamps=True (medium.en, cached)",
           "renders": []}
    for r in manifest["renders"]:
        kw = dict(temperature=0.0, condition_on_previous_text=False,
                  word_timestamps=True, fp16=False, language="en")
        result = model.transcribe(r["wav"], **kw)
        words = []
        text_parts = []
        for seg in result.get("segments", []):
            text_parts.append(seg.get("text", "").strip())
            for w in seg.get("words", []):
                token = w["word"].strip()
                if token:
                    words.append({"word": token,
                                  "startMs": round(w["start"] * 1000.0, 1),
                                  "endMs": round(w["end"] * 1000.0, 1),
                                  "durationMs": round(
                                      (w["end"] - w["start"]) * 1000.0, 1)})
        entry = {"wav": r["wav"],
                 "slot": r["slot"],
                 "sourceText": r["text"],
                 "spokenText": r["spokenText"],
                 "transcript": " ".join(text_parts),
                 "words": words,
                 "audioMs": r["audioMs"]}
        out["renders"].append(entry)
        print(f"===== {os.path.basename(r['wav'])} ({r['slot']}) =====")
        print(f"  source : {r['text']}")
        print(f"  spoken : {r['spokenText']}")
        print(f"  heard  : {entry['transcript']}")
        key = [w for w in words if "psalm" in w["word"].lower()
               or "bless" in w["word"].lower()]
        for w in key:
            print(f"    key word: {w['word']} {w['startMs']}-"
                  f"{w['endMs']}ms ({w['durationMs']}ms)")
    out_path = os.path.join(renders_dir, "addendum_transcripts.json")
    with open(out_path, "w") as f:
        json.dump(out, f, indent=2, ensure_ascii=False)
    print(f"[saved] {out_path}")


if __name__ == "__main__":
    main()
