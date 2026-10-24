// The line that installs this CLI, in one place.
//
// The published package is not called `epito`. npm refused that name as a
// typosquat of `exit` and `pino` on 2026-10-23, so it is `epito-cli` while the
// BINARY is still `epito` — the first time in this product's life that the
// install line and the command are different words. Two refusals had the old
// line spelled into them, which made them worse than refusals with no fix at
// all: the old line does not fail on a typo the reader can see, it 404s on the
// registry, which reads as "this product does not exist."
//
// Compiled in rather than read from `package.json`, because the refusal that
// needs this line most is the one reporting that `package.json` could not be
// read (`src/index.js`): resolving the name from the file whose absence is
// being announced would print nothing, or crash inside the handler for a
// crash. So the constant is the source of truth for what the product SAYS,
// `package.json`'s `name` is the source of truth for what npm SERVES, and
// `test/unit.mjs` asserts they are the same word — which turns the next
// rename that forgets this file into a failing test instead of a refusal that
// sends its reader to a registry page for a package nobody published.
export const PACKAGE = "epito-cli";

// Why `i -g` and not `install --global`: this is the line a reader pastes, and
// it is the line the README's front page pastes too (test/stranger.sh asserts
// the page's install line names this package). One spelling, both places.
export const INSTALL = `npm i -g ${PACKAGE}`;
