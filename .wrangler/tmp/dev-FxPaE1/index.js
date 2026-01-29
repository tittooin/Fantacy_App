var __defProp = Object.defineProperty;
var __name = (target, value) => __defProp(target, "name", { value, configurable: true });

// .wrangler/tmp/bundle-67ZTK2/checked-fetch.js
var urls = /* @__PURE__ */ new Set();
function checkURL(request, init) {
  const url = request instanceof URL ? request : new URL(
    (typeof request === "string" ? new Request(request, init) : request).url
  );
  if (url.port && url.port !== "443" && url.protocol === "https:") {
    if (!urls.has(url.toString())) {
      urls.add(url.toString());
      console.warn(
        `WARNING: known issue with \`fetch()\` requests to custom HTTPS ports in published Workers:
 - ${url.toString()} - the custom port will be ignored when the Worker is published using the \`wrangler deploy\` command.
`
      );
    }
  }
}
__name(checkURL, "checkURL");
globalThis.fetch = new Proxy(globalThis.fetch, {
  apply(target, thisArg, argArray) {
    const [request, init] = argArray;
    checkURL(request, init);
    return Reflect.apply(target, thisArg, argArray);
  }
});

// workers/index.js
var corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type"
};
var lastWorkingMatchEndpoint = null;
var workers_default = {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }
    if (url.pathname === "/api/refresh-matches") {
      return handleRefreshMatches(env);
    }
    if (url.pathname === "/api/get-matches") {
      return handleGetMatches(env);
    }
    if (url.pathname.startsWith("/api/scorecard/")) {
      const matchId = url.pathname.split("/").pop();
      return handleGetScorecard(matchId, env);
    }
    if (url.pathname === "/api/diag") {
      return handleGlobalDiag(env);
    }
    return new Response("Fantasy Cricket API - Ready", {
      headers: { ...corsHeaders, "Content-Type": "text/plain" }
    });
  },
  /**
   * Scheduled handler - runs every 5 minutes
   * Hindi: Har 5 minute mein automatically chalega
   */
  async scheduled(event, env, ctx) {
    console.log("\u23F0 Scheduled poll triggered - DISABLED to save quota");
  }
};
async function handleRefreshMatches(env) {
  try {
    console.log("\u{1F504} Manual refresh triggered");
    const matches = await fetchFromRapidAPI("/cricket-schedule", env);
    if (!matches || matches.length === 0) {
      return jsonResponse({ success: false, message: "No matches found" });
    }
    await saveToFirestore("matches", matches, env);
    return jsonResponse({
      success: true,
      total_matches: matches.length,
      message: `Refreshed ${matches.length} matches. Scorecards will update in background.`
    });
  } catch (error) {
    console.error("\u274C Refresh error:", error);
    return jsonResponse({ success: false, error: error.message });
  }
}
__name(handleRefreshMatches, "handleRefreshMatches");
async function handleGetMatches(env) {
  try {
    const matches = await getFromFirestore("matches", env);
    return jsonResponse({ success: true, matches });
  } catch (error) {
    return jsonResponse({ success: false, error: error.message });
  }
}
__name(handleGetMatches, "handleGetMatches");
async function handleGetScorecard(matchId, env) {
  try {
    const scorecard = await fetchFromRapidAPI(`/scorecard?matchId=${matchId}`, env);
    if (scorecard) {
      await saveToFirestore(`scorecards`, { id: matchId, ...scorecard }, env);
      return jsonResponse({ success: true, scorecard });
    }
    return jsonResponse({ success: false, message: "Scorecard not found" });
  } catch (error) {
    return jsonResponse({ success: false, error: error.message });
  }
}
__name(handleGetScorecard, "handleGetScorecard");
async function fetchFromRapidAPI(endpoint, env, retryCount = 0) {
  let targetEndpoint = endpoint;
  const isProbe = retryCount > 0;
  if (endpoint.includes("matches") && !isProbe) {
    targetEndpoint = lastWorkingMatchEndpoint || "/matches/list";
    console.log(`\u{1F9E0} Match routing: ${targetEndpoint}`);
  }
  const host = env.RAPID_API_HOST || "free-cricbuzz-cricket-api.p.rapidapi.com";
  const url = `https://${host}${targetEndpoint}`;
  console.log(`\u{1F4E1} [RapidAPI] GET ${url} (Attempt ${retryCount + 1})`);
  try {
    const response = await fetch(url, {
      headers: {
        "x-rapidapi-key": env.RAPID_API_KEY,
        "x-rapidapi-host": host,
        "User-Agent": "Mozilla/5.0"
      }
    });
    const status = response.status;
    const statusText = response.statusText;
    if (status === 429) {
      await response.body?.cancel();
      if (retryCount < 1) {
        const waitTime = endpoint.includes("scorecard") ? 3e4 : 15e3;
        console.log(`\u26A0\uFE0F 429 Rate Limit. Waiting ${waitTime / 1e3}s for retry...`);
        await new Promise((r) => setTimeout(r, waitTime));
        return fetchFromRapidAPI(targetEndpoint, env, retryCount + 1);
      }
      throw new Error("RapidAPI Rate Limit Exceeded (429)");
    }
    if (status === 404 && endpoint.includes("matches") && !isProbe) {
      const errorBody = await response.text();
      console.log(`\u{1F50D} 404 on ${targetEndpoint}. Body: ${errorBody.substring(0, 100)}`);
      console.log(`\u{1F50D} Searching valid match candidates...`);
      const candidates = ["/matches/upcoming", "/matches/list", "/matches", "/live"];
      for (const cand of candidates) {
        if (cand === targetEndpoint) continue;
        try {
          console.log(`\u{1F50E} Probing ${cand}...`);
          const data2 = await fetchFromRapidAPI(cand, env, 1);
          if (data2) {
            console.log(`\u2705 DISCOVERY SUCCESS: Found working endpoint: ${cand}`);
            lastWorkingMatchEndpoint = cand;
            return data2;
          }
        } catch (e) {
          const errorMsg = e.message;
          console.log(`\u274C ${cand} probe failed: ${errorMsg}`);
          if (errorMsg.includes("429")) {
            console.log(`\u{1F3AF} Valid endpoint found via 429 signal: ${cand}`);
            lastWorkingMatchEndpoint = cand;
            return fetchFromRapidAPI(cand, env, 0);
          }
        }
      }
      throw new Error(`Could not discover any working match endpoint (Last: ${targetEndpoint})`);
    }
    if (!response.ok) {
      const errorText = await response.text();
      console.error(`\u274C RapidAPI Error ${status} (${statusText}):`, errorText);
      throw new Error(`RapidAPI error: ${status} - ${errorText.substring(0, 50)}`);
    }
    const data = await response.json();
    const actualData = data.response || data;
    const quota = {
      remaining: response.headers.get("x-ratelimit-requests-remaining"),
      limit: response.headers.get("x-ratelimit-requests-limit")
    };
    console.log(`\u2705 [RapidAPI] 200 OK - ${targetEndpoint} (Quota: ${quota.remaining}/${quota.limit})`);
    if (endpoint.includes("matches") || endpoint.includes("schedule")) lastWorkingMatchEndpoint = targetEndpoint;
    if (targetEndpoint.includes("scorecard")) return actualData;
    return parseMatches(actualData);
  } catch (error) {
    console.error(`\u{1F4A5} Fetch Exception: ${error.message}`);
    throw error;
  }
}
__name(fetchFromRapidAPI, "fetchFromRapidAPI");
function parseMatches(data) {
  const matches = [];
  try {
    if (data.schedules && Array.isArray(data.schedules)) {
      console.log(`\u{1F4E6} Parsing schedules (${data.schedules.length} days)`);
      for (const item of data.schedules) {
        const day = item.scheduleAdWrapper || item;
        if (day.matchScheduleList && Array.isArray(day.matchScheduleList)) {
          for (const scheduleItem of day.matchScheduleList) {
            const matchInfos = scheduleItem.matchInfo || [];
            if (Array.isArray(matchInfos)) {
              for (const info of matchInfos) {
                matches.push(formatMatch(info));
              }
            } else if (typeof matchInfos === "object") {
              matches.push(formatMatch(matchInfos));
            }
          }
        }
      }
      if (matches.length > 0) return matches;
    }
    const typeMatches = data.typeMatches || data.matches || (Array.isArray(data) ? data : []);
    if (Array.isArray(typeMatches)) {
      for (const type of typeMatches) {
        if (type.seriesMatches) {
          for (const series of type.seriesMatches) {
            if (series.seriesAdWrapper?.matches) {
              for (const match of series.seriesAdWrapper.matches) {
                if (match.matchInfo) {
                  matches.push(formatMatch(match.matchInfo));
                }
              }
            }
          }
        } else if (type.matchInfo) {
          matches.push(formatMatch(type.matchInfo));
        } else if (type.matchId) {
          matches.push(formatMatch(type));
        }
      }
    }
  } catch (error) {
    console.error("\u274C Parse error:", error);
  }
  return matches;
}
__name(parseMatches, "parseMatches");
function formatMatch(info) {
  return {
    id: info.matchId?.toString() || info.id?.toString() || "",
    seriesName: info.seriesName || "Series",
    matchDesc: info.matchDesc || "Match",
    matchFormat: info.matchFormat || "T20",
    team1Name: info.team1?.teamName || "Team 1",
    team1ShortName: info.team1?.teamSName || "T1",
    team1Img: info.team1?.imageId?.toString() || "1",
    team2Name: info.team2?.teamName || "Team 2",
    team2ShortName: info.team2?.teamSName || "T2",
    team2Img: info.team2?.imageId?.toString() || "1",
    startDate: info.startDate ? parseInt(info.startDate) : 0,
    status: info.status || info.state || "Upcoming",
    lastUpdated: Date.now()
  };
}
__name(formatMatch, "formatMatch");
async function saveToFirestore(collection, data, env) {
  const baseUrl = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${collection}`;
  const items = Array.isArray(data) ? data : [data];
  for (const item of items) {
    const docId = item.id || Date.now().toString();
    const url = `${baseUrl}/${docId}?key=${env.FIREBASE_API_KEY}`;
    const fields = {};
    for (const [key, value] of Object.entries(item)) {
      if (typeof value === "string") fields[key] = { stringValue: value };
      else if (typeof value === "number") fields[key] = { integerValue: Math.floor(value).toString() };
      else if (typeof value === "boolean") fields[key] = { booleanValue: value };
      else if (typeof value === "object") fields[key] = { stringValue: JSON.stringify(value) };
    }
    try {
      await fetch(url, {
        method: "PATCH",
        // Upsert
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ fields })
      });
    } catch (e) {
      console.error(`\u274C Firestore Save Error: ${e.message}`);
    }
  }
  return true;
}
__name(saveToFirestore, "saveToFirestore");
async function getFromFirestore(collection, env) {
  const url = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${collection}?key=${env.FIREBASE_API_KEY}`;
  try {
    const response = await fetch(url);
    if (!response.ok) return [];
    const data = await response.json();
    if (!data.documents) return [];
    return data.documents.map((doc) => {
      const item = { id: doc.name.split("/").pop() };
      for (const [key, value] of Object.entries(doc.fields || {})) {
        if (value.stringValue) {
          try {
            item[key] = key.toLowerCase().includes("team") || key === "scorecard" ? JSON.parse(value.stringValue) : value.stringValue;
          } catch {
            item[key] = value.stringValue;
          }
        } else if (value.integerValue) item[key] = parseInt(value.integerValue);
        else if (value.booleanValue) item[key] = value.booleanValue;
      }
      return item;
    });
  } catch (e) {
    console.error(`\u274C Firestore Load Error: ${e.message}`);
    return [];
  }
}
__name(getFromFirestore, "getFromFirestore");
async function handleGlobalDiag(env) {
  const hosts = [
    "free-cricbuzz-cricket-api1.p.rapidapi.com",
    "cricbuzz-cricket.p.rapidapi.com",
    "free-cricbuzz-cricket-api.p.rapidapi.com"
  ];
  const results = {};
  for (const host of hosts) {
    try {
      const url = `https://${host}/matches/list`;
      const res = await fetch(url, {
        headers: {
          "x-rapidapi-key": env.RAPID_API_KEY,
          "x-rapidapi-host": host,
          "User-Agent": "Mozilla/5.0"
        }
      });
      results[host] = {
        status: res.status,
        headers: {
          remaining: res.headers.get("x-ratelimit-requests-remaining"),
          limit: res.headers.get("x-ratelimit-requests-limit")
        }
      };
      await res.body?.cancel();
    } catch (e) {
      results[host] = { error: e.message };
    }
  }
  return jsonResponse({ success: true, results });
}
__name(handleGlobalDiag, "handleGlobalDiag");
function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json"
    }
  });
}
__name(jsonResponse, "jsonResponse");

// C:/Users/tittoo/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/wrangler/templates/middleware/middleware-ensure-req-body-drained.ts
var drainBody = /* @__PURE__ */ __name(async (request, env, _ctx, middlewareCtx) => {
  try {
    return await middlewareCtx.next(request, env);
  } finally {
    try {
      if (request.body !== null && !request.bodyUsed) {
        const reader = request.body.getReader();
        while (!(await reader.read()).done) {
        }
      }
    } catch (e) {
      console.error("Failed to drain the unused request body.", e);
    }
  }
}, "drainBody");
var middleware_ensure_req_body_drained_default = drainBody;

// C:/Users/tittoo/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/wrangler/templates/middleware/middleware-miniflare3-json-error.ts
function reduceError(e) {
  return {
    name: e?.name,
    message: e?.message ?? String(e),
    stack: e?.stack,
    cause: e?.cause === void 0 ? void 0 : reduceError(e.cause)
  };
}
__name(reduceError, "reduceError");
var jsonError = /* @__PURE__ */ __name(async (request, env, _ctx, middlewareCtx) => {
  try {
    return await middlewareCtx.next(request, env);
  } catch (e) {
    const error = reduceError(e);
    return Response.json(error, {
      status: 500,
      headers: { "MF-Experimental-Error-Stack": "true" }
    });
  }
}, "jsonError");
var middleware_miniflare3_json_error_default = jsonError;

// .wrangler/tmp/bundle-67ZTK2/middleware-insertion-facade.js
var __INTERNAL_WRANGLER_MIDDLEWARE__ = [
  middleware_ensure_req_body_drained_default,
  middleware_miniflare3_json_error_default
];
var middleware_insertion_facade_default = workers_default;

// C:/Users/tittoo/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/wrangler/templates/middleware/common.ts
var __facade_middleware__ = [];
function __facade_register__(...args) {
  __facade_middleware__.push(...args.flat());
}
__name(__facade_register__, "__facade_register__");
function __facade_invokeChain__(request, env, ctx, dispatch, middlewareChain) {
  const [head, ...tail] = middlewareChain;
  const middlewareCtx = {
    dispatch,
    next(newRequest, newEnv) {
      return __facade_invokeChain__(newRequest, newEnv, ctx, dispatch, tail);
    }
  };
  return head(request, env, ctx, middlewareCtx);
}
__name(__facade_invokeChain__, "__facade_invokeChain__");
function __facade_invoke__(request, env, ctx, dispatch, finalMiddleware) {
  return __facade_invokeChain__(request, env, ctx, dispatch, [
    ...__facade_middleware__,
    finalMiddleware
  ]);
}
__name(__facade_invoke__, "__facade_invoke__");

// .wrangler/tmp/bundle-67ZTK2/middleware-loader.entry.ts
var __Facade_ScheduledController__ = class ___Facade_ScheduledController__ {
  constructor(scheduledTime, cron, noRetry) {
    this.scheduledTime = scheduledTime;
    this.cron = cron;
    this.#noRetry = noRetry;
  }
  static {
    __name(this, "__Facade_ScheduledController__");
  }
  #noRetry;
  noRetry() {
    if (!(this instanceof ___Facade_ScheduledController__)) {
      throw new TypeError("Illegal invocation");
    }
    this.#noRetry();
  }
};
function wrapExportedHandler(worker) {
  if (__INTERNAL_WRANGLER_MIDDLEWARE__ === void 0 || __INTERNAL_WRANGLER_MIDDLEWARE__.length === 0) {
    return worker;
  }
  for (const middleware of __INTERNAL_WRANGLER_MIDDLEWARE__) {
    __facade_register__(middleware);
  }
  const fetchDispatcher = /* @__PURE__ */ __name(function(request, env, ctx) {
    if (worker.fetch === void 0) {
      throw new Error("Handler does not export a fetch() function.");
    }
    return worker.fetch(request, env, ctx);
  }, "fetchDispatcher");
  return {
    ...worker,
    fetch(request, env, ctx) {
      const dispatcher = /* @__PURE__ */ __name(function(type, init) {
        if (type === "scheduled" && worker.scheduled !== void 0) {
          const controller = new __Facade_ScheduledController__(
            Date.now(),
            init.cron ?? "",
            () => {
            }
          );
          return worker.scheduled(controller, env, ctx);
        }
      }, "dispatcher");
      return __facade_invoke__(request, env, ctx, dispatcher, fetchDispatcher);
    }
  };
}
__name(wrapExportedHandler, "wrapExportedHandler");
function wrapWorkerEntrypoint(klass) {
  if (__INTERNAL_WRANGLER_MIDDLEWARE__ === void 0 || __INTERNAL_WRANGLER_MIDDLEWARE__.length === 0) {
    return klass;
  }
  for (const middleware of __INTERNAL_WRANGLER_MIDDLEWARE__) {
    __facade_register__(middleware);
  }
  return class extends klass {
    #fetchDispatcher = /* @__PURE__ */ __name((request, env, ctx) => {
      this.env = env;
      this.ctx = ctx;
      if (super.fetch === void 0) {
        throw new Error("Entrypoint class does not define a fetch() function.");
      }
      return super.fetch(request);
    }, "#fetchDispatcher");
    #dispatcher = /* @__PURE__ */ __name((type, init) => {
      if (type === "scheduled" && super.scheduled !== void 0) {
        const controller = new __Facade_ScheduledController__(
          Date.now(),
          init.cron ?? "",
          () => {
          }
        );
        return super.scheduled(controller);
      }
    }, "#dispatcher");
    fetch(request) {
      return __facade_invoke__(
        request,
        this.env,
        this.ctx,
        this.#dispatcher,
        this.#fetchDispatcher
      );
    }
  };
}
__name(wrapWorkerEntrypoint, "wrapWorkerEntrypoint");
var WRAPPED_ENTRY;
if (typeof middleware_insertion_facade_default === "object") {
  WRAPPED_ENTRY = wrapExportedHandler(middleware_insertion_facade_default);
} else if (typeof middleware_insertion_facade_default === "function") {
  WRAPPED_ENTRY = wrapWorkerEntrypoint(middleware_insertion_facade_default);
}
var middleware_loader_entry_default = WRAPPED_ENTRY;
export {
  __INTERNAL_WRANGLER_MIDDLEWARE__,
  middleware_loader_entry_default as default
};
//# sourceMappingURL=index.js.map
