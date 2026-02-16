import json
import os
import sys
import zipfile


def inspect_ppa(path: str) -> None:
    print(f"=== {path}")
    if not os.path.exists(path):
        print("MISSING")
        return

    try:
        with zipfile.ZipFile(path, "r") as zf:
            print("Zip entries:")
            for name in zf.namelist():
                print(f"  {name}")

            for name in ("meta.json", "ppa.json"):
                try:
                    data = zf.read(name)
                except KeyError:
                    print(f"{name}: MISSING in archive")
                    continue

                print(f"{name}: {len(data)} bytes")

                try:
                    text = data.decode("utf-8")
                except UnicodeDecodeError as exc:
                    print(f"{name}: UTF-8 decode error: {exc}")
                    continue

                print(f"{name}: first 300 chars:")
                print(text[:300].replace("\n", " ") + "\n")

                try:
                    obj = json.loads(text)
                except Exception as exc:  # noqa: BLE001 - debugging script
                    print(f"{name}: JSON parse error: {exc}")
                else:
                    keys = list(obj) if isinstance(obj, dict) else []
                    print(f"{name}: JSON parsed OK; top-level keys: {keys[:20]}")

    except zipfile.BadZipFile as exc:
        print(f"Bad ZIP/.ppa file: {exc}")

    print()


def main(argv: list[str]) -> int:
    if not argv:
        print("Usage: inspect_ppa_tmp.py <file1.ppa> [<file2.ppa> ...]")
        return 1

    for path in argv:
        inspect_ppa(path)

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

