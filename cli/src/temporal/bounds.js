// The two clocks this runtime stops things with, and nothing else in the file.
//
// WHY A FILE OF ITS OWN. These were declared in temporal/env.js, and the hour
// was ALSO written out again as a literal in temporal/workflows.js, as the
// fallback for a run started without one. So the bound had two homes: an
// operator who moved the declaration moved it for the runs that carry it in
// their input and not for the rest, and nothing said so. On 2026-11-02 that
// hour killed nineteen runs on this company's host, and "change it in env.js"
// was an answer that would have looked applied and not been.
//
// It is not env.js's two constants moved for tidiness. A workflow is bundled
// into a deterministic sandbox, so it may not import a module that reaches a
// disk, a socket or a clock at load time — env.js reads process.env and
// dynamically imports node:net, and a workflow importing it for one number
// would be importing all of that. A file holding two integer literals can be
// imported from either side without that question being asked, which is what
// makes one declaration possible at all.
//
// Both are overridable per box ($EPITO_RUN_TIMEOUT_MS, $EPITO_WINDOW_MS);
// temporal/env.js is where that reading happens and it re-exports these, so
// every caller that already knew where to look still finds them there.
export const DEFAULT_RUN_TIMEOUT_MS = 60 * 60 * 1000;
export const DEFAULT_WINDOW_MS = 4 * 60 * 60 * 1000;
