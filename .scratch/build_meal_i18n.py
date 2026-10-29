# -*- coding: utf-8 -*-
"""Build EN lunch and JA lunch/evening encouragement files from the Korean decks."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAP = json.loads((Path(__file__).with_name("meal_i18n_map.json")).read_text(encoding="utf-8"))

PREFIX = {
    "lunch": (
        "오늘의 점심 미션: ",
        "Today's lunch note: ",
        "今日のランチ：",
    ),
    "evening": (
        "오늘의 작은 알림: ",
        "A little reminder: ",
        "今夜のメモ：",
    ),
}


def split_parts(text):
    return [p.strip() for p in re.split(r"(?<=[.!])\s+", text) if p.strip()]


def ending(part):
    if part.endswith("!"):
        return "!"
    if part.endswith("."):
        return "."
    return ""


def translate_part(part, kind, lang_index):
    end = ending(part)
    text = part.rstrip(".!").strip()
    prefix_ko, prefix_en, prefix_ja = PREFIX[kind]
    prefix = ""
    if text.startswith(prefix_ko):
        text = text[len(prefix_ko) :]
        prefix = (prefix_en, prefix_ja)[lang_index]
    pair = MAP[kind]["parts"].get(text)
    if pair is None:
        raise KeyError(text)
    return prefix + pair[lang_index] + end


def japanese_punctuation(text):
    text = text.replace("!", "！")
    text = text.replace(". ", "。")
    if text.endswith("."):
        text = text[:-1] + "。"
    return text


def translate_body(body, kind, lang_index):
    text = " ".join(translate_part(part, kind, lang_index) for part in split_parts(body))
    return japanese_punctuation(text) if lang_index == 1 else text


def translate_title(title, kind, lang_index):
    pair = MAP[kind]["titles"].get(title)
    if pair is None:
        raise KeyError(title)
    text = pair[lang_index]
    return japanese_punctuation(text) if lang_index == 1 else text


def build(kind, src_name, outputs):
    src = json.loads((ROOT / "assets" / "quotes" / "ko" / src_name).read_text(encoding="utf-8"))
    built = {}
    for lang_index, rel in outputs:
        rows = []
        for item in src:
            rows.append(
                {
                    "day": item["day"],
                    "title": translate_title(item["title"], kind, lang_index),
                    "body": translate_body(item["body"], kind, lang_index),
                }
            )
        path = ROOT / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(rows, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        built[rel] = len(rows)
    return built


if __name__ == "__main__":
    print(
        build(
            "lunch",
            "lunch_encouragement_fcm_365_ko.json",
            [
                (0, "assets/quotes/en/lunch_encouragement_fcm_365_en.json"),
                (1, "assets/quotes/ja/lunch_encouragement_fcm_365_ja.json"),
            ],
        )
    )
    print(
        build(
            "evening",
            "evening_encouragement_fcm_365_ko.json",
            [
                (1, "assets/quotes/ja/evening_encouragement_fcm_365_ja.json"),
            ],
        )
    )
