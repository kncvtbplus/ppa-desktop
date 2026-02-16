from __future__ import annotations

from pathlib import Path

try:
    from PIL import Image
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "Pillow (PIL) is required. Install it with 'python -m pip install pillow'."
    ) from exc


REPO_ROOT = Path(__file__).resolve().parents[1]
ASSETS_ROOT = Path(
    r"C:\Users\jobva\.cursor\projects\c-Dev-ppa-wizard\assets"
)

# (source PNG, destination ICO inside the repo)
ICON_PAIRS: list[tuple[Path, Path]] = [
    # Main PPA Desktop app icon – use the new round logo provided by the user
    (
        ASSETS_ROOT
        / "c__Users_jobva_AppData_Roaming_Cursor_User_workspaceStorage_5ca333fdc354a1a9cf7193bc46d32b38_images_image-bedad425-a105-4d3a-8088-772658d039e3.png",
        REPO_ROOT / "windows" / "ppa-logo.ico",
    ),
    # Dedicated .ppaw file-type icon
    (
        ASSETS_ROOT / "ppaw-file-icon.png",
        REPO_ROOT / "windows" / "ppaw-file.ico",
    ),
]

# Common Windows icon sizes
ICON_SIZES: list[tuple[int, int]] = [
    (16, 16),
    (24, 24),
    (32, 32),
    (48, 48),
    (64, 64),
    (128, 128),
    (256, 256),
]


def convert_icon(src: Path, dst: Path) -> None:
    """Convert a PNG to a multi-size ICO."""
    if not src.is_file():
        print(f"[WARN] Source PNG missing, skipping: {src}")
        return

    dst.parent.mkdir(parents=True, exist_ok=True)

    img = Image.open(src).convert("RGBA")
    img.save(dst, format="ICO", sizes=ICON_SIZES)

    print(f"[OK] Wrote {dst}")


def main() -> None:
    for src, dst in ICON_PAIRS:
        convert_icon(src, dst)


if __name__ == "__main__":
    main()

