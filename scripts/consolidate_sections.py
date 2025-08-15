#!/usr/bin/env python3
import re
import subprocess
from pathlib import Path
import shutil
import filecmp

REPO_ROOT = Path(__file__).resolve().parents[1]
WIKI_ROOT = REPO_ROOT / "khetisahayak.wiki"
DEST_DIR = WIKI_ROOT / "prd" / "sections"

SECTION_PATTERN = re.compile(r"section_[^/\\]+\.md$")


def run(cmd, cwd=REPO_ROOT, check=True):
    res = subprocess.run(cmd, cwd=str(cwd), text=True, capture_output=True)
    if check and res.returncode != 0:
        raise RuntimeError(f"Command failed: {' '.join(cmd)}\nSTDOUT: {res.stdout}\nSTDERR: {res.stderr}")
    return res


def git_ls_files():
    res = run(["git", "ls-files"])
    return [Path(p) for p in res.stdout.splitlines() if p.strip()]


def ensure_dir(p: Path):
    p.mkdir(parents=True, exist_ok=True)


def git_mv(src: Path, dst: Path):
    ensure_dir(dst.parent)
    run(["git", "mv", str(src), str(dst)])


def git_rm(path: Path):
    run(["git", "rm", "-f", str(path)])


def main():
    ensure_dir(DEST_DIR)
    tracked = git_ls_files()
    # Identify section_* files under wiki
    section_files = [p for p in tracked if p.suffix.lower() == ".md" and str(p).startswith("khetisahayak.wiki/") and SECTION_PATTERN.search(p.name)]

    moved = 0
    removed_dupe = 0
    conflicts = []

    for src in section_files:
        # Skip if already in prd/sections
        if str(src).startswith("khetisahayak.wiki/prd/sections/"):
            continue
        dst = DEST_DIR / src.name
        if dst.exists():
            # Compare contents
            try:
                same = filecmp.cmp(REPO_ROOT / src, dst, shallow=False)
            except Exception:
                same = False
            if same:
                git_rm(src)
                removed_dupe += 1
                continue
            else:
                # Keep existing dest, stage alt copy
                alt = DEST_DIR / (dst.stem + "_alt" + dst.suffix)
                shutil.copy2(REPO_ROOT / src, alt)
                git_rm(src)
                conflicts.append((src, dst))
                continue
        # Normal move
        git_mv(src, dst)
        moved += 1

    # Update links across wiki: replace references to any section_*.md (relative or path-based) with canonical /wiki/prd/sections/<name>
    md_files = [p for p in tracked if p.suffix.lower() == ".md" and str(p).startswith("khetisahayak.wiki/")]
    changed = 0
    link_re = re.compile(r"\((?:\./|\.\./|/)?(?:khetisahayak\.wiki/)?(?:prd/)?(?:sections/)?(section_[^)#]+?)\)"
                         , re.IGNORECASE)

    for md in md_files:
        path = REPO_ROOT / md
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        new = text
        def repl(m):
            target = m.group(1)
            target = target.split('#')[0]
            if target.endswith('.md'):
                target = target[:-3]
            return f"(https://github.com/automotiv/khetisahayak/wiki/prd/sections/{target})"
        new = link_re.sub(repl, new)
        if new != text:
            path.write_text(new, encoding="utf-8")
            changed += 1
            # stage file
            run(["git", "add", str(md)])

    # Stage all moves/removes
    run(["git", "add", "-A"])
    print(f"Moved: {moved}, Removed dupes: {removed_dupe}, Conflicts: {len(conflicts)}, Updated files: {changed}")


if __name__ == "__main__":
    main()
