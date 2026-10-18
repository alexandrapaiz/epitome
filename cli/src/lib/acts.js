// Who does this seat act as on THIS box?
//
// `epito doctor` answers "would a run on this box start". It does not answer
// the question the product exists for: and whose name would the pull request
// open under. Those are different questions with different failures, and the
// second one is invisible in every outcome anyone looks at — a seat with no
// App of its own runs green, opens its PR as whatever human credential the box
// holds, and nothing anywhere says which of the two happened.
//
// The run path decides it in one place (src/lib/identity.js, loadPrincipal and
// mintForRun) and this is its reader, not a second copy of its rules:
//
//   1. `.epito/principals.json` + `.epito/keys/<agent>.pem` — what `epito
//      deploy` writes on a laptop
//   2. `$EPITO_APP_ID_<SEAT>` with either `$EPITO_APP_KEY_FILE_<SEAT>` or
//      `$EPITO_APP_KEY_<SEAT>` — what a runtime box has, from the unit's
//      EnvironmentFile
//   3. neither: the pre-identity behaviour, which is legitimate and is the
//      state every seat in this company's own roster is in today
//
// Five answers, and the two in the middle are why this is worth a section:
//
//   own      the seat has an App here, and the key on this box actually signs
//            the JWT the mint starts with. PRs open as the App's own login,
//            which is `<slug>[bot]` and is not always `<name>[bot]` — see
//            `rosterInstalled` below, which is the only half that knows.
//   refused  it has an App here and the mint would fail PERMANENTLY — an
//            unreadable key file, a PEM that is not a PEM, a key that is not
//            RSA, a scope v0.2 cannot mint, an App with no [runtime].repo to
//            scope a token to. mintForRun throws rather than falling back
//            (acting as a human when an operator asked for the agent is the
//            precise thing this product deletes), so the RUN does not start.
//            That makes it a refusal here, by doctor's own contract.
//   half     this box holds PART of an identity for this seat — an App id and
//            no key, a key and no id, a name set to nothing. loadPrincipal
//            reads that as "no App" and the seat silently falls back to the
//            shared credential, which is the one outcome the operator who set
//            those names did not ask for. Same shape and same answer as a
//            road this box has and has wrong (src/lib/router.js): the box has
//            this one and has it wrong, so it is loud.
//   shared   no App, and a GitHub credential does reach its runs through
//            `[runtime].env`. The seat acts as that credential's owner — a
//            human. A report, not a refusal: it is how every seat ran before
//            the identity leg existed, and it still works.
//   none     no App, and no GitHub credential reaches its runs at all. The run
//            starts; its `gh` has nothing to authenticate with. Also a report,
//            for the reason `epito env` gives about absent names: nothing in a
//            manifest says this seat must open a PR, and a seat that only
//            posts to Slack is a seat, so this command does not guess.
//
// What `actsAs` never does: read a key's bytes out loud, print an App id it was
// not given, or reach the network. The `own` check signs a throwaway JWT in
// memory, which is free, offline, and is exactly the step the mint does first.
//
// And the one thing it therefore cannot say, which is the second half of this
// file: an App installed nowhere mints nothing, however valid its key. That
// answer is a network call — `GET /repos/{owner}/{name}/installation` as the
// App, the mint's own next step — so it lives behind `epito doctor --deep`,
// the flag that already means "leave this box". See `rosterInstalled` below.
import { existsSync, readFileSync } from "node:fs";
import { inRepo } from "./where.js";
import { join, resolve } from "node:path";
import {
  loadPrincipal, envNames, appJwt, permissionsFor, installationAt, appAs,
  installUrl, appSettingsUrl,
  PRINCIPALS_PATH, KEYS_DIR, GITHUB_API, noRepoMessage,
} from "./identity.js";
import { holding, HELD, ABSENT, EMPTY } from "./boxenv.js";

export const OWN = "own";
export const REFUSED = "refused";
export const HALF = "half";
export const SHARED = "shared";
export const NONE = "none";

// What `gh` inside a run reads, in its own order of precedence. A run's child
// gets the allowlist (src/lib/runenv.js) plus the names `[runtime].env` asks
// for, so one of these two is in the child's environment only if the manifest
// named it and the box holds it.
export const SHARED_NAMES = ["GH_TOKEN", "GITHUB_TOKEN"];

// The file store, per agent. `epito deploy` writes both halves together; one
// without the other is a store that cannot be read, and loadPrincipal falls
// through it in silence, which is what makes it worth a sentence.
function fileStore(name, dir) {
  const principalsPath = join(dir, PRINCIPALS_PATH);
  const keyPath = join(dir, KEYS_DIR, `${name}.pem`);
  const out = { principalsPath, keyPath, hasFile: existsSync(principalsPath), hasKey: existsSync(keyPath), record: null };
  if (out.hasFile) {
    try {
      const all = JSON.parse(readFileSync(principalsPath, "utf8"));
      out.record = (Array.isArray(all) ? all : all.principals ?? []).find((p) => p.agent === name) ?? null;
    } catch { out.record = null; }
  }
  return out;
}

// One seat, one answer. Pure but for reading the files and the environment the
// run path itself reads, and it reads them through the run path's own function.
//
// `dir` is where the file store is resolved from, and it defaults to the same
// "." that mintForRun defaults to — so this cannot disagree with a run that
// starts in the same directory. On a provisioned host that directory is the
// unit's WorkingDirectory ($BASE/state), which is why the report prints the
// absolute path it looked at rather than claiming there is one true store.
export function actsAs(name, manifest, { env = process.env, dir = "." } = {}) {
  const names = envNames(name);
  const store = fileStore(name, dir);
  const repo = manifest?.runtime?.repo ?? null;
  const declared = manifest?.runtime?.env ?? [];
  // A manifest may name both. The one that decides who the seat acts as is the
  // one this box actually holds (`gh` reads GH_TOKEN first and GITHUB_TOKEN
  // second, and a run's child only ever receives the names the box holds), so
  // a held name outranks the order they are declared in.
  const named = SHARED_NAMES.filter((n) => declared.includes(n));
  const sharedName = named.find((n) => holding(n, env) === HELD) ?? named[0] ?? null;
  const base = {
    agent: name,
    names,
    store: { principals: resolve(store.principalsPath), key: resolve(store.keyPath) },
    shared: sharedName ? { name: sharedName, state: holding(sharedName, env) } : null,
    appId: null, installation: null, source: null, repo,
    // Carried on the row because the online half below compares them against
    // what the installation was actually granted, and a row that had to be
    // paired back up with its manifest is a row two readers can mismatch.
    scopes: manifest?.identity?.scopes ?? [],
  };

  let principal = null;
  try {
    principal = loadPrincipal(name, { env, dir });
  } catch (e) {
    // loadPrincipal throws only where it is sure: a principals.json that is
    // not JSON, a $..._KEY_FILE pointing at something this user cannot read.
    // Both are its own sentences, with its own fixes, and this is the command
    // that says them before 06:00 instead of at it.
    return { ...base, state: REFUSED, says: `an identity this box cannot read: ${e.message}`, fix: null };
  }

  if (principal) {
    // The file store's source is resolved against `dir`, so an operator sees
    // WHICH `.epito/` answered — the one in this process's working directory,
    // which on a provisioned host is the unit's WorkingDirectory and not the
    // home directory they are standing in. The environment's source is already
    // absolute in the only sense it has ("$EPITO_APP_ID_PM/...").
    const source = principal.source.startsWith("$") ? principal.source : resolve(principal.source);
    const row = { ...base, appId: principal.appId, installation: principal.installationId, source };
    // The mint's first two steps, done here because both are free and offline:
    // sign the App JWT, and map the manifest's scopes. Either one failing is a
    // mint that never starts, which is a run that never starts.
    try { appJwt(principal.appId, principal.privateKey); }
    catch (e) { return { ...row, state: REFUSED, says: `an App whose mint cannot start: ${e.message}`, fix: null }; }
    try { permissionsFor(manifest?.identity?.scopes ?? []); }
    catch (e) { return { ...row, state: REFUSED, says: `an App whose mint cannot start: ${e.message}`, fix: null }; }
    if (!repo) return { ...row, state: REFUSED, says: `an App whose mint cannot start: ${noRepoMessage(name)}`, fix: null };
    return {
      ...row,
      state: OWN,
      // Every line in this section starts with WHAT the seat acts as and ends
      // with the seats it covers (`epito doctor` prints the "— covers a, b"
      // half), which is the one shape that reads right whether a sentence
      // speaks for one seat or five: a verb agreeing with a list is how the
      // first draft ended up with five near-identical paragraphs.
      says: `its own GitHub App: id ${principal.appId}, from ${source}${principal.installationId ? `, installation ${principal.installationId}` : ", installation discovered from [runtime].repo at mint time"}`,
      fix: null,
    };
  }

  // No principal. Is that because this box was never given one for this seat,
  // or because it was given half of one?
  const half = [];
  // The three names that ARE an identity. `EPITO_INSTALLATION_ID_<SEAT>` is
  // deliberately not among them: it is optional and the mint discovers it from
  // [runtime].repo, so a leftover empty line is not half an identity and must
  // not refuse a run (identity.js reads an empty one as unset for the same
  // reason).
  for (const [role, key] of [["App id", names.id], ["key file", names.keyFile], ["key", names.key]]) {
    const state = holding(key, env);
    if (state === EMPTY) half.push(`$${key} is set here and set to nothing (${role})`);
  }
  const idSet = holding(names.id, env) === HELD;
  const keySet = holding(names.key, env) === HELD || holding(names.keyFile, env) === HELD;
  if (idSet && !keySet) half.push(`$${names.id} is set here and neither $${names.keyFile} nor $${names.key} is — an App id alone signs nothing`);
  if (keySet && !idSet) half.push(`a key is set here ($${holding(names.keyFile, env) === HELD ? names.keyFile : names.key}) and $${names.id} is not — a key alone has no App to be`);
  if (store.record && !store.hasKey) half.push(`${resolve(store.principalsPath)} records an App for this seat and its key is not at ${resolve(store.keyPath)}`);
  if (store.hasKey && !store.record) half.push(`${resolve(store.keyPath)} is a key for this seat and ${resolve(store.principalsPath)} ${store.hasFile ? "does not record an App for it" : "does not exist"}`);
  if (half.length) {
    return {
      ...base,
      state: HALF,
      says: `half an identity, which the runtime reads as none: ${half.join("; ")}`,
      fix: `finish the pair or remove it: this seat needs $${names.id} AND one of $${names.keyFile} (a .pem at 0600, the form a systemd EnvironmentFile can hold) or $${names.key}, or both halves of the file store. As it stands the runtime reads this as "no App" and the seat falls back to whatever else this box gives it — ${sharedName ? `$${sharedName}, a person's credential` : "nothing, since its [runtime].env names no GitHub credential either"} — which is the one outcome setting those names asked it not to do`,
    };
  }

  if (sharedName && base.shared.state === HELD) {
    return {
      ...base,
      state: SHARED,
      says: `the owner of $${sharedName}, a person: the name is in [runtime].env and held here, and no App on this box replaces it`,
      fix: null,
    };
  }
  return {
    ...base,
    state: NONE,
    says: sharedName
      ? `nobody: no App on this box, and $${sharedName} is named in [runtime].env and not set here, so nothing reaches the run`
      : `nobody: no App on this box, and [runtime].env names neither ${SHARED_NAMES.join(" nor ")}, so a run's child gets no GitHub credential at all`,
    fix: null,
  };
}

// The fix for `shared` and `none`, said ONCE however many seats are in that
// state, and that is the whole reason it is a constant rather than a sentence
// per row: the two names are mechanical (the seat's `[agent].name` uppercased,
// `-` as `_`, which is envNames above), so an operator needs the rule once,
// not five paragraphs that differ by one word. The first draft of this section
// printed it per seat and buried itself — the same mistake `epito doctor`'s
// executor block already learned not to make.
export const IDENTITY_FIX =
  `a seat acts as itself when this box holds two names for it — $EPITO_APP_ID_<SEAT> and $EPITO_APP_KEY_FILE_<SEAT> ` +
  `(the seat's name uppercased, - as _; the key a .pem at 0600, which is the form a systemd EnvironmentFile can hold). ` +
  `Then its runs mint their own short-lived token, clone and push as themselves, and open PRs as the App's own login — ` +
  `which is <slug>[bot], usually the seat's name and not guaranteed to be, because an App name is unique across the whole of GitHub. ` +
  `${inRepo('docs/deploy/README.md', '"Giving an agent its own identity"')} is the long version, and \`epito deploy\` is the laptop route. ` +
  `The pre-identity answer, which is what every seat did before this leg existed, is to name ${SHARED_NAMES[0]} in the seat's [runtime].env and hold it here — then its PRs open as that token's owner`;

// The whole roster, in roster order, plus the three roll-ups a report needs.
// `refusals` is the only one the exit code may be read off: a half identity and
// a mint that cannot start are facts about this box that a run trips over, and
// `shared`/`none` are how this product worked before the identity leg and are
// nobody's error.
export function rosterActs(roster, { env = process.env, dir = "." } = {}) {
  const seats = [];
  for (const [agent, entry] of roster) {
    seats.push(actsAs(agent, entry?.manifest ?? entry, { env, dir }));
  }
  return {
    seats,
    own: seats.filter((s) => s.state === OWN),
    refusals: seats.filter((s) => s.state === REFUSED || s.state === HALF),
    shared: seats.filter((s) => s.state === SHARED),
    none: seats.filter((s) => s.state === NONE),
  };
}

// --- the half that has to leave the box -----------------------------------
// `own` above means: this box holds an App for this seat, and the key here
// actually signs the JWT a mint starts with. That is everything about the mint
// that is knowable offline, and it stops one step short of the thing an
// operator is actually asking — because the mint's next step is
//
//     GET /repos/{owner}/{name}/installation     (as the App)
//
// and an App installed nowhere mints nothing, however valid its key. Until
// that question is asked, "a run on this box would start" is a prediction with
// a hole in it the exact size of the most common setup mistake there is:
// creating the App and not installing it on the repository.
//
// So this is the online half, and it costs nothing — no model call, no token
// minted, no ledger line, one GET per (App, repo) pair in the roster. It sits
// behind `--deep` because that flag already means "leave this box", not
// because it is expensive.
//
// Which answers refuse, and why that line is not this file's to draw: a mint
// failure is either the kind that passes (GitHub throttling, a network blip)
// or the kind that never will, and identity.js already marks the difference —
// `permanent` on the error, because the `clone` activity retries and must not
// retry an App that is installed nowhere. This reads that flag rather than
// re-deciding by status code, so a preflight cannot call permanent what the
// run path treats as transient:
//
//   installed    GitHub named an installation on [runtime].repo, and either
//                this box names no installation id (the mint discovers this
//                one) or the id it names is that one. ✓
//   mismatch     installed, and this box tells its runs to mint from a
//                DIFFERENT id. The mint uses the id the box names rather than
//                discovering one, so GitHub answers it 404 — identity.js
//                calls that permanent too. A refusal, and the one answer here
//                that is per seat rather than per App.
//   ungranted    installed, and the installation was granted LESS than
//                [identity].scopes maps to — contents:read where the manifest
//                needs contents:write. An installation can only hand out
//                permissions the App was granted, so GitHub answers the mint
//                422. Free to check: the installation GitHub just described
//                carries its own permissions, so this is a comparison and not
//                a second request.
//   refused      GitHub refused permanently: not installed there (404), or an
//                App id and a private key that are not from the same App
//                (401). Two sentences, two fixes, both identity.js's own
//                words verbatim — a preflight that paraphrases the run's
//                refusal is a preflight an operator has to translate.
//   unreachable  anything else: no route to GitHub, a 5xx, a rate limit, or
//                no answer inside the deadline below. A report, not a
//                refusal, for the same reason the run path retries it.
export const INSTALLED = "installed";
export const MISMATCH = "mismatch";
export const UNGRANTED = "ungranted";
export const GH_REFUSED = "refused";
export const UNREACHABLE = "unreachable";

// A preflight is a thing an operator runs while standing in front of a box,
// and a half-open socket to api.github.com would otherwise hang it for the
// length of the kernel's own patience. Five seconds, said in the report when
// it is spent: the mint itself has no deadline (it is a run, and the engine
// retries it), which is the right trade there and the wrong one here.
export const INSTALL_DEADLINE_MS = 5000;

const withDeadline = (p, ms) => {
  if (!(ms > 0)) return p;
  let timer;
  const bell = new Promise((_, reject) => {
    timer = setTimeout(() => reject(new Error(`GitHub did not answer within ${ms / 1000}s, which is as long as a preflight waits on purpose (the same look is instant on a box with a route to api.github.com, and the mint at 06:00 is the thing that genuinely has to wait). Fix: check this box's route to ${GITHUB_API}, then run this again.`)), ms);
  });
  // Deliberately NOT unref'd, and the first draft was: an unref'd timer does
  // not hold the event loop open, so a lookup that never settles — which is
  // precisely the case this exists for — leaves the loop with nothing to do
  // and the await never resolves. (node --test says it in those words:
  // "Promise resolution is still pending but the event loop has already
  // resolved". It is the test for this function that found it.) The timer
  // cannot outlive the race either way, because `finally` clears it the
  // moment either side settles.
  return Promise.race([p, bell]).finally(() => clearTimeout(timer));
};

// One call, per (App, repo). The answer depends on nothing else: two seats
// sharing an App and a repository share an installation, and asking twice
// would print the same proof twice and spend two requests to do it.
// The App's own name, which is the one fact in this section that no manifest
// holds and nothing offline can reach: `GET /app`, as the App, with the same
// JWT the installation lookup just used. It buys two sentences nothing else
// can write — the page that performs the fix a refusal names, and the login a
// pull request will actually open AS, which is the App's slug and not
// necessarily the seat's name.
//
// It never changes a verdict. A failure here means a link missing from a
// sentence that was already complete and already correct, so it degrades to
// null and the report reads exactly as it did before this existed — the same
// trade `mintToken` makes about the commit identity, for the same reason: an
// avatar is not worth a refusal.
//
// Not asked at all in two cases, both of them "GitHub has already answered
// this": a 401 is GitHub rejecting these very credentials, so /app would spend
// a request to be told so a second time, and a GitHub with no route from here
// has no route for either call. The deadline is the operator's patience and
// not a per-request budget, so this shares the one above rather than adding
// five seconds of its own.
async function describeApp(row, jwt, answer, { describe, deadline }) {
  if (answer.state === UNREACHABLE || answer.status === 401) return null;
  try { return await withDeadline(describe(row.appId, jwt), deadline); }
  catch { return null; }
}

async function askGitHub(row, { env, dir, lookup, describe, deadline }) {
  // `row.state === OWN` is the caller's contract and it is what makes the next
  // two lines safe: loadPrincipal answered for this seat, its key signed a JWT
  // already, and [runtime].repo is set. Read through loadPrincipal rather than
  // off the row because the row deliberately carries no key.
  const principal = loadPrincipal(row.agent, { env, dir });
  const jwt = appJwt(principal.appId, principal.privateKey);
  const answer = await askInstallation(row, jwt, { lookup, deadline });
  return { ...answer, app: await describeApp(row, jwt, answer, { describe, deadline }) };
}

async function askInstallation(row, jwt, { lookup, deadline }) {
  try {
    const inst = await withDeadline(lookup(jwt, row.repo), deadline);
    // A 200 with no id in it. Not reachable through api.github.com, and this
    // is the one call in the preflight whose endpoint an operator can move
    // ($EPITO_GITHUB_API, for GitHub Enterprise) — and the id is the whole
    // answer, so the honest report is that it was not given rather than a
    // sentence with a hole where the number goes.
    if (!inst?.id) return { state: UNREACHABLE, says: `GitHub answered about ${row.repo} without an installation id, and the id is the whole answer. Fix: if $EPITO_GITHUB_API points at a GitHub Enterprise host, check it is the API root (/api/v3) and not the web root.` };
    return { state: INSTALLED, installation: String(inst.id), permissions: inst.permissions ?? null };
  } catch (e) {
    // The flag, not the status: see the note above.
    if (e.permanent) return { state: GH_REFUSED, status: e.status ?? null, says: e.message };
    return { state: UNREACHABLE, status: e.status ?? null, says: e.message };
  }
}

// GitHub's three levels, ranked, so "the App has contents:read where the
// manifest needs contents:write" is a comparison rather than a string match.
// An unknown level ranks 0 and therefore reads as short of anything, which is
// the safe direction for a preflight: it reports a mint it is not sure of
// rather than ticking one.
const LEVELS = { read: 1, write: 2, admin: 3 };
const short = (granted, need) => (LEVELS[granted] ?? 0) < (LEVELS[need] ?? 0);

// What the manifest's scopes need against what the installation was granted.
// Returns the shortfalls, or [] — including when GitHub described the
// installation without a permissions object at all, which is the one case
// where the honest answer is to say nothing rather than to guess.
export function grantGap(scopes, granted) {
  if (!granted) return [];
  let need;
  // Unmappable scopes are `actsAs`'s own refusal (offline, before this ever
  // runs), so a throw here would be unreachable — but the ceiling is the one
  // rule that must not fail open, so this says nothing rather than claiming
  // a grant is sufficient for a mint that will not be attempted.
  try { need = permissionsFor(scopes); } catch { return []; }
  return Object.entries(need)
    .filter(([name, level]) => short(granted[name], level))
    .map(([name, level]) => ({ permission: name, need: level, granted: granted[name] ?? null }));
}

// Where the id this box names actually comes from, so a fix names the thing
// the operator would edit. Two stores, one each (identity.js, loadPrincipal).
function idSource(row) {
  return row.source?.startsWith("$")
    ? `$${row.names.installation}`
    : `the "installations" entry for "${row.agent}" in ${row.store.principals}`;
}

// One seat's verdict: the call's answer, plus the one fact that is this seat's
// own rather than its App's — which installation id this box tells its runs
// to mint from.
// A line printed UNDER a row, which is not a second fix: the page that
// performs the fix the sentence already named, or the one fact about a healthy
// App that is worth a line of its own. Kept separate from `fix` so a refusal
// never reads as having two of them, and so identity.js's own refusal wording
// stays verbatim rather than being rewritten to hold a URL.
const under = (...lines) => lines.filter(Boolean);

function verdictFor(row, call) {
  const app = call.app ?? null;
  const base = {
    agent: row.agent, appId: row.appId, repo: row.repo,
    declared: row.installation ?? null, installation: call.installation ?? null,
    status: call.status ?? null,
    // The login a pull request from this seat actually opens as, where GitHub
    // was asked and answered. Null is "not asked or not answered", never a
    // guess: `<name>[bot]` is the usual case and guessing it here is exactly
    // the promise this pass exists to stop making.
    login: app?.login ?? null,
    slug: app?.slug ?? null,
    // Always an array, including on the answers that have nothing to put in
    // it: a reader that has to tell [] from undefined is a reader that will
    // get it wrong once. A mismatch is the clearest case — it is fixed by
    // editing this box, so there is nothing to open.
    under: [],
  };
  if (call.state === INSTALLED) {
    // Mismatch before grant, deliberately: with the wrong id the mint never
    // reaches the permission check, so naming the grant first would be naming
    // the second thing an operator would have to fix.
    const named = row.installation ? String(row.installation) : null;
    if (named && named !== call.installation) {
      return {
        ...base,
        state: MISMATCH,
        says: `an App installed on ${row.repo} as installation ${call.installation}, while this box tells its runs to mint from ${named} instead; the mint uses the id the box names rather than discovering one, so GitHub refuses it (404 if no such installation exists, 422 if one does and cannot see ${row.repo}) and the run stops at its first step`,
        fix: `unset ${idSource(row)} and let the mint discover the installation from [runtime].repo, which is what it does when nothing names one — or correct it to ${call.installation}, the installation GitHub says this App has on ${row.repo}`,
      };
    }
    const gaps = grantGap(row.scopes ?? [], call.permissions);
    if (gaps.length) {
      const asked = gaps.map((g) => `${g.permission}:${g.need}`).join(", ");
      return {
        ...base,
        state: UNGRANTED,
        gaps,
        says: `an App installed on ${row.repo} as installation ${call.installation} and granted less there than its [identity].scopes need: ${gaps.map((g) => `${g.permission} is ${g.granted ?? "not granted at all"} and the manifest needs ${g.need}`).join("; ")}. An installation can only hand out permissions the App was granted, so GitHub answers the mint 422`,
        fix: `grant the App ${asked} and accept the request on ${row.repo} (its owner does this once, from the App's permissions page), or drop the scope from this agent's agent.toml — scopes are the ceiling, so the mint refuses rather than quietly minting a token narrower than the manifest promises`,
        // "the App's permissions page" is a real page and an operator should
        // not have to find it. Which path it is depends on who owns the App,
        // which is why `GET /app` is read for its owner and not only its slug:
        // an org-owned App is not reachable under /settings/apps at all.
        under: under(app && `The page that does it: ${appSettingsUrl(app)}`),
      };
    }
    return {
      ...base,
      state: INSTALLED,
      // No em dash in any of these sentences: doctor appends "— covers a, b"
      // to every line in this block, and a second dash inside the sentence is
      // where a reader loses which half the list belongs to.
      says: `its own GitHub App, installed on ${row.repo} as installation ${call.installation}, which is ${named ? "the id this box names for it" : "the id its runs discover from [runtime].repo, since nothing on this box names one"}${call.permissions ? `, and granted there everything its [identity].scopes ask to mint` : ""}`,
      fix: null,
      // The one thing worth a line under a ✓ row. It is printed because it is
      // the question the whole identity leg exists to answer and the only
      // place in this product that can answer it truthfully: an App name is
      // unique across GitHub, so a seat called `pm` whose App had to be
      // created as `asc-pm` opens its pull requests as `asc-pm[bot]`, and
      // every other sentence here would have told the operator `pm[bot]`.
      under: under(app && `Its pull requests there open as ${app.login}, which is this App's own login: usually the seat's name, and whatever GitHub actually gave the App when it was created.`),
    };
  }
  if (call.state === GH_REFUSED) {
    return {
      ...base,
      state: GH_REFUSED,
      says: `an App this box cannot mint with: ${call.says}`,
      fix: null,
      // identity.js's 404 says "install the App on owner/name (its owner does
      // this once)" — the instruction, and the thing an owner then has to go
      // and find. This is where it is: the App's install page, which is a form
      // (choose the account, choose the repositories, press Install), so the
      // link performs nothing by being followed.
      //
      // Only on the 404. A 401 is an App id and a key that are not from the
      // same App, and the same credentials cannot read `GET /app` either, so
      // there is no slug to build a page out of — its fix stays the sentence
      // identity.js already writes, which is to re-copy both.
      under: under(app && call.status === 404 && `The page that does it: ${installUrl(app.slug)}`),
    };
  }
  return {
    ...base,
    state: UNREACHABLE,
    says: `an App whose installation this box could not ask about: ${call.says}`,
    fix: null,
  };
}

// The roster's `own` seats, asked. Takes the rows `actsAs` already produced —
// so the two halves cannot disagree about which seats have an App — and
// returns one verdict per such seat, in roster order. A roster with no `own`
// seat makes no request and returns nothing, which is this company's own
// roster today.
export async function rosterInstalled(rows, { env = process.env, dir = ".", lookup = installationAt, describe = appAs, deadline = INSTALL_DEADLINE_MS } = {}) {
  const calls = new Map();
  const out = [];
  for (const row of rows) {
    if (row.state !== OWN) continue;
    const key = `${row.appId}|${row.repo}`;
    if (!calls.has(key)) calls.set(key, await askGitHub(row, { env, dir, lookup, describe, deadline }));
    out.push({ ...verdictFor(row, calls.get(key)), key });
  }
  return out;
}

// Read off one list, for the same reason doctor's own verdict is: two answers
// to "would the mint start" is one too many.
export const INSTALL_REFUSES = new Set([MISMATCH, UNGRANTED, GH_REFUSED]);

// What `--deep` would prove and a plain run cannot, said in the one place
// doctor prints its "not proven" line. Named for the seats it is true of: a
// roster with no App of its own has nothing here to prove.
export const INSTALL_UNPROVEN =
  "whether each App is installed on the repository it would mint for, was granted there what its [identity].scopes ask to mint, and which login its pull requests actually open as — the key signing is offline and free, and all three are questions only GitHub can answer";
