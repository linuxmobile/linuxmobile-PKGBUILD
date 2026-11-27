#!/usr/bin/env python3
"""Regenerate the marked ISA table and note in README.md from config/isa-policy.tsv.

Only the marked regions are replaced; unrelated README content is preserved.
"""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parent.parent
README = ROOT / "README.md"
POLICY = ROOT / "config" / "isa-policy.tsv"
TABLE_START = "<!-- BEGIN GENERATED PACKAGE ISA STATUS -->"
TABLE_END = "<!-- END GENERATED PACKAGE ISA STATUS -->"
NOTE_START = "<!-- BEGIN GENERATED PACKAGE ISA NOTE -->"
NOTE_END = "<!-- END GENERATED PACKAGE ISA NOTE -->"

PAYLOADS = {
    "antigravity-cli": "Upstream binary archive",
    "agentty": "CMake/C++",
    "ardia": "Upstream binary archive",
    "blurcam": "CMake/C++",
    "chromium-widevine-helper": "Python / assets",
    "cressida": "Meson/C++",
    "frame": "Rust",
    "flow-control": "Zig",
    "hibiki": "Rust",
    "isocast": "Rust",
    "kernwatch": "Rust",
    "ladybird": "Upstream Debian package",
    "lui": "Zig",
    "mdrs": "Rust",
    "microsoft-edge-beta": "Upstream Debian package",
    "monocode": "Rust",
    "monstar": "Zig",
    "multiviewer": "Upstream Electron archive",
    "netwatch": "Rust",
    "obs-pipewire-audio-capture": "CMake/C++",
    "omalive": "Rust",
    "omatuner": "Rust",
    "oxfmt": "Rust",
    "ps_mem": "Python",
    "rgrc": "Rust",
    "rhun": "Assembly",
    "rlottie": "CMake/C++",
    "rune": "Rust, Zig",
    "sonora": "Rust",
    "strata": "Rust",
    "syswatch": "Rust",
    "zmon": "Zig",
}


def load_policy() -> list[tuple[str, str, str]]:
    entries: list[tuple[str, str, str]] = []
    seen: set[str] = set()
    for lineno, raw in enumerate(POLICY.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        fields = raw.split("|", 3)
        if len(fields) != 4:
            raise ValueError(f"{POLICY}:{lineno}: expected 4 pipe-separated fields")
        package, policy, _exception, _reason = (field.strip() for field in fields)
        if package in seen:
            raise ValueError(f"{POLICY}:{lineno}: duplicate package {package}")
        if package not in PAYLOADS:
            raise ValueError(f"{POLICY}:{lineno}: no README payload label for {package}")
        seen.add(package)
        entries.append((package, policy, PAYLOADS[package]))
    return entries


def status_for(policy: str, package: str) -> str:
    if policy == "required":
        return "Enforced by CI (ELF ISA note)"
    if policy == "partial":
        return "Partial; bundled upstream ELF excluded"
    if policy == "upstream":
        return "Upstream binary; not guaranteed"
    if policy == "any":
        return "n/a (`any`)"
    if policy == "target":
        return "v3 target selected; GNU ISA note not asserted"
    if policy == "review":
        return "Review required; ISA audit/tuning pending"
    raise ValueError(f"{package}: unknown ISA policy {policy!r}")


def generated_table(entries: list[tuple[str, str, str]]) -> list[str]:
    rows = [
        TABLE_START + "\n",
        "| Package | Payload / build | x86-64-v3 status |\n",
        "| -------------------------- | --------------- | ---------------- |\n",
    ]
    for package, policy, payload in entries:
        rows.append(f"| {package} | {payload} | {status_for(policy, package)} |\n")
    rows.append(TABLE_END + "\n")
    return rows


def locate_table(lines: list[str]) -> tuple[int, int]:
    starts = [i for i, line in enumerate(lines) if line.strip() == TABLE_START]
    ends = [i for i, line in enumerate(lines) if line.strip() == TABLE_END]
    if len(starts) != 1 or len(ends) != 1 or starts[0] >= ends[0]:
        raise ValueError("README has malformed generated ISA table markers")
    return starts[0], ends[0] + 1


def replace_note(lines: list[str]) -> list[str]:
    note = (
        NOTE_START + "\n"
        + "The ISA status table is generated from `config/isa-policy.tsv` during repository publication. "
        + "`required` packages are checked for the GNU `x86 ISA needed` property.\n"
        + NOTE_END + "\n"
    ).splitlines(keepends=True)

    starts = [i for i, line in enumerate(lines) if line.strip() == NOTE_START]
    ends = [i for i, line in enumerate(lines) if line.strip() == NOTE_END]
    if len(starts) != 1 or len(ends) != 1 or starts[0] >= ends[0]:
        raise ValueError("README has malformed generated ISA note markers")
    return lines[: starts[0]] + note + lines[ends[0] + 1 :]


def main() -> int:
    entries = load_policy()
    lines = README.read_text(encoding="utf-8").splitlines(keepends=True)
    start, end = locate_table(lines)
    updated = lines[:start] + generated_table(entries) + lines[end:]
    updated = replace_note(updated)
    content = "".join(updated)
    if content != README.read_text(encoding="utf-8"):
        README.write_text(content, encoding="utf-8")
        print("Updated README package ISA status from config/isa-policy.tsv")
    else:
        print("README package ISA status is already up to date")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)
