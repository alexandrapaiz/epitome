#!/usr/bin/env node --test
// Unit tests for `epito deploy`'s pure parts: the App manifest it builds, the
// page it serves, and the principal record it keeps. Run with:
//
//   node --test test/unit-deploy.mjs      # from cli/
//
// A separate file from unit.mjs deliberately: the end-to-end flow is
// test/smoke-deploy.sh, and what is left here is the handful of functions that
// decide what GitHub is ASKED for. Those are worth pinning one by one, because
// every one of them is a place where an App could quietly be created wider
// than the manifest that describes it.
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync, mkdirSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { appNameFor, appManifestFor, formPage, EPITO_HOME, readPrincipals, writePrincipals, recordInstallation, resolveAgent } from "../src/deploy.js";
import { permissionsFor } from "../src/lib/identity.js";

const temps = [];
const temp = () => { const d = mkdtempSync(join(tmpdir(), "epito-deploy-unit-")); temps.push(d); return d; };
process.on("exit", () => { for (const d of temps) rmSync(d, { recursive: true, force: true }); });

test("the App name is the agent plus the repo owner, inside GitHub's 34-char cap", () => {
  assert.equal(appNameFor("pm", "alexandrapaiz/epitome"), "pm-alexandrapaiz");
  // Globally unique across GitHub is why the suffix exists at all: "pm" alone
  // is taken and always will be.
  assert.notEqual(appNameFor("pm", "acme/roster"), appNameFor("pm", "other/roster"));
  const long = appNameFor("a-very-long-seat-name-indeed", "an-organisation-with-a-long-name");
  assert.equal(long.length, 34, "GitHub refuses a name over 34 characters");
});

test("a manifest with no repo still yields a name rather than a dangling dash", () => {
  assert.equal(appNameFor("solo", undefined), "solo");
});

test("the App's homepage is the repo it works in, or this product's own source", () => {
  // Whatever goes in `url` sits on the App's settings page for as long as the
  // App exists, and the operator never typed it. With a repo it is that repo.
  const withRepo = appManifestFor({
    name: "historian", repo: "acme/roster", permissions: { contents: "write" },
    redirectUrl: "http://127.0.0.1:1/callback",
  });
  assert.equal(withRepo.url, "https://github.com/acme/roster");
  // Without one it used to be `https://epito.me`, a name this company does not
  // own and which redirects to a page selling it. Pinned as a host rather than
  // as a string, so the next edit to this fallback has to point somewhere the
  // package already points too.
  const noRepo = appManifestFor({
    name: "solo", permissions: { contents: "write" },
    redirectUrl: "http://127.0.0.1:1/callback",
  });
  assert.equal(noRepo.url, EPITO_HOME);
  assert.equal(new URL(noRepo.url).host, "github.com");
});

test("the permissions in the App manifest ARE the manifest's scopes, mapped", () => {
  const permissions = permissionsFor(["github:contents", "github:issues"]);
  const shape = appManifestFor({
    name: "historian", repo: "acme/roster", permissions,
    redirectUrl: "http://127.0.0.1:1234/callback",
  });
  assert.deepEqual(shape.default_permissions, { contents: "write", issues: "write" });
  // Rule 2 is "scopes are the ceiling", and this is the one place the ceiling
  // is set for the life of the App: a permission not in the file cannot be in
  // the App, because there is no other input.
  assert.equal(Object.keys(shape.default_permissions).length, 2);
});

test("the App subscribes to no events and declares no webhook", () => {
  const shape = appManifestFor({
    name: "historian", repo: "acme/roster", permissions: { contents: "write" },
    redirectUrl: "http://127.0.0.1:1234/callback",
  });
  assert.deepEqual(shape.default_events, []);
  assert.equal("hook_attributes" in shape, false,
    "triggers are `epito run`'s job; an App that declares a hook URL nobody serves is a dead endpoint forever");
});

test("an App is private to its owner unless the operator says otherwise", () => {
  const base = { name: "h", repo: "acme/roster", permissions: { contents: "write" }, redirectUrl: "http://127.0.0.1:1/callback" };
  assert.equal(appManifestFor(base).public, false);
  assert.equal(appManifestFor({ ...base, isPublic: true }).public, true);
});

test("the redirect is this deploy's own loopback port, never a hosted one", () => {
  const shape = appManifestFor({
    name: "h", repo: "acme/roster", permissions: { contents: "write" },
    redirectUrl: "http://127.0.0.1:47481/callback",
  });
  assert.match(shape.redirect_url, /^http:\/\/127\.0\.0\.1:\d+\/callback$/);
});

test("the form page carries the state, and an org posts to the org's form", () => {
  const shape = appManifestFor({ name: "h", repo: "acme/roster", permissions: { contents: "write" }, redirectUrl: "http://127.0.0.1:1/callback" });
  const personal = formPage({ manifest: shape, state: "abc123", org: null });
  assert.match(personal, /action="https:\/\/github\.com\/settings\/apps\/new\?state=abc123"/);
  const orgPage = formPage({ manifest: shape, state: "abc123", org: "acme inc" });
  assert.match(orgPage, /organizations\/acme%20inc\/settings\/apps\/new\?state=abc123/);
});

test("the page escapes the manifest it embeds", () => {
  // The App name reaches this page from a file on disk and leaves it inside an
  // HTML attribute. `--app-name '"><script>'` must not become markup.
  const shape = appManifestFor({
    name: "h", repo: "acme/roster", permissions: { contents: "write" },
    redirectUrl: "http://127.0.0.1:1/callback", appName: `x"><script>alert(1)</script>`,
  });
  const page = formPage({ manifest: shape, state: "s", org: null });
  assert.equal(page.includes("<script>alert(1)"), false);
  assert.match(page, /&lt;script&gt;/);
});

test("the installation for the manifest's repo is always first in the record", () => {
  // lib/identity.js reads installations[0] when a mint does not discover one
  // itself, so an agent installed on two repositories must mint for the one
  // its manifest names.
  const record = { agent: "pm", installations: [{ repo: "acme/other", installationId: "11" }] };
  recordInstallation(record, "acme/roster", 4242);
  assert.deepEqual(record.installations[0], { repo: "acme/roster", installationId: "4242" });
  assert.equal(record.installations.length, 2);
  // Re-recording the same repo updates it rather than growing the list.
  recordInstallation(record, "acme/roster", 4343);
  assert.equal(record.installations.length, 2);
  assert.equal(record.installations[0].installationId, "4343");
});

test("principals round-trip, and a machine with no store reads as empty", () => {
  const dir = temp();
  assert.deepEqual(readPrincipals(dir), []);
  mkdirSync(join(dir, ".epito"), { recursive: true });
  const cwd = process.cwd();
  process.chdir(dir);
  try {
    writePrincipals([{ agent: "pm", provider: "github-app", externalId: "1" }]);
  } finally { process.chdir(cwd); }
  const back = readPrincipals(dir);
  assert.equal(back.length, 1);
  assert.equal(back[0].agent, "pm");
  // Rule 1's line in the store: the record is safe to read aloud.
  assert.equal(readFileSync(join(dir, ".epito/principals.json"), "utf8").includes("PRIVATE KEY"), false);
});

test("a principals.json written as a bare array still reads — the store predates the wrapper", () => {
  const dir = temp();
  mkdirSync(join(dir, ".epito"), { recursive: true });
  writeFileSync(join(dir, ".epito/principals.json"), JSON.stringify([{ agent: "pm", externalId: "9" }]));
  assert.equal(readPrincipals(dir)[0].externalId, "9");
});

// The composition assertion: every seat shape the frozen spec blesses is a
// shape `epito deploy` can actually provision. #28 froze v0.1 against these
// three fixtures and #36 built deploy; they were separate branches, so until
// they met nothing checked that the shapes the spec holds up as the three real
// ways to be an agent all map to a GitHub App. The event responder is the one
// worth having: it is the only shape whose scopes are not the builder's pair,
// and an unmapped scope is a refusal AFTER a human has been sent to a browser.
test("every seat shape in the frozen spec is a shape deploy can provision", () => {
  const shapes = ["daily-builder", "weekly-writer", "event-responder"];
  for (const shape of shapes) {
    const dir = fileURLToPath(new URL(`./fixtures/shapes/${shape}/`, import.meta.url));
    const { manifest } = resolveAgent(undefined, dir);
    const perms = permissionsFor(manifest.identity.scopes);
    assert.ok(
      Object.keys(perms).length > 0,
      `${shape}: [identity].scopes maps to no GitHub App permission, so deploy would refuse a shape the spec blesses`,
    );
    const app = appManifestFor({
      name: manifest.agent.name,
      repo: manifest.runtime.repo,
      permissions: perms,
      redirectUrl: "http://127.0.0.1:1/callback",
    });
    assert.deepEqual(app.default_permissions, perms, `${shape}: the App would not carry the manifest's scopes`);
    assert.deepEqual(app.default_events, [], `${shape}: an identity subscribes to nothing`);
    assert.ok(app.name.length <= 34, `${shape}: App name over GitHub's cap: ${app.name}`);
  }
});
