#!/usr/bin/env python3
import os
import re
import json
import subprocess
from pathlib import Path
from typing import List, Tuple, Dict, Set

REPO_ROOT = Path(__file__).resolve().parents[1]
WIKI_ROOT = REPO_ROOT / "khetisahayak.wiki"
TRACEABILITY_FILE = WIKI_ROOT / "prd" / "prd_task_traceability.md"
REPO_SLUG = "automotiv/khetisahayak"
REPO_BASE_WIKI = "https://github.com/automotiv/khetisahayak/wiki/"

# Reuse the table parsing from other scripts
ROW_REGEX = re.compile(r"\|\s*\*\*(?P<feature>.*?)\*\*.*?\|\s*\[.*?\]\((?P<prd>.*?)\)\s*\|\s*(?P<issuecol>.*?)\|", re.DOTALL)
ISSUE_LINK_REGEX = re.compile(r"\[(?P<label>.*?)\]\((?P<url>https?://github.com/[^/]+/[^/]+/issues/(?P<num>\d+))\)")

# Markdown link regex
MD_LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")

# Section markers for idempotent updates
SECTION_START = "<!-- RELATED_WIKI_DOCS_START -->"
SECTION_END = "<!-- RELATED_WIKI_DOCS_END -->"
SECTION_TITLE = "## Related Wiki Docs"


def run(cmd: List[str], cwd: Path = REPO_ROOT, check: bool = True, capture: bool = True) -> subprocess.CompletedProcess:
    res = subprocess.run(cmd, cwd=str(cwd), text=True, capture_output=capture)
    if check and res.returncode != 0:
        raise RuntimeError(f"Command failed: {' '.join(cmd)}\nSTDOUT: {res.stdout}\nSTDERR: {res.stderr}")
    return res


def gh_issue_body(issue_number: int) -> str:
    res = run(["gh", "issue", "view", str(issue_number), "--repo", REPO_SLUG, "--json", "body", "--jq", ".body"])  # type: ignore
    return (res.stdout or "").strip()


def gh_issue_update(issue_number: int, new_body: str) -> None:
    run(["gh", "issue", "edit", str(issue_number), "--repo", REPO_SLUG, "--body", new_body], capture=False)


def to_canonical_wiki_url(rel_path_from_wiki_root: str) -> str:
    # Normalize and strip .md for canonical wiki URL
    rel = os.path.normpath(rel_path_from_wiki_root).replace(os.path.sep, "/")
    if rel.endswith(".md"):
        rel = rel[:-3]
    return f"{REPO_BASE_WIKI}{rel}"


def resolve_wiki_link(base_doc: Path, link_target: str) -> Tuple[str, Path]:
    """Resolve a markdown link target to a wiki-relative path and filesystem path.
    Returns (wiki_rel_path, abs_fs_path). Raises ValueError if not a wiki doc link.
    """
    # Ignore anchors and querystrings
    if link_target.startswith("#"):
        raise ValueError("anchor")
    if link_target.startswith("http://") or link_target.startswith("https://"):
        # External; only keep if already canonical wiki URL
        if "/automotiv/khetisahayak/wiki/" in link_target:
            # Convert to wiki relative if possible
            try:
                wiki_rel = link_target.split("/wiki/")[-1]
                fs_path = WIKI_ROOT / wiki_rel
                if not str(fs_path).endswith(".md"):
                    fs_path = fs_path.with_suffix(".md")
                return (wiki_rel, fs_path)
            except Exception:
                raise ValueError("external")
        raise ValueError("external")

    # Treat as relative to the current PRD file directory
    abs_path = (base_doc.parent / link_target).resolve()
    try:
        abs_path.relative_to(WIKI_ROOT)
    except ValueError:
        raise ValueError("outside_wiki")

    if abs_path.is_dir():
        # Not a document; skip
        raise ValueError("dir")

    if abs_path.suffix == "":
        abs_path = abs_path.with_suffix(".md")

    if abs_path.suffix.lower() != ".md":
        raise ValueError("non_md")

    wiki_rel = str(abs_path.relative_to(WIKI_ROOT)).replace(os.path.sep, "/")
    return (wiki_rel, abs_path)


def extract_related_wiki_links(prd_file: Path) -> List[Tuple[str, str]]:
    """Return list of (label, canonical_url) from links inside a PRD markdown file.
    Only includes links that resolve to files under the wiki root, and are .md files.
    """
    text = prd_file.read_text(encoding="utf-8")
    found: List[Tuple[str, str]] = []
    seen_urls: Set[str] = set()

    for m in MD_LINK_RE.finditer(text):
        label = m.group(1).strip()
        target = m.group(2).strip()
        try:
            wiki_rel, fs_path = resolve_wiki_link(prd_file, target)
        except ValueError:
            continue

        # Skip self
        if fs_path.resolve() == prd_file.resolve():
            continue

        canonical = to_canonical_wiki_url(wiki_rel)
        if canonical in seen_urls:
            continue
        seen_urls.add(canonical)
        found.append((label or fs_path.stem.replace("-", " "), canonical))

    return found


def iter_all_wiki_md_files() -> List[Path]:
    files: List[Path] = []
    for p in WIKI_ROOT.rglob("*.md"):
        # Skip traceability matrix itself to avoid noisy backlinks
        files.append(p)
    return files


def normalize_rel_no_ext(rel_path: str) -> str:
    rel = os.path.normpath(rel_path).replace(os.path.sep, "/")
    if rel.endswith(".md"):
        rel = rel[:-3]
    return rel


def extract_backlinks_for_prd(prd_rel_path: str) -> List[Tuple[str, str]]:
    """Find all wiki docs that link to the given PRD (relative path under wiki/prd/).
    Returns list of (label, canonical_url) for the source documents.
    """
    prd_rel_no_ext = normalize_rel_no_ext(prd_rel_path if not prd_rel_path.startswith("prd/") else prd_rel_path)
    # Ensure has leading folder 'prd/' in compare key
    if not prd_rel_no_ext.startswith("prd/"):
        prd_rel_no_ext = f"prd/{prd_rel_no_ext}"

    backlinks: List[Tuple[str, str]] = []
    seen: Set[str] = set()

    for doc in iter_all_wiki_md_files():
        try:
            text = doc.read_text(encoding="utf-8")
        except Exception:
            continue
        matched_here = False
        for m in MD_LINK_RE.finditer(text):
            label = m.group(1).strip()
            target = m.group(2).strip()

            # Extract target as wiki-relative path if possible, keep anchor if present
            target_path = ""
            if target.startswith("http://") or target.startswith("https://"):
                if "/automotiv/khetisahayak/wiki/" not in target:
                    continue
                after = target.split("/wiki/")[-1]
                # remove querystring
                after = after.split("?")[0]
                # keep anchor for match only
                t_path = after.split("#")[0]
                target_path = t_path
            else:
                # relative link; resolve against doc
                abs_t = (doc.parent / target)
                # strip anchor and query
                pure = str(abs_t).split("#")[0].split("?")[0]
                abs_path = Path(pure)
                if abs_path.suffix == "":
                    abs_path = abs_path.with_suffix(".md")
                try:
                    rel = abs_path.resolve().relative_to(WIKI_ROOT)
                except Exception:
                    continue
                target_path = str(rel).replace(os.path.sep, "/")

            # Compare without extension
            if normalize_rel_no_ext(target_path) == prd_rel_no_ext:
                matched_here = True
                # Use source doc as backlink target
                source_rel = str(doc.relative_to(WIKI_ROOT)).replace(os.path.sep, "/")
                canon = to_canonical_wiki_url(source_rel)
                if canon in seen:
                    continue
                seen.add(canon)
                # Friendly label: prefer doc title from first heading if available
                doc_label = doc.stem.replace("_", " ").replace("-", " ")
                backlinks.append((doc_label, canon))
        # Continue scanning others

    return backlinks


def build_section(links: List[Tuple[str, str]]) -> str:
    if not links:
        return ""
    lines = [SECTION_START, SECTION_TITLE]
    for label, url in links:
        lines.append(f"- [{label}]({url})")
    lines.append(SECTION_END)
    return "\n".join(lines) + "\n"


def upsert_related_docs_section(body: str, section_md: str) -> str:
    if not section_md:
        return body
    start = body.find(SECTION_START)
    end = body.find(SECTION_END)
    if start != -1 and end != -1:
        end += len(SECTION_END)
        before = body[:start].rstrip() + "\n\n"
        after = body[end:].lstrip()
        return before + section_md + "\n" + after
    # Append at end, ensuring a blank line separator
    sep = "\n\n" if not body.endswith("\n\n") else ""
    return body + sep + section_md


def main():
    if not TRACEABILITY_FILE.exists():
        raise SystemExit(f"Traceability file not found: {TRACEABILITY_FILE}")

    matrix = TRACEABILITY_FILE.read_text(encoding="utf-8")
    rows = ROW_REGEX.findall(matrix)
    if not rows:
        raise SystemExit("No rows found in traceability matrix")

    updated = 0
    for feature, prd_link, issue_col in rows:
        m = ISSUE_LINK_REGEX.search(issue_col)
        if not m:
            print(f"Skipping '{feature}': missing issue link in matrix")
            continue
        issue_num = int(m.group("num"))
        prd_fs_path = (WIKI_ROOT / "prd" / prd_link).resolve()
        if not prd_fs_path.exists():
            print(f"Skipping issue #{issue_num}: PRD file not found -> {prd_fs_path}")
            continue

        # Forward links from PRD page
        related = extract_related_wiki_links(prd_fs_path)
        # Backlinks from any wiki page to this PRD
        backlinks = extract_backlinks_for_prd(str(Path("prd") / prd_link))
        # Merge and dedupe by URL
        all_links: List[Tuple[str, str]] = []
        seen_urls: Set[str] = set()
        for pair in (related + backlinks):
            if pair[1] in seen_urls:
                continue
            seen_urls.add(pair[1])
            all_links.append(pair)
        if not all_links:
            print(f"No related or backlink wiki links for issue #{issue_num}")
            continue

        section = build_section(all_links)
        current = gh_issue_body(issue_num)
        new_body = upsert_related_docs_section(current, section)
        if new_body != current:
            gh_issue_update(issue_num, new_body)
            updated += 1
            print(f"Updated issue #{issue_num} with {len(all_links)} related/backlink wiki link(s)")
        else:
            print(f"Issue #{issue_num} already up-to-date")

    print(f"Updated {updated} issue(s) with Related Wiki Docs section")


if __name__ == "__main__":
    main()
