#!/usr/bin/env python3
# Simple GitHub "agent" to summarize .github docs and annotate PRs.
# Extended: validates PR description for "Quellen / References" and produces
# field‑specific improvement suggestions.
# Minimal deps: requests. Adjust/extend as needed.

import os
import json
import hashlib
import requests
import re
from pathlib import Path
from typing import Dict, Any, List, Tuple, Optional

GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
REPO = os.getenv("GITHUB_REPOSITORY") or os.getenv("GITHUB_REPOSITORY", "")
EVENT_NAME = os.getenv("GITHUB_EVENT_NAME", "")
PR_NUMBER = os.getenv("PR_NUMBER", "")
WORKDIR = Path.cwd()
CACHE_DIR = WORKDIR / ".github" / ".agent_cache"
MANIFEST_PATH = CACHE_DIR / "manifest.json"

HEADERS = {"Authorization": f"token {GITHUB_TOKEN}", "Accept": "application/vnd.github.v3+json"}

# Validation regexes
URL_REGEX = re.compile(r"https?://[^\s\)]+")
SHA_REGEX = re.compile(r"[0-9a-f]{7,40}", re.IGNORECASE)
TAG_OR_VERSION_REGEX = re.compile(r"\bv?\d+\.\d+(\.\d+)?\b")
GITHUB_BLOB_REGEX = re.compile(r"https?://github\.com/[^/]+/[^/]+/blob/([0-9a-fA-F]{7,40}|[^/]+)/.+", re.IGNORECASE)

BOT_COMMENT_PREFIX = "## .github Agent Summary (automated)"

def sha_for_file(path: Path) -> str:
    data = path.read_bytes()
    return hashlib.sha1(data).hexdigest()

def collect_github_docs() -> Dict[str, Any]:
    base = WORKDIR / ".github"
    out = {}
    if not base.exists():
        return out
    for p in base.rglob("*"):
        if p.is_file():
            rel = str(p.relative_to(WORKDIR))
            try:
                sha = sha_for_file(p)
            except Exception:
                sha = ""
            out[rel] = {"sha": sha, "path": rel}
    # also include docs/ if present (optional)
    docs = WORKDIR / "docs"
    if docs.exists():
        for p in docs.rglob("*"):
            if p.is_file():
                rel = str(p.relative_to(WORKDIR))
                try:
                    sha = sha_for_file(p)
                except Exception:
                    sha = ""
                out[rel] = {"sha": sha, "path": rel}
    return out

def load_manifest() -> Dict[str, Any]:
    if MANIFEST_PATH.exists():
        try:
            return json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        except Exception:
            return {}
    return {}

def save_manifest(m: Dict[str, Any]):
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    MANIFEST_PATH.write_text(json.dumps(m, indent=2), encoding="utf-8")

def manifest_changed(old: Dict[str, Any], new: Dict[str, Any]) -> bool:
    return json.dumps(old, sort_keys=True) != json.dumps(new, sort_keys=True)

def create_blob_url(path: str, sha: str) -> str:
    owner, repo = REPO.split("/", 1) if "/" in REPO else ("", "")
    commit = os.getenv("GITHUB_SHA", "")
    if owner and repo and commit:
        return f"https://github.com/{owner}/{repo}/blob/{commit}/{path}"
    return path

def post_pr_comment(pr_number: str, body: str):
    owner, repo = REPO.split("/", 1)
    url = f"https://api.github.com/repos/{owner}/{repo}/issues/{pr_number}/comments"
    r = requests.post(url, headers=HEADERS, json={"body": body})
    r.raise_for_status()
    return r.json()

def find_existing_bot_comment(pr_number: str, bot_name: str="github-actions[bot]") -> Dict[str, Any]:
    owner, repo = REPO.split("/", 1)
    url = f"https://api.github.com/repos/{owner}/{repo}/issues/{pr_number}/comments"
    r = requests.get(url, headers=HEADERS)
    r.raise_for_status()
    for c in r.json():
        if c.get("user", {}).get("login") == bot_name and c.get("body", "").startswith(BOT_COMMENT_PREFIX):
            return c
    return {}

def update_comment(comment_url: str, body: str):
    r = requests.patch(comment_url, headers=HEADERS, json={"body": body})
    r.raise_for_status()
    return r.json()

def build_summary(manifest: Dict[str, Any], pr_findings: Optional[Dict[str, Any]] = None) -> str:
    lines: List[str] = []
    lines.append(BOT_COMMENT_PREFIX)
    lines.append("")
    lines.append("This comment summarizes the authoritative documents under `.github/` and `docs/` and provides quick checks for PR verification.")
    lines.append("")
    lines.append("### Documents found")
    for k, v in sorted(manifest.items()):
        url = create_blob_url(k, v.get("sha", ""))
        lines.append(f"- `{k}` — SHA: `{v.get('sha','')}` — {url}")
    lines.append("")
    lines.append("### PR description validation")
    if not pr_findings:
        lines.append("- No PR validation performed in this run.")
    else:
        status = pr_findings.get("status", "unknown")
        lines.append(f"- Overall status: **{status}**")
        lines.append("")
        if pr_findings.get("sections"):
            lines.append("#### Detected sections")
            for sec in pr_findings["sections"]:
                lines.append(f"- {sec}")
            lines.append("")
        if pr_findings.get("issues"):
            lines.append("#### Issues found")
            for issue in pr_findings["issues"]:
                lines.append(f"- {issue}")
            lines.append("")
        if pr_findings.get("suggestions"):
            lines.append("#### Concrete suggestions (field‑level)")
            for s in pr_findings["suggestions"]:
                lines.append(f"- {s}")
            lines.append("")
    lines.append("### Suggested next steps for reviewer (automated hints)")
    lines.append("- Verify that all changed files are referenced in the PR `Quellen / References` section using blob URLs with SHAs.")
    lines.append("- If a referenced source is external, ensure it includes version/sha/tag or a persistent spec link.")
    lines.append("")
    lines.append("_This comment is updated automatically by the repository agent. It provides proposed text the author can copy/paste into the PR description. The agent does not edit the PR body._")
    return "\n".join(lines)

# PR validation helpers
def get_pr_data(pr_number: str) -> Dict[str, Any]:
    owner, repo = REPO.split("/", 1)
    url = f"https://api.github.com/repos/{owner}/{repo}/pulls/{pr_number}"
    r = requests.get(url, headers=HEADERS)
    r.raise_for_status()
    return r.json()

def detect_sections(pr_body: str) -> List[str]:
    sections = []
    # Find headings
    for m in re.finditer(r"(^|\n)(#{1,6}\s*)([^\n]+)", pr_body):
        heading = m.group(3).strip()
        sections.append(heading)
    # also include plain "Quellen / References" without leading #
    if re.search(r"(^|\n)Quellen\s*/\s*References", pr_body, re.IGNORECASE):
        sections.append("Quellen / References (plain)")
    return sections

def extract_urls(pr_body: str) -> List[str]:
    return URL_REGEX.findall(pr_body)

def analyze_references(urls: List[str]) -> Tuple[bool, List[str], List[str]]:
    """
    Returns (has_stable_ref, good_refs, bad_refs)
    good_refs: urls that include a stable ref (blob with sha or tag)
    bad_refs: urls that lack stable ref or are non-actionable
    """
    good = []
    bad = []
    for u in urls:
        # Check for GitHub blob with commit SHA or tag in the blob part
        blob_match = GITHUB_BLOB_REGEX.match(u)
        if blob_match:
            ref = blob_match.group(1)
            # if ref looks like a SHA or a tag/version, treat as good
            if SHA_REGEX.search(ref) or TAG_OR_VERSION_REGEX.search(ref):
                good.append(u)
                continue
        # If contains a SHA anywhere
        if SHA_REGEX.search(u):
            good.append(u)
            continue
        # version-like
        if TAG_OR_VERSION_REGEX.search(u):
            good.append(u)
            continue
        # allow certain authoritative docs (examples)
        if "lua-api.factorio.com" in u or "wiki.factorio.com" in u:
            good.append(u)
            continue
        bad.append(u)
    return (len(good) > 0, good, bad)

def produce_field_suggestions(pr_body: str, urls: List[str], good_refs: List[str], bad_refs: List[str], files_changed: List[str]) -> List[str]:
    suggestions: List[str] = []
    # Suggest concrete Beispiele for Quellen / References
    if not urls:
        suggestions.append("Füge eine Section `Quellen / References` hinzu mit mindestens einer stabil referenzierten URL. Beispiel:\n\nTyp: Interne Doku\n- Beschreibung: PR-relevant design\n- URL: https://github.com/<owner>/<repo>/blob/<commit-sha>/docs/design.md#abschnitt\n- Relevanter Abschnitt: Zeile X–Y")
    else:
        if bad_refs:
            for b in bad_refs:
                suggestions.append(f"Ersetze oder ergänze die unsichere Referenz `{b}` mit einer stabilen Referenz (blob URL mit commit SHA oder Tag). Beispiel: `https://github.com/owner/repo/blob/<commit-sha>/path#L10-L20`")
        if good_refs:
            suggestions.append("Die folgenden Referenzen sehen stabil aus und können so beibehalten werden:")
            for g in good_refs:
                suggestions.append(f"- {g}")
    # If there are changed files not mentioned in references, suggest adding them
    mentioned_files = set()
    for u in urls:
        m = re.search(r"github\.com/.+?/blob/.+?/(.+?)(#|$)", u)
        if m:
            mentioned_files.add(m.group(1))
    uncovered = []
    for f in files_changed:
        # Normalize simple paths and check prefix match
        if not any(f.endswith(mf) or mf.endswith(f) or mf in f for mf in mentioned_files):
            uncovered.append(f)
    if uncovered:
        suggestions.append("Einige geänderte Dateien sind nicht in den `Quellen / References` aufgeführt. Bitte ergänze für jede relevante Datei eine Quelle oder erkläre, warum keine Quelle nötig ist. Fehlende Datei-Beispiele:")
        for u in uncovered[:20]:
            suggestions.append(f"- {u}")
    # Suggest verification step
    suggestions.append("Füge in 'Erklärung zur Verifikation' konkrete Prüfschritte hinzu, z. B. `Vergleiche die Validierungsregeln in src/validator.py mit Abschnitt X in docs/spec.md (Zeilen Y–Z)`.")
    return suggestions

def get_files_changed_in_pr(pr_number: str) -> List[str]:
    owner, repo = REPO.split("/", 1)
    files = []
    page = 1
    while True:
        url = f"https://api.github.com/repos/{owner}/{repo}/pulls/{pr_number}/files?page={page}&per_page=100"
        r = requests.get(url, headers=HEADERS)
        r.raise_for_status()
        batch = r.json()
        if not batch:
            break
        for f in batch:
            files.append(f.get("filename"))
        if len(batch) < 100:
            break
        page += 1
    return files

def validate_pr_description(pr_body: str, pr_number: str) -> Dict[str, Any]:
    findings: Dict[str, Any] = {"status": "ok", "sections": [], "issues": [], "suggestions": []}
    sections = detect_sections(pr_body)
    findings["sections"] = sections
    # Check for Quellen / References heading
    has_references_heading = any(re.search(r"(^|\n)#{1,6}\s*Quellen\s*/\s*References", pr_body, re.IGNORECASE) or re.search(r"(^|\n)Quellen\s*/\s*References", pr_body, re.IGNORECASE) for _ in [0])
    urls = extract_urls(pr_body)
    has_stable_ref, good_refs, bad_refs = analyze_references(urls)
    files_changed = get_files_changed_in_pr(pr_number) if pr_number else []
    # Build issues
    if not has_references_heading:
        findings["issues"].append("PR body does not contain a 'Quellen / References' section heading.")
    if not urls:
        findings["issues"].append("No URLs found in the PR body. At least one stable reference is required.")
    if urls and not has_stable_ref:
        findings["issues"].append("Found URLs, but none include a stable reference (commit SHA or explicit version/tag).")
    # Update status
    if findings["issues"]:
        findings["status"] = "action_required"
    # Suggestions
    findings["suggestions"] = produce_field_suggestions(pr_body, urls, good_refs, bad_refs, files_changed)
    return findings

def main():
    if not REPO:
        print("REPO not set; aborting (expect GITHUB_REPOSITORY env).")
        return
    # Collect current docs state
    new_manifest = collect_github_docs()
    old_manifest = load_manifest()
    changed = manifest_changed(old_manifest, new_manifest)
    if changed:
        print("Manifest changed; saving new manifest.")
        save_manifest(new_manifest)
    else:
        print("Manifest unchanged.")

    pr_findings = None
    # If we are in a PR run, validate PR description and post/update a single comment
    if EVENT_NAME == "pull_request" and PR_NUMBER:
        try:
            pr_data = get_pr_data(PR_NUMBER)
            pr_body = pr_data.get("body", "") or ""
            pr_findings = validate_pr_description(pr_body, PR_NUMBER)
        except Exception as e:
            pr_findings = {"status": "error", "issues": [f"Failed to fetch/analyze PR: {e}"], "sections": [], "suggestions": []}

        summary = build_summary(new_manifest or old_manifest, pr_findings)
        existing = find_existing_bot_comment(PR_NUMBER)
        if existing:
            print("Updating existing agent comment.")
            update_comment(existing["url"], summary)
        else:
            print("Posting new agent comment.")
            post_pr_comment(PR_NUMBER, summary)
    else:
        print("Not a PR event; finished.")

if __name__ == "__main__":
    main()
