#!/usr/bin/env python3
import os
import re
import subprocess
from pathlib import Path
from typing import List, Tuple, Dict, Set

import requests

REPO_ROOT = Path(__file__).resolve().parents[1]
WIKI_ROOT = REPO_ROOT / "khetisahayak.wiki"
TRACEABILITY_FILE = WIKI_ROOT / "prd" / "prd_task_traceability.md"
REPO_SLUG = "automotiv/khetisahayak"
REPO_BASE_WIKI = "https://github.com/automotiv/khetisahayak/wiki/"

ROW_REGEX = re.compile(r"\|\s*\*\*(?P<feature>.*?)\*\*.*?\|\s*\[.*?\]\((?P<prd>.*?)\)\s*\|\s*(?P<issuecol>.*?)\|", re.DOTALL)
ISSUE_LINK_REGEX = re.compile(r"\[(?P<label>.*?)\]\((?P<url>https?://github.com/[^/]+/[^/]+/issues/(?P<num>\d+))\)")
MD_LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")

SECTION_START = "<!-- RELATED_WIKI_DOCS_START -->"
SECTION_END = "<!-- RELATED_WIKI_DOCS_END -->"
SECTION_TITLE = "## Related Wiki Docs"

HEADERS = {"User-Agent": "Mozilla/5.0"}

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
    rel = os.path.normpath(rel_path_from_wiki_root).replace(os.path.sep, "/")
    if rel.endswith(".md"):
        rel = rel[:-3]
    return f"{REPO_BASE_WIKI}{rel}"


def prd_rel_to_raw_url(prd_rel: str) -> str:
    # Build raw markdown URL for a PRD page under wiki/prd/
    rel = os.path.normpath(prd_rel).replace(os.path.sep, "/")
    if not rel.endswith(".md"):
        rel = rel + ".md"
    return f"https://raw.githubusercontent.com/wiki/automotiv/khetisahayak/prd/{rel}"


def fetch(url: str) -> str:
    r = requests.get(url, headers=HEADERS, timeout=20)
    r.raise_for_status()
    return r.text


def extract_links_from_markdown(md_text: str, base_prd_rel: str) -> List[Tuple[str, str]]:
    """Parse markdown links and convert internal wiki links to canonical /wiki/ URLs.
    base_prd_rel is the PRD relative path under prd/ (with .md).
    """
    links: List[Tuple[str, str]] = []
    seen: Set[str] = set()

    base_dir = os.path.dirname(base_prd_rel)

    for m in MD_LINK_RE.finditer(md_text):
        label = m.group(1).strip()
        target = m.group(2).strip()

        # Skip anchors and mailto
        if target.startswith("#") or target.startswith("mailto:"):
            continue

        # Absolute wiki URL
        if target.startswith("http://") or target.startswith("https://"):
            if "/automotiv/khetisahayak/wiki/" not in target:
                continue
            url = target.split("?")[0]
            if url in seen:
                continue
            seen.add(url)
            links.append((label or url.rsplit("/", 1)[-1].replace("-", " "), url))
            continue

        # Relative path inside wiki, resolve against prd/<base_dir>
        rel = os.path.normpath(os.path.join("prd", base_prd_rel))
        # resolve target relative to the PRD's dir
        tgt = os.path.normpath(os.path.join("prd", base_dir, target)).replace(os.path.sep, "/")
        # ensure .md for canonical conversion
        if not tgt.endswith(".md"):
            tgt_md = tgt + ".md"
        else:
            tgt_md = tgt
        canon = to_canonical_wiki_url(tgt_md)
        if canon in seen:
            continue
        seen.add(canon)
        links.append((label or tgt_md.rsplit("/", 1)[-1].replace("-", " "), canon))

    return links


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
    sep = "\n\n" if not body.endswith("\n\n") else ""
    return body + sep + section_md


def parse_traceability() -> List[Tuple[int, str]]:
    text = TRACEABILITY_FILE.read_text(encoding="utf-8")
    rows = ROW_REGEX.findall(text)
    items: List[Tuple[int, str]] = []
    for _feature, prd_link, issue_col in rows:
        m = ISSUE_LINK_REGEX.search(issue_col)
        if not m:
            continue
        num = int(m.group("num"))
        items.append((num, prd_link))
    return items


def main():
    if not TRACEABILITY_FILE.exists():
        raise SystemExit(f"Traceability file not found: {TRACEABILITY_FILE}")

    mapping = parse_traceability()
    updated = 0
    for issue_num, prd_rel in mapping:
        raw_url = prd_rel_to_raw_url(prd_rel)
        try:
            md_text = fetch(raw_url)
        except Exception as e:
            print(f"Skipping issue #{issue_num}: failed to fetch {raw_url} -> {e}")
            continue
        # Extract markdown links and convert to canonical wiki URLs
        prd_rel_md = prd_rel if prd_rel.endswith(".md") else prd_rel + ".md"
        links = extract_links_from_markdown(md_text, prd_rel_md)
        if not links:
            print(f"No wiki links found in PRD markdown for issue #{issue_num}")
            continue
        section = build_section(links)
        current = gh_issue_body(issue_num)
        new_body = upsert_related_docs_section(current, section)
        if new_body != current:
            gh_issue_update(issue_num, new_body)
            updated += 1
            print(f"Updated issue #{issue_num} with {len(links)} wiki link(s) from PRD page")
        else:
            print(f"Issue #{issue_num} already up-to-date")

    print(f"Updated {updated} issue(s) with Related Wiki Docs section")


if __name__ == "__main__":
    main()
