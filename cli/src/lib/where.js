// Where this repository is, for the handful of messages that name a file only
// it holds.
//
// `epito validate` sets the bar for every message in this product: name the
// rule broken, in the product's own vocabulary, with the fix in the message.
// Seven messages named their fix as a bare path into this repository —
// `deploy/provision-host.sh`, `docs/deploy/README.md` — which is a fix with no
// page to find it for the reader who matters most here: somebody who ran `npm
// i -g epito`, has no checkout at all, and cannot even guess which repository
// that path is relative to. A path is a reference only when it comes with
// where to find it.
//
// One constant, because a repository that moves should be one edit and not a
// grep, and because `test/stranger.sh` holds the rule from the other side: a
// user-facing line naming a repo path and no locator fails that suite.
export const REPO = "github.com/alexandrapaiz/epitome";

// "docs/deploy/README.md in github.com/alexandrapaiz/epitome"
export const inRepo = (path) => `${path} in ${REPO}`;
