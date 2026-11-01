#!/usr/bin/env python3
"""Word-timing verifier: transcribes the app-pipeline audio with whisper WORD
TIMESTAMPS and aligns the heard words against the app's own word schedule
(manifest.json written by tool/word_timing_verify.dart) to measure ACTUAL
per-word drift — max/mean per chapter, both languages, in milliseconds.

Uses openai-whisper with word_timestamps=True (the round-2 task's working
whisper setup; models cached in ~/.cache/whisper). faster-whisper is the
same capability but its package/models cannot be fetched from this host
(PyPI/HF blocked), so the cached openai-whisper word-timestamp path is used.

Alignment: both word sequences derive from the same spoken text, so a
monotonic difflib alignment pairs them; unmatched words (whisper merges or
drops) are excluded from the stats and reported separately.

Usage: python3 tool/word_timing_whisper.py <outDir>
"""
import difflib
import json
import os
import re
import sys

import whisper

_KEEP = "a-z0-9áéíóúüñ'"


def norm(word):
    txt = word.lower()
    txt = re.sub(r"[^" + _KEEP + r"]", "", txt)
    return txt.strip("'")


_models = {}


def get_model(lang):
    # Round-2 choices: medium.en for English, small for Spanish (cached).
    size = "medium.en" if lang == "en" else "small"
    if size not in _models:
        _models[size] = whisper.load_model(size)
    return _models[size]


def transcribe_words(model, wav_path, lang):
    kw = dict(temperature=0.0, condition_on_previous_text=False,
              word_timestamps=True)
    if lang == "es":
        kw["language"] = "es"
    if model.device.type == "cpu":
        kw["fp16"] = False
    result = model.transcribe(wav_path, **kw)
    words = []
    for seg in result.get("segments", []):
        for w in seg.get("words", []):
            token = w["word"].strip()
            if token:
                words.append((token, w["start"] * 1000.0, w["end"] * 1000.0))
    return words


def align(app_words, heard_words):
    """Pairs app-schedule words with heard words in order.

    app_words: [{word, startMs, endMs}]; heard_words: [(token, startMs, endMs)].
    Returns (pairs, unmatched_app, unmatched_heard) where pairs are
    (app_word, heard_word, start_dev_ms, midpoint_dev_ms).
    """
    a_norm = [norm(w["word"]) for w in app_words]
    h_norm = [norm(w[0]) for w in heard_words]
    sm = difflib.SequenceMatcher(None, a_norm, h_norm, autojunk=False)
    pairs, unmatched_app, unmatched_heard = [], [], []
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal" or tag == "replace":
            for k in range(min(i2 - i1, j2 - j1)):
                a, h = app_words[i1 + k], heard_words[j1 + k]
                start_dev = h[1] - a["startMs"]
                mid_dev = (h[1] + h[2]) / 2.0 - (a["startMs"] + a["endMs"]) / 2.0
                pairs.append((a, h, start_dev, mid_dev))
            for k in range(min(i2 - i1, j2 - j1), i2 - i1):
                unmatched_app.append(app_words[i1 + k]["word"])
            for k in range(min(i2 - i1, j2 - j1), j2 - j1):
                unmatched_heard.append(heard_words[j1 + k][0])
        elif tag == "delete":
            unmatched_app.extend(app_words[i1 + k]["word"]
                                 for k in range(i2 - i1))
        elif tag == "insert":
            unmatched_heard.extend(heard_words[j1 + k][0]
                                   for k in range(j2 - j1))
    return pairs, unmatched_app, unmatched_heard


def stats(values):
    if not values:
        return {"max": None, "mean": None, "p95": None}
    sv = sorted(abs(v) for v in values)
    p95 = sv[min(len(sv) - 1, int(len(sv) * 0.95))]
    return {
        "max": round(max(sv), 1),
        "mean": round(sum(sv) / len(sv), 1),
        "p95": round(p95, 1),
    }


def quartile_trend(pairs):
    """Sustained-drift view: mean deviation of the last quartile of matched
    words minus the first quartile — a growing schedule shows up here, while
    isolated whisper boundary jitter does not."""
    if len(pairs) < 8:
        return None
    q = len(pairs) // 4
    first = [p[3] for p in pairs[:q]]
    last = [p[3] for p in pairs[-q:]]
    return round(sum(last) / len(last) - sum(first) / len(first), 1)


def main():
    out_dir = sys.argv[1]
    manifest = json.load(open(os.path.join(out_dir, "manifest.json")))
    report = {"tool": "whisper word-timestamp alignment vs app schedule",
              "whisper": "openai-whisper word_timestamps=True "
                         "(medium.en EN / small ES, cached models)",
              "chapters": []}
    for ch in manifest["chapters"]:
        lang, book, chapter = ch["lang"], ch["book"], ch["chapter"]
        model = get_model(lang)
        chunk_reports = []
        all_mid, all_start = [], []
        matched_total, app_total, heard_total = 0, 0, 0
        for chunk in ch["chunks"]:
            heard = transcribe_words(model, chunk["wav"], lang)
            pairs, un_app, un_heard = align(chunk["words"], heard)
            matched_total += len(pairs)
            app_total += len(chunk["words"])
            heard_total += len(heard)
            all_mid.extend(p[3] for p in pairs)
            all_start.extend(p[2] for p in pairs)
            chunk_reports.append({
                "chunk": chunk["index"],
                "verses": f"{chunk['firstVerse']}-{chunk['lastVerse']}",
                "audioMs": chunk["audioMs"],
                "appWords": len(chunk["words"]),
                "heardWords": len(heard),
                "matched": len(pairs),
                "unmatchedApp": un_app,
                "unmatchedHeard": un_heard,
                "midpointDevMs": stats([p[3] for p in pairs]),
                "startDevMs": stats([p[2] for p in pairs]),
                "quartileTrendMs": quartile_trend(pairs),
                "perWord": [
                    {"word": a["word"], "heard": h[0],
                     "appStartMs": round(a["startMs"], 1),
                     "heardStartMs": round(h[1], 1),
                     "startDevMs": round(sd, 1),
                     "midDevMs": round(md, 1)}
                    for a, h, sd, md in pairs
                ],
            })
        entry = {
            "book": book,
            "chapter": chapter,
            "lang": lang,
            "voice": ch["voice"],
            "audioMs": ch["totalAudioMs"],
            "appWords": app_total,
            "heardWords": heard_total,
            "matchedWords": matched_total,
            "matchRate": round(matched_total / max(1, app_total), 3),
            "midpointDevMs": stats(all_mid),
            "startDevMs": stats(all_start),
            "quartileTrendMs": quartile_trend(
                [(None, None, sd, md) for sd, md in
                 zip(all_start, all_mid)]),
            "chunks": chunk_reports,
        }
        report["chapters"].append(entry)
        m, s = entry["midpointDevMs"], entry["startDevMs"]
        print(f"===== {book} {chapter} ({lang}) =====")
        print(f"  audio {ch['totalAudioMs'] / 1000:.1f}s | app words "
              f"{app_total} | heard {heard_total} | matched {matched_total} "
              f"({entry['matchRate'] * 100:.1f}%)")
        print(f"  midpoint dev: max {m['max']}ms mean {m['mean']}ms "
              f"p95 {m['p95']}ms | start dev: max {s['max']}ms "
              f"mean {s['mean']}ms p95 {s['p95']}ms")
        print(f"  sustained-drift trend (last-quartile minus first-quartile "
              f"mean): {entry['quartileTrendMs']}ms")
        for cr in chunk_reports:
            cm, cs = cr["midpointDevMs"], cr["startDevMs"]
            print(f"    chunk {cr['chunk']} (v{cr['verses']}, "
                  f"{cr['audioMs'] / 1000:.1f}s): mid max {cm['max']} mean "
                  f"{cm['mean']} | start max {cs['max']} mean {cs['mean']} | "
                  f"trend {cr['quartileTrendMs']}ms | unmatched app "
                  f"{len(cr['unmatchedApp'])} heard {len(cr['unmatchedHeard'])}")

    out_path = os.path.join(out_dir, "word_timing_report.json")
    with open(out_path, "w") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    print(f"[saved] {out_path}")


if __name__ == "__main__":
    main()