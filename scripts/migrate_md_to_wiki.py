#!/usr/bin/env python3
import subprocess
import sys
from pathlib import Path
import shutil
import filecmp

REPO_ROOT = Path(__file__).resolve().parents[1]
WIKI_ROOT = REPO_ROOT / "khetisahayak.wiki"

EXCLUDE_DIRS = {
    ".git",
    ".idx",
    ".vscode",
    "khetisahayak.wiki",
}


def run(cmd, cwd=REPO_ROOT, check=True):
    res = subprocess.run(cmd, cwd=str(cwd), text=True, capture_output=True)
    if check and res.returncode != 0:
        raise RuntimeError(f"Command failed: {' '.join(cmd)}\nSTDOUT: {res.stdout}\nSTDERR: {res.stderr}")
    return res


def list_tracked_md():
    res = run(["git", "ls-files"], check=True)
    files = [Path(line.strip()) for line in res.stdout.splitlines() if line.strip()]
    return [f for f in files if f.suffix.lower() == ".md" and not str(f).startswith("khetisahayak.wiki/")]


def ensure_parent(p: Path):
    p.parent.mkdir(parents=True, exist_ok=True)


def git_mv(src: Path, dst: Path):
    ensure_parent(dst)
    run(["git", "mv", str(src), str(dst)])


def git_rm(path: Path):
    run(["git", "rm", "-f", str(path)])


def main():
    moved, skipped_same, conflicts = 0, 0, 0
    files = list_tracked_md()
    if not files:
        print("No Markdown files to migrate.")
        return 0

    for src in files:
        dst = WIKI_ROOT / src
        if dst.exists():
            try:
                same = filecmp.cmp(REPO_ROOT / src, dst, shallow=False)
            except Exception:
                same = False
            if same:
                # Remove source, keep existing wiki version
                git_rm(src)
                skipped_same += 1
                continue
            else:
                # Keep existing wiki file; stage a migrated copy alongside
                migrated = dst.with_name(dst.stem + "_migrated" + dst.suffix)
                ensure_parent(migrated)
                shutil.copy2(REPO_ROOT / src, migrated)
                git_rm(src)
                conflicts += 1
                continue
        # Normal move
        git_mv(src, dst)
        moved += 1

    print(f"Moved: {moved}, Removed duplicates: {skipped_same}, Conflicts (kept *_migrated.md): {conflicts}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
