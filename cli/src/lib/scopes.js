// `[identity].scopes` → GitHub App permissions.
//
// Spec rule 2 says scopes are the ceiling: the runtime can never acquire a
// permission the manifest doesn't declare. This file is where that sentence
// becomes arithmetic. Every token epito mints asks GitHub for exactly the
// permissions this table derives from the manifest — never the installation's
// full grant, which is usually wider.
//
// v0.1 maps the three the alexandria seat shapes need (a daily builder, a
// weekly writer, an event-driven responder) plus metadata. A `github:` scope
// with no row here is a loud failure, not a silent drop: an agent that thinks
// it has a permission it was never given fails later, in the middle of a run,
// with GitHub's error instead of ours.
export const GITHUB_SCOPES = {
  "github:contents": ["contents", "write"],
  "github:issues": ["issues", "write"],
  "github:metadata": ["metadata", "read"],
  "github:pull_requests": ["pull_requests", "write"],
};

export const MAPPED = Object.keys(GITHUB_SCOPES).sort();

// GitHub grants metadata:read to every installation and several permissions
// imply it; asking for it explicitly costs nothing and keeps the token's
// permission set readable in the audit line.
const ALWAYS = { metadata: "read" };

export function unmappedScopeError(scope) {
  return `scope "${scope}" names no GitHub permission — v0.1 maps ${MAPPED.join(", ")}. Remove it from [identity].scopes, or propose the mapping as a spec change (spec/manifest.md, "Scope mapping") before an agent relies on it`;
}

// Returns { permissions, errors }. `permissions` is the object the
// installation-token API takes; `errors` is empty or fatal — a partially
// mapped scope list never mints, because the ceiling would be wrong.
export function mapScopes(scopes) {
  const permissions = { ...ALWAYS };
  const errors = [];
  for (const scope of scopes ?? []) {
    if (typeof scope !== "string") { errors.push(unmappedScopeError(String(scope))); continue; }
    const [platform] = scope.split(":");
    const row = GITHUB_SCOPES[scope];
    if (row) { const [perm, level] = row; if (permissions[perm] !== "write") permissions[perm] = level; continue; }
    if (platform === "github") { errors.push(unmappedScopeError(scope)); continue; }
    errors.push(`scope "${scope}" is for platform "${platform}", and v0.1 deploys to github only — see spec/manifest.md, "Open questions"`);
  }
  return { permissions, errors };
}

// One line for humans and for the audit: "contents:write, metadata:read".
export const describePermissions = (p) => Object.entries(p).map(([k, v]) => `${k}:${v}`).sort().join(", ");
