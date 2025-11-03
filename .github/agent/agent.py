#!/usr/bin/env python3
# Simple GitHub "agent" to summarize .github docs and annotate PRs.
# Minimal deps: requests, PyYAML (for future parsing). Adjust/extend as needed.

import os
import json
import hashlib
import requests
from pathlib import Path
from typing import Dict, Any, List

GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
REPO = os.getenv("GITHUB_REPOSITORY") or os.getenv("GITHUB_REPOSITORY", "")
EVENT_NAME = os.getenv("GITHUB_EVENT_NAME", "")
PR_NUMBER = os.getenv("PR_NUMBER", "")
WORKDIR = Path.cwd()
CACHE_DIR = WORKDIR / ".github" / ".agent_cache"
MANIFEST_PATH = CACHE_DIR / "manifest.json"

HEADERS = {"Authorization": f"token {GITHUB_TOKEN}", "Accept": "application/vnd.github.v3+json"}

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
    # Prefer commit SHA blob links — fallback to tree ref as we are running in action
    # This is a best-effort link for human reviewers.
    owner, repo = REPO.split("/", 1)
    # Use current commit SHA
    commit = os.getenv("GITHUB_SHA", "")
    return f"https://github.com/{owner}/{repo}/blob/{commit}/{path}"

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
        if c.get("user", {}).get("login") == bot_name and c.get("body", "").startswith("## .github Agent Summary"):
            return c
    return {}

def update_comment(comment_url: str, body: str):
    r = requests.patch(comment_url, headers=HEADERS, json={"body": body})
    r.raise_for_status()
    return r.json()

def build_summary(manifest: Dict[str, Any]) -> str:
    lines: List[str] = []
    lines.append("## .github Agent Summary (automated)")
    lines.append("")
    lines.append("This comment summarizes the authoritative documents under `.github/` and `docs/` and provides quick checks for PR verification.")
    lines.append("")
    lines.append("### Documents found")
    for k, v in sorted(manifest.items()):
        url = create_blob_url(k, v.get("sha", ""))
        lines.append(f"- `{k}` — SHA: `{v.get('sha','')}` — {url}")
    lines.append("")
    lines.append("### Quick checks")
    lines.append("- PR template: ensure `Quellen / References` is filled with stable refs (blob URL + sha).")
    lines.append("- If `copilot-instructions.md` exists: check whether the PR content follows project policies.")
    lines.append("")
    lines.append("### Suggested next steps for reviewer (automated hints)")
    lines.append("- Verify that all changed files are referenced in the PR `Quellen / References` section using blob URLs with SHAs.")
    lines.append("- If a referenced source is external, ensure it includes version/sha/tag or a persistent spec link.")
    lines.append("")
    lines.append("_This comment is updated automatically by the repository agent. If you prefer not to receive it, configure the workflow._")
    return "\n".join(lines)

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

    # If we are in a PR run, post/update a single comment
    if EVENT_NAME == "pull_request" and PR_NUMBER:
        summary = build_summary(new_manifest or old_manifest)
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
