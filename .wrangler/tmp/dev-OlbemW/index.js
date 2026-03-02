var __defProp = Object.defineProperty;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __name = (target, value) => __defProp(target, "name", { value, configurable: true });
var __esm = (fn, res) => function __init() {
  return fn && (res = (0, fn[__getOwnPropNames(fn)[0]])(fn = 0)), res;
};
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};

// .wrangler/tmp/bundle-TcfayS/checked-fetch.js
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
var urls;
var init_checked_fetch = __esm({
  ".wrangler/tmp/bundle-TcfayS/checked-fetch.js"() {
    urls = /* @__PURE__ */ new Set();
    __name(checkURL, "checkURL");
    globalThis.fetch = new Proxy(globalThis.fetch, {
      apply(target, thisArg, argArray) {
        const [request, init] = argArray;
        checkURL(request, init);
        return Reflect.apply(target, thisArg, argArray);
      }
    });
  }
});

// wrangler-modules-watch:wrangler:modules-watch
var init_wrangler_modules_watch = __esm({
  "wrangler-modules-watch:wrangler:modules-watch"() {
    init_checked_fetch();
    init_modules_watch_stub();
  }
});

// C:/Users/tittoo/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/wrangler/templates/modules-watch-stub.js
var init_modules_watch_stub = __esm({
  "C:/Users/tittoo/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/wrangler/templates/modules-watch-stub.js"() {
    init_wrangler_modules_watch();
  }
});

// workers/squad_engine.js
var squad_engine_exports = {};
__export(squad_engine_exports, {
  isPrioritySeries: () => isPrioritySeries,
  processRepairQueue: () => processRepairQueue,
  processSquads: () => processSquads,
  syncMatchSquad: () => syncMatchSquad
});
function isPrioritySeries(seriesName, liveSeriesSet = null) {
  if (!seriesName) return false;
  const s = seriesName.toUpperCase();
  if (liveSeriesSet && liveSeriesSet.has(s)) return true;
  if (s.includes("WORLD CUP")) return true;
  if (s.includes("T20 WORLD CUP")) return true;
  if (s.includes("CHAMPIONS TROPHY")) return true;
  if (s.includes("ASIA CUP")) return true;
  if (s.includes("IPL") || s.includes("INDIAN PREMIER")) return true;
  if (s.includes("PSL") || s.includes("PAKISTAN SUPER")) return true;
  if (s.includes("BBL") || s.includes("BIG BASH")) return true;
  if (s.includes("THE HUNDRED")) return true;
  if (s.includes("WPL") || s.includes("WOMEN'S PREMIER")) return true;
  return false;
}
function buildLiveScardCheckKey(matchId) {
  return `${LIVE_SCARD_CHECK_PREFIX}${String(matchId)}`;
}
async function readLiveScardCheckedAt(env, matchId) {
  const key = buildLiveScardCheckKey(matchId);
  const row = await env.DB.prepare("SELECT value FROM sys_config WHERE key = ?").bind(key).first();
  if (!row || row.value === null || row.value === void 0) return 0;
  const checkedAt = Number(row.value);
  return Number.isFinite(checkedAt) ? checkedAt : 0;
}
async function writeLiveScardCheckedAt(env, matchId, nowSeconds) {
  const key = buildLiveScardCheckKey(matchId);
  await env.DB.prepare(
    "INSERT OR REPLACE INTO sys_config (key, value, updated_at) VALUES (?, ?, ?)"
  ).bind(key, String(Number(nowSeconds || 0)), Date.now()).run();
}
async function clearLiveScardCheckedAt(env, matchId) {
  const key = buildLiveScardCheckKey(matchId);
  await env.DB.prepare("DELETE FROM sys_config WHERE key = ?").bind(key).run();
}
function buildScardSnapshotKey(matchId) {
  return `${SCARD_SNAPSHOT_PREFIX}${String(matchId)}`;
}
async function readScardSnapshot(env, matchId) {
  const key = buildScardSnapshotKey(matchId);
  const row = await env.DB.prepare("SELECT value FROM sys_config WHERE key = ?").bind(key).first();
  if (!row || !row.value) return null;
  try {
    const parsed = JSON.parse(row.value);
    if (!parsed || typeof parsed !== "object") return null;
    return {
      hash: String(parsed.hash || "").trim(),
      stableUntil: Number(parsed.stableUntil || 0)
    };
  } catch {
    return null;
  }
}
async function writeScardSnapshot(env, matchId, payload) {
  const key = buildScardSnapshotKey(matchId);
  await env.DB.prepare(
    "INSERT OR REPLACE INTO sys_config (key, value, updated_at) VALUES (?, ?, ?)"
  ).bind(
    key,
    JSON.stringify(payload || {}),
    Date.now()
  ).run();
}
function stableHash(input) {
  const text = String(input || "");
  let hash = 2166136261;
  for (let i = 0; i < text.length; i += 1) {
    hash ^= text.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0).toString(16).padStart(8, "0");
}
function buildScardSnapshotHash(data) {
  const xiA = normalizeIdsForCompare(data?.xiA || []);
  const xiB = normalizeIdsForCompare(data?.xiB || []);
  const lastUpdated = String(data?.lastUpdated || "").trim();
  return stableHash(`${xiA.join(",")}|${xiB.join(",")}|${lastUpdated}`);
}
function normalizeIdsForCompare(values) {
  return Array.from(new Set(
    (Array.isArray(values) ? values : []).map((v) => String(v || "").trim()).filter(Boolean)
  )).sort();
}
async function hasMeaningfulScardUpdate(env, matchId, data) {
  if (!data || data.error) return false;
  const nextA = normalizeIdsForCompare(data.xiA);
  const nextB = normalizeIdsForCompare(data.xiB);
  if (nextA.length === 0 && nextB.length === 0) return false;
  const current = await env.DB.prepare(
    "SELECT playing_11_a, playing_11_b FROM match_squads WHERE match_id = ?"
  ).bind(matchId).first();
  if (!current) return false;
  let currentA = [];
  let currentB = [];
  try {
    currentA = normalizeIdsForCompare(JSON.parse(current.playing_11_a || "[]"));
  } catch (_) {
    currentA = [];
  }
  try {
    currentB = normalizeIdsForCompare(JSON.parse(current.playing_11_b || "[]"));
  } catch (_) {
    currentB = [];
  }
  const sameA = currentA.length === nextA.length && currentA.every((v, i) => v === nextA[i]);
  const sameB = currentB.length === nextB.length && currentB.every((v, i) => v === nextB[i]);
  return !(sameA && sameB);
}
async function processSquads(matches, env, apiKey, apiHost) {
  const logs = [];
  try {
    if (!matches || !Array.isArray(matches)) {
      console.log(`[SQUAD_SAFE_GUARD_APPLIED] matches argument invalid hai (type: ${typeof matches}). Squad engine skip.`);
      return { processed: 0, logs: ["[SQUAD_SAFE_GUARD_APPLIED] Invalid matches input - skipped"] };
    }
    logs.push(`\u{1F50D} Squad Engine: ${matches.length} matches process ho rahe hain...`);
    const liveSeriesSet = new Set(
      matches.filter((m) => m.status === "Live" || m.status === "In Progress").map((m) => (m.series_name || m.title || "").toUpperCase()).filter(Boolean)
    );
    if (liveSeriesSet.size > 0) {
      console.log("[DYNAMIC_WHITELIST] Live series detected:", [...liveSeriesSet]);
    }
    for (const match of matches) {
      const seriesName = match.series_name || match.title || "";
      const isPriority = isPrioritySeries(seriesName, liveSeriesSet);
      if (!isPriority) {
        continue;
      }
      const meta = await env.DB.prepare(
        "SELECT series_last_fetch, series_last_fail, scard_last_fetch, squad_state FROM match_squads WHERE match_id = ?"
      ).bind(match.id).first();
      const now = Math.floor(Date.now() / 1e3);
      let source = "NONE";
      let reason = "";
      if (!meta) {
        console.log(`[SQUAD_META_MISSING_SKIP ${match.id}] match_squads record nahi mila. Fetch skip.`);
        continue;
      }
      const squadState = meta.squad_state;
      let targetState = squadState;
      if (match.status === "Live" || match.status === "In Progress") {
        const lastFetch = meta?.scard_last_fetch || 0;
        const diff = now - lastFetch;
        const lastCheckedAt = await readLiveScardCheckedAt(env, match.id);
        const checkedDiff = lastCheckedAt > 0 ? now - lastCheckedAt : Number.MAX_SAFE_INTEGER;
        const scardSnapshotState = await readScardSnapshot(env, match.id);
        if (scardSnapshotState && scardSnapshotState.stableUntil > now) {
          source = "NONE";
          reason = `[FETCH_SKIPPED_COOLDOWN] SCARD hash window active`;
        } else if (lastCheckedAt > 0 && checkedDiff < LIVE_SCARD_CHECK_COOLDOWN_SECONDS) {
          source = "NONE";
          reason = `[FETCH_SKIPPED_COOLDOWN] Live Memory Wait (${checkedDiff}s < ${LIVE_SCARD_CHECK_COOLDOWN_SECONDS}s)`;
        } else if (diff > 600) {
          source = "SCARD";
          targetState = 2;
          reason = `Live Match (Last fetch: ${diff}s ago)`;
        } else {
          source = "NONE";
          reason = `[FETCH_SKIPPED_COOLDOWN] Live Wait (${diff}s < 600s)`;
        }
      } else if (squadState === 0) {
        const lastFetch = meta?.series_last_fetch || 0;
        const lastFail = meta?.series_last_fail || 0;
        if (lastFetch > 0) {
          source = "NONE";
          reason = `[FETCH_ALREADY_EXISTS] Series Squad already fetched.`;
          if (squadState === 0) targetState = 1;
        } else {
          const failDiff = now - lastFail;
          if (failDiff > 21600) {
            source = "SERIES";
            targetState = 1;
            reason = `New Match (First Fetch)`;
          } else {
            source = "NONE";
            reason = `[FETCH_SKIPPED_COOLDOWN] Series Fail Wait (${failDiff}s < 6h)`;
          }
        }
      } else if (squadState === 1) {
        source = "NONE";
        reason = `[FETCH_ALREADY_EXISTS] State 1 (Roster Saved). No updates needed until Toss.`;
      } else {
        source = "NONE";
        reason = `Match Status: ${match.status}`;
      }
      if (source !== "NONE") {
        console.log(`[FETCH_ALLOWED] Match: ${match.id} | Source: ${source} | Reason: ${reason}`);
        logs.push(`\u{1F680} Fetching ${match.id} (${source})`);
        const data = await fetchSquadBySource(match.id, match.series_id, source, apiKey, apiHost, env);
        await saveToDB(env, String(match.id), data, targetState, source);
        if (source === "SCARD") {
          if (data && !data.error) {
            const scardSnapshotHash = buildScardSnapshotHash(data);
            const previousSnapshot = await readScardSnapshot(env, match.id);
            const stableUntil = previousSnapshot && previousSnapshot.hash && previousSnapshot.hash === scardSnapshotHash ? now + SCARD_SNAPSHOT_SKIP_SECONDS : 0;
            await writeScardSnapshot(env, match.id, {
              hash: scardSnapshotHash,
              stableUntil
            });
          }
          const meaningfulUpdate = await hasMeaningfulScardUpdate(env, String(match.id), data);
          if (meaningfulUpdate) {
            await clearLiveScardCheckedAt(env, match.id);
          } else {
            await writeLiveScardCheckedAt(env, match.id, now);
          }
        }
      } else {
        if (reason.includes("COOLDOWN") || reason.includes("EXISTS")) {
          console.log(`[SKIP] Match: ${match.id} | ${reason}`);
        }
      }
    }
    return { processed: matches.length, logs };
  } catch (e) {
    console.error("Squad Engine SafeGuard Error:", e);
    return { processed: 0, error: e.message };
  }
}
async function saveToDB(env, matchId, data, newState, source) {
  const now = Math.floor(Date.now() / 1e3);
  if (!data || data.error) {
    console.log(`\u26A0\uFE0F Fetch Failed for ${matchId} (${source}). Error: ${data?.error}`);
    if (source === "SERIES") {
      await env.DB.prepare("UPDATE match_squads SET series_last_fail = ? WHERE match_id = ?").bind(now, matchId).run();
    }
    return;
  }
  if (source === "SERIES") {
    if (!data.teamA || !data.teamB || data.teamA.length === 0) {
      console.log(`\u26A0\uFE0F Empty Roster for ${matchId}. Skipping Save.`);
      await env.DB.prepare("UPDATE match_squads SET series_last_fail = ? WHERE match_id = ?").bind(now, matchId).run();
      return;
    }
    console.log(`\u2705 Saving Full Roster for ${matchId}. State -> ${newState}. Source: SERIES`);
    await env.DB.prepare(`
            INSERT INTO match_squads (
                match_id, series_id, team_a_roster, team_b_roster, playing_11_a, playing_11_b, 
                squad_state, last_updated, series_last_fetch
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(match_id) DO UPDATE SET
                squad_state = excluded.squad_state,
                last_updated = excluded.last_updated,
                team_a_roster = excluded.team_a_roster,
                team_b_roster = excluded.team_b_roster,
                series_id = excluded.series_id,
                series_last_fetch = excluded.series_last_fetch,
                series_last_fail = NULL  -- Clear fail flag on success
        `).bind(
      matchId,
      data.seriesId,
      JSON.stringify(data.teamA),
      JSON.stringify(data.teamB),
      JSON.stringify([]),
      JSON.stringify([]),
      newState,
      now,
      now
      // Set series_last_fetch
    ).run();
  } else if (source === "SCARD") {
    console.log(`\u2705 Updating Playing XI for ${matchId}. State -> ${newState}. Source: SCARD`);
    const current = await env.DB.prepare("SELECT team_a_roster, team_b_roster FROM match_squads WHERE match_id = ?").bind(matchId).first();
    if (!current) {
      console.log(`\u26A0\uFE0F No existing roster for ${matchId}. Cannot process SCARD update.`);
      return;
    }
    let rosterA = JSON.parse(current.team_a_roster || "[]");
    let rosterB = JSON.parse(current.team_b_roster || "[]");
    const xiA = data.xiA || [];
    const xiB = data.xiB || [];
    const updateRoster = /* @__PURE__ */ __name((roster, xiList) => {
      return roster.map((p) => ({
        ...p,
        is_playing: xiList.includes(p.player_id)
        // USE player_id NOT id
      }));
    }, "updateRoster");
    rosterA = updateRoster(rosterA, xiA);
    rosterB = updateRoster(rosterB, xiB);
    await env.DB.prepare(`
            UPDATE match_squads 
            SET squad_state = ?, last_updated = ?, 
                team_a_roster = ?, team_b_roster = ?,
                playing_11_a = ?, playing_11_b = ?,
                scard_last_fetch = ?
            WHERE match_id = ?
        `).bind(
      newState,
      now,
      JSON.stringify(rosterA),
      JSON.stringify(rosterB),
      JSON.stringify(xiA),
      JSON.stringify(xiB),
      now,
      // Set scard_last_fetch
      matchId
    ).run();
  }
}
async function fetchSquadBySource(matchId, seriesId, source, key, host, env) {
  try {
    if (source === "SERIES") {
      return await fetchSeriesSquads(matchId, seriesId, key, host, env);
    } else if (source === "SCARD") {
      return await fetchMatchScard(matchId, key, host);
    }
    return { error: "Unknown Source" };
  } catch (e) {
    console.error(`Adapter Error ${matchId} (${source}):`, e);
    return { error: e.message };
  }
}
async function fetchSeriesSquads(matchId, seriesId, key, host, env) {
  const matchInfo = await env.DB.prepare("SELECT team_a, team_b, team_a_id, team_b_id FROM matches WHERE id = ?").bind(matchId).first();
  if (!matchInfo) return { error: "Match not found in DB" };
  const teamA = matchInfo.team_a;
  const teamB = matchInfo.team_b;
  const teamAId = matchInfo.team_a_id || "0";
  const teamBId = matchInfo.team_b_id || "0";
  if (!seriesId || seriesId == "0") return { error: "Invalid Series ID" };
  const url = `https://${host}/series/v1/${seriesId}/squads`;
  const resp = await fetch(url, { headers: { "x-rapidapi-key": key, "x-rapidapi-host": host } });
  if (!resp.ok) return { error: `API Error: ${resp.status} ${resp.statusText}` };
  if (resp.status === 204) {
    return { error: "No Content (204)", status: 204 };
  }
  const rawText = await resp.text();
  console.log(`[SQUAD_HTTP_DETAILS] Series: ${seriesId}`, {
    status: resp.status,
    contentType: resp.headers.get("content-type"),
    preview: rawText.substring(0, 200)
  });
  let sData;
  try {
    sData = JSON.parse(rawText);
    console.log(`[SQUAD_RAW_DUMP] Series: ${seriesId}`, {
      keys: Object.keys(sData || {}),
      squadsType: typeof sData?.squads,
      squadsLen: Array.isArray(sData?.squads) ? sData.squads.length : -1
    });
    if (!sData.squads) {
      console.log("[SQUAD_ROOT_KEYS]", Object.keys(sData));
      for (const k in sData) {
        if (typeof sData[k] === "object" && sData[k] !== null) {
          console.log("[SQUAD_CHILD_KEYS]", k, Object.keys(sData[k]));
        }
      }
    }
  } catch (e) {
    console.error(`JSON Parse Error for ${seriesId}:`, rawText.substring(0, 200));
    return { error: `JSON Parse Error. Raw: ${rawText}` };
  }
  if (!sData.squads) {
    console.log(`[SQUAD_RESPONSE_SHAPE] Series: ${seriesId}`, {
      keys: Object.keys(sData)
    });
    return { error: "No 'squads' in API response" };
  }
  const squadA = findSquad(sData.squads, teamA);
  const squadB = findSquad(sData.squads, teamB);
  if (!squadA && !squadB) return { error: `Squads not found for ${teamA} or ${teamB}` };
  const result = { teamA: [], teamB: [], seriesId };
  if (squadA) result.teamA = await fetchPlayers(squadA, seriesId, key, host, teamAId, teamA);
  if (squadB) result.teamB = await fetchPlayers(squadB, seriesId, key, host, teamBId, teamB);
  return result;
}
async function fetchMatchScard(matchId, key, host) {
  const url = `https://${host}/mcenter/v1/${matchId}/scard`;
  const resp = await fetch(url, { headers: { "x-rapidapi-key": key, "x-rapidapi-host": host } });
  if (!resp.ok) return { error: `Scard Error: ${resp.status}` };
  const data = await resp.json();
  if (!data.miniScore) return { error: "No miniScore in Scard" };
  const tA = data.miniScore.teamA || {};
  const tB = data.miniScore.teamB || {};
  const getIDs = /* @__PURE__ */ __name((list) => (list || []).map((p) => p.id).filter((id) => !!id).map(String), "getIDs");
  return {
    xiA: getIDs(tA.playingXI),
    benchA: getIDs(tA.bench),
    xiB: getIDs(tB.playingXI),
    benchB: getIDs(tB.bench),
    lastUpdated: String(
      data.lastUpdated || data.lastUpdatedTime || data.lastUpdatedTs || data.miniScore?.lastUpdated || ""
    )
  };
}
function findSquad(squads, teamName) {
  if (!squads || !teamName) return null;
  const nameLower = teamName.trim().toLowerCase();
  let found = squads.find((s) => !s.isHeader && s.squadType && s.squadType.trim().toLowerCase() === nameLower);
  if (found) return found;
  found = squads.find((s) => !s.isHeader && s.teamName && s.teamName.trim().toLowerCase() === nameLower);
  if (found) return found;
  return squads.find((s) => {
    if (s.isHeader) return false;
    const sType = (s.squadType || "").trim().toLowerCase();
    const tName = (s.teamName || "").trim().toLowerCase();
    return sType && (sType.includes(nameLower) || nameLower.includes(sType)) || tName && (tName.includes(nameLower) || nameLower.includes(tName));
  });
}
async function fetchPlayers(squad, seriesId, key, host, teamId, teamName) {
  if (!squad || !squad.squadId) return [];
  try {
    const url = `https://${host}/series/v1/${seriesId}/squads/${squad.squadId}`;
    const resp = await fetch(url, { headers: { "x-rapidapi-key": key, "x-rapidapi-host": host } });
    if (resp.ok) {
      const rawText = await resp.text();
      console.log(`[PLAYER_RAW_PREVIEW] SquadID: ${squad.squadId} | First 200 chars:`, rawText.substring(0, 200));
      let data;
      try {
        data = JSON.parse(rawText);
        console.log(`[PLAYER_RAW_DUMP] SquadID: ${squad.squadId}`, {
          keys: Object.keys(data || {}),
          playerType: typeof data?.player,
          playersType: typeof data?.players,
          isArray: Array.isArray(data?.player)
        });
        if (data.player) return mapPlayers(data.player, teamId, teamName);
      } catch (e) {
        console.error(`[PLAYER_JSON_FAIL] SquadID: ${squad.squadId}`, rawText.substring(0, 200));
      }
    }
  } catch (e) {
    console.error("Player Fetch Error", e);
  }
  return [];
}
function mapPlayers(players, teamId, teamName) {
  return players.filter((p) => p.id && p.name && !p.isHeader).map((p) => ({
    player_id: (p.id || "").toString(),
    name: p.name || "Unknown",
    team_id: teamId.toString(),
    team_name: teamName,
    role: normalizeRoleStrict(p.role),
    image_id: p.imageId ? p.imageId.toString() : "",
    is_playing: false,
    // Default for Pre-Match
    fantasy_points: 0,
    credit: 0
  }));
}
function normalizeRoleStrict(role) {
  if (!role) return "BAT";
  const r = role.toUpperCase();
  if (r.includes("WK") || r.includes("KEEPER")) return "WK";
  if (r.includes("ALL") || r.includes("ROUND")) return "AR";
  if (r.includes("BOWL")) return "BOWL";
  return "BAT";
}
async function syncMatchSquad(matchId, env, sourceOverride) {
  console.log(`\u{1F6E0}\uFE0F Manual Sync Requested for ${matchId} [${sourceOverride || "AUTO"}]`);
  const apiKey = env.RAPID_API_KEY || "70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee";
  const apiHost = "cricbuzz-cricket.p.rapidapi.com";
  const match = await env.DB.prepare("SELECT id, series_id, status FROM matches WHERE id = ?").bind(matchId).first();
  if (!match) return { error: "Match Not Found" };
  let source = sourceOverride;
  let targetState = 0;
  if (!source) {
    source = "SERIES";
    targetState = 1;
    if (match.status === "Live") {
      source = "SCARD";
      targetState = 2;
    }
  } else {
    targetState = source === "SERIES" ? 1 : 2;
  }
  const data = await fetchSquadBySource(match.id, match.series_id, source, apiKey, apiHost, env);
  await saveToDB(env, String(matchId), data, targetState, source);
  return { data, source, targetState };
}
async function processRepairQueue(env) {
  const logs = [];
  logs.push("\u{1F6E0}\uFE0F Checking Repair Queue...");
  try {
    const task = await env.DB.prepare("SELECT * FROM repair_queue WHERE processed = 0 ORDER BY created_at ASC LIMIT 1").first();
    if (!task) {
      logs.push("\u2705 No Pending Repairs.");
      return { processed: 0, logs };
    }
    logs.push(`\u{1F680} Processing Repair: Match ${task.match_id} (${task.action})`);
    const result = await syncMatchSquad(task.match_id, env, "SERIES");
    if (result && result.data && result.data.status === 204) {
      await env.DB.prepare("UPDATE repair_queue SET processed = 1 WHERE id = ?").bind(task.id).run();
      logs.push(`\u26A0\uFE0F Repair Skipped for ${task.match_id}. API returned 204 No Content.`);
      return { processed: 1, logs };
    }
    if (result && result.data && result.data.error && result.data.status === 204) {
      await env.DB.prepare("UPDATE repair_queue SET processed = 1 WHERE id = ?").bind(task.id).run();
      logs.push(`\u26A0\uFE0F Repair Skipped for ${task.match_id}. API returned 204 No Content.`);
      return { processed: 1, logs };
    }
    const valid = await env.DB.prepare(`
            SELECT 
                json_array_length(team_a_roster) as a, 
                json_array_length(team_b_roster) as b 
            FROM match_squads 
            WHERE match_id = ?
        `).bind(task.match_id).first();
    const success = valid && valid.a >= 11 && valid.b >= 11;
    if (success) {
      await env.DB.prepare("UPDATE repair_queue SET processed = 1 WHERE id = ?").bind(task.id).run();
      logs.push(`\u2705 Repair Success for ${task.match_id}. Squads: A=${valid.a}, B=${valid.b}`);
    } else {
      logs.push(`\u274C Repair Failed for ${task.match_id}. Data Invalid/Empty. Retrying next cycle.`);
    }
    return { processed: 1, logs };
  } catch (e) {
    console.error("Repair Error:", e);
    logs.push("\u274C Repair Error: " + e.message);
    return { processed: 0, error: e.message, logs };
  }
}
var LIVE_SCARD_CHECK_PREFIX, LIVE_SCARD_CHECK_COOLDOWN_SECONDS, SCARD_SNAPSHOT_PREFIX, SCARD_SNAPSHOT_SKIP_SECONDS;
var init_squad_engine = __esm({
  "workers/squad_engine.js"() {
    init_checked_fetch();
    init_modules_watch_stub();
    __name(isPrioritySeries, "isPrioritySeries");
    LIVE_SCARD_CHECK_PREFIX = "live_scard_checked:";
    LIVE_SCARD_CHECK_COOLDOWN_SECONDS = 15 * 60;
    SCARD_SNAPSHOT_PREFIX = "scard_snapshot:";
    SCARD_SNAPSHOT_SKIP_SECONDS = 30 * 60;
    __name(buildLiveScardCheckKey, "buildLiveScardCheckKey");
    __name(readLiveScardCheckedAt, "readLiveScardCheckedAt");
    __name(writeLiveScardCheckedAt, "writeLiveScardCheckedAt");
    __name(clearLiveScardCheckedAt, "clearLiveScardCheckedAt");
    __name(buildScardSnapshotKey, "buildScardSnapshotKey");
    __name(readScardSnapshot, "readScardSnapshot");
    __name(writeScardSnapshot, "writeScardSnapshot");
    __name(stableHash, "stableHash");
    __name(buildScardSnapshotHash, "buildScardSnapshotHash");
    __name(normalizeIdsForCompare, "normalizeIdsForCompare");
    __name(hasMeaningfulScardUpdate, "hasMeaningfulScardUpdate");
    __name(processSquads, "processSquads");
    __name(saveToDB, "saveToDB");
    __name(fetchSquadBySource, "fetchSquadBySource");
    __name(fetchSeriesSquads, "fetchSeriesSquads");
    __name(fetchMatchScard, "fetchMatchScard");
    __name(findSquad, "findSquad");
    __name(fetchPlayers, "fetchPlayers");
    __name(mapPlayers, "mapPlayers");
    __name(normalizeRoleStrict, "normalizeRoleStrict");
    __name(syncMatchSquad, "syncMatchSquad");
    __name(processRepairQueue, "processRepairQueue");
  }
});

// .wrangler/tmp/bundle-TcfayS/middleware-loader.entry.ts
init_checked_fetch();
init_modules_watch_stub();

// .wrangler/tmp/bundle-TcfayS/middleware-insertion-facade.js
init_checked_fetch();
init_modules_watch_stub();

// workers/index.js
init_checked_fetch();
init_modules_watch_stub();

// workers/cricket_engine.js
init_checked_fetch();
init_modules_watch_stub();
init_squad_engine();
var API_LOCK_ACTIVE = false;
var UPCOMING_EMPTY_CHECK_KEY = "upcoming_empty_checked_at";
var UPCOMING_EMPTY_CHECK_COOLDOWN_MS = 6 * 60 * 60 * 1e3;
var PREDICTIVE_CHECK_COOLDOWN_MS = 5 * 60 * 1e3;
var LIVE_SNAPSHOT_SKIP_WINDOW_MS = 60 * 60 * 1e3;
var UPCOMING_SNAPSHOT_HASH_KEY = "upcoming_snapshot_hash";
var UPCOMING_SNAPSHOT_SKIP_WINDOW_MS = 4 * 60 * 60 * 1e3;
var MATCH_STATE_CLASS_PREFIX = "match_state_class:";
async function processCricketData(env) {
  console.log("\u{1F3CF} Cricket Engine Shuru (Predictive Guarded Verification Mode)...");
  await verifySchema(env);
  if (API_LOCK_ACTIVE) {
    console.log("[API_LOCK_ACTIVE] Sab external API calls band hain. Sirf DB se data return ho raha hai.");
    return await getMatchesFromDB(env);
  }
  try {
    const matches = await fetchPublicLiveMatches(env);
    if (matches && matches.length > 0) {
      console.log(`\u{1F4E1} Scraper se ${matches.length} matches mila`);
      for (const match of matches.slice(0, 1)) {
        console.log("[CONTROL_UNLOCK_MATCH_ID] Syncing: " + match.id);
        await syncMatchToD1(match, env);
      }
    }
    return await getMatchesFromDB(env);
  } catch (e) {
    console.error("\u274C Cricket Engine Error:", e);
    return await getMatchesFromDB(env);
  }
}
__name(processCricketData, "processCricketData");
async function seedUpcomingMatches(env) {
  const nowMs = Date.now();
  const windowEndMs = nowMs + 48 * 60 * 60 * 1e3;
  const dbUpcomingRows = await env.DB.prepare(`
        SELECT id, start_time
        FROM matches
        WHERE status = 'Upcoming'
        AND start_time IS NOT NULL
        AND CAST(start_time AS INTEGER) > ?
    `).bind(nowMs).all();
  const currentUpcomingHash = buildUpcomingSnapshotHash(dbUpcomingRows.results || []);
  const upcomingSnapshotState = parseSnapshotState(
    await readSysConfigValue(env, UPCOMING_SNAPSHOT_HASH_KEY)
  );
  if (upcomingSnapshotState && upcomingSnapshotState.hash && upcomingSnapshotState.hash === currentUpcomingHash && upcomingSnapshotState.stableUntil > nowMs) {
    return;
  }
  const countRow = await env.DB.prepare(`
        SELECT COUNT(1) AS upcoming_count
        FROM matches
        WHERE status = 'Upcoming'
        AND start_time IS NOT NULL
        AND CAST(start_time AS INTEGER) > ?
        AND CAST(start_time AS INTEGER) < ?
    `).bind(nowMs, windowEndMs).first();
  const upcomingCount = Number(countRow?.upcoming_count || 0);
  if (upcomingCount >= 15) {
    console.log(`[UPCOMING_SEED_SKIP] ${upcomingCount} matches already available in next 48h.`);
    return;
  }
  const lastEmptyCheckedAt = await readSysConfigTimestamp(env, UPCOMING_EMPTY_CHECK_KEY);
  if (lastEmptyCheckedAt > 0 && nowMs - lastEmptyCheckedAt < UPCOMING_EMPTY_CHECK_COOLDOWN_MS) {
    console.log("[UPCOMING_SEED_SKIP] Empty window cooldown active.");
    return;
  }
  const incomingMatches = await fetchPublicLiveMatches(env);
  if (!Array.isArray(incomingMatches) || incomingMatches.length === 0) {
    await writeSysConfigTimestamp(env, UPCOMING_EMPTY_CHECK_KEY, nowMs);
    const emptyHash = buildUpcomingSnapshotHash([]);
    const stableUntil = upcomingSnapshotState?.hash === emptyHash ? nowMs + UPCOMING_SNAPSHOT_SKIP_WINDOW_MS : 0;
    await writeSysConfigValue(env, UPCOMING_SNAPSHOT_HASH_KEY, JSON.stringify({
      hash: emptyHash,
      stableUntil
    }));
    console.log("[UPCOMING_SEED_NO_DATA] Scraper returned no upcoming matches.");
    return;
  }
  let inserted = 0;
  let updated = 0;
  for (const match of incomingMatches) {
    const matchId = String(match?.id || "").trim();
    const startTime = Number(match?.startTime || 0);
    if (!matchId || startTime <= nowMs) {
      continue;
    }
    const existing = await env.DB.prepare(`
            SELECT status, start_time
            FROM matches
            WHERE id = ?
        `).bind(matchId).first();
    if (!existing) {
      await env.DB.prepare(`
                INSERT INTO matches(
            id,
            series_id,
            series_name,
            title,
            short_title,
            status,
            start_time,
            team_a,
            team_b,
            team_a_img,
            team_b_img,
            team_a_id,
            team_b_id,
            last_updated,
            last_score,
            last_wickets,
            last_over,
            last_innings
        ) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
        matchId,
        match.seriesId || "0",
        match.seriesName || "",
        match.title || "",
        match.shortTitle || "",
        "Upcoming",
        startTime,
        match.teamA || "",
        match.teamB || "",
        match.teamAImg || "",
        match.teamBImg || "",
        match.team1Id || "0",
        match.team2Id || "0",
        startTime,
        match.lastScore || null,
        match.lastWickets || 0,
        match.lastOver || null,
        match.lastInnings || 1
      ).run();
      inserted += 1;
      continue;
    }
    if (existing.status !== "Upcoming") {
      continue;
    }
    const existingStart = Number(existing.start_time || 0);
    if (existingStart === startTime) {
      continue;
    }
    await env.DB.prepare(`
            UPDATE matches
            SET start_time = ?, last_updated = ?
        WHERE id = ?
            AND status = 'Upcoming'
                `).bind(startTime, startTime, matchId).run();
    updated += 1;
  }
  if (inserted === 0) {
    await writeSysConfigTimestamp(env, UPCOMING_EMPTY_CHECK_KEY, nowMs);
  } else {
    await clearSysConfigTimestamp(env, UPCOMING_EMPTY_CHECK_KEY);
  }
  const incomingUpcomingHash = buildUpcomingSnapshotHash(incomingMatches);
  const upcomingStableUntil = upcomingSnapshotState?.hash === incomingUpcomingHash ? nowMs + UPCOMING_SNAPSHOT_SKIP_WINDOW_MS : 0;
  await writeSysConfigValue(env, UPCOMING_SNAPSHOT_HASH_KEY, JSON.stringify({
    hash: incomingUpcomingHash,
    stableUntil: upcomingStableUntil
  }));
  console.log(`[UPCOMING_SEED_DONE] inserted = ${inserted}, updated = ${updated}, scanned = ${incomingMatches.length}`);
}
__name(seedUpcomingMatches, "seedUpcomingMatches");
async function warmupMissingUpcomingSquads(env) {
  const nowMs = Date.now();
  const eligibleRows = await env.DB.prepare(`
        SELECT m.id
        FROM matches m
        LEFT JOIN match_squads ms
            ON CAST(ms.match_id AS INTEGER) = CAST(m.id AS INTEGER)
        LEFT JOIN sys_config sc
            ON sc.key = ('squad_warmup_done:' || CAST(m.id AS TEXT))
        WHERE m.status = 'Upcoming'
        AND m.start_time IS NOT NULL
        AND CAST(m.start_time AS INTEGER) > ?
        AND ms.match_id IS NULL
        AND sc.key IS NULL
        ORDER BY CAST(m.start_time AS INTEGER) ASC
        LIMIT 2
        `).bind(nowMs).all();
  const matches = eligibleRows.results || [];
  if (matches.length === 0) {
    console.log("[SQUAD_WARMUP_SKIP] No eligible upcoming matches.");
    return;
  }
  const { syncMatchSquad: syncMatchSquad2 } = await Promise.resolve().then(() => (init_squad_engine(), squad_engine_exports));
  let attempted = 0;
  let success = 0;
  let failed = 0;
  for (const row of matches) {
    const matchId = String(row?.id || "").trim();
    if (!matchId) continue;
    const markerKey = `squad_warmup_done: ${matchId}`;
    const claimAt = Date.now();
    const claim = await env.DB.prepare(
      "INSERT OR IGNORE INTO sys_config (key, value, updated_at) VALUES (?, ?, ?)"
    ).bind(
      markerKey,
      JSON.stringify({ status: "claimed", claimedAt: claimAt }),
      claimAt
    ).run();
    if (!claim.meta || claim.meta.changes !== 1) {
      continue;
    }
    attempted += 1;
    const marker = {
      status: "failed",
      source: "SERIES",
      reason: "UNKNOWN",
      attemptedAt: claimAt
    };
    try {
      const result = await syncMatchSquad2(matchId, env, "SERIES");
      const errorText = result?.error || result?.data?.error;
      if (errorText) {
        marker.reason = String(errorText);
        failed += 1;
      } else {
        marker.status = "success";
        marker.reason = "OK";
        success += 1;
      }
    } catch (e) {
      marker.reason = e?.message ? String(e.message) : "EXCEPTION";
      failed += 1;
    }
    marker.attemptedAt = Date.now();
    await env.DB.prepare(
      "UPDATE sys_config SET value = ?, updated_at = ? WHERE key = ?"
    ).bind(
      JSON.stringify(marker),
      marker.attemptedAt,
      markerKey
    ).run();
  }
  console.log(`[SQUAD_WARMUP_DONE] attempted = ${attempted}, success = ${success}, failed = ${failed}, scanned = ${matches.length}`);
}
__name(warmupMissingUpcomingSquads, "warmupMissingUpcomingSquads");
async function verifySchema(env) {
  try {
    const matchesCols = ["last_score", "last_wickets", "last_over", "last_innings"];
    for (const col of matchesCols) {
      try {
        await env.DB.prepare(`SELECT ${col} FROM matches LIMIT 1`).first();
      } catch (e) {
        const colDef = col === "last_score" ? "TEXT" : col === "last_over" ? "TEXT" : col === "last_wickets" ? "INTEGER" : col === "last_innings" ? "INTEGER" : "TEXT";
        await env.DB.prepare(`ALTER TABLE matches ADD COLUMN ${col} ${colDef}`).run();
        console.log(`[SCHEMA_COLUMN_ADDED] ${col} column add kiya gaya matches table mein`);
      }
    }
    try {
      await env.DB.prepare(`SELECT total_points FROM leaderboards LIMIT 1`).first();
      console.log(`[SCHEMA_OK] leaderboards.total_points column exist karta hai.`);
    } catch (e) {
      console.log(`[SCHEMA_SKIP] leaderboards check fail(non - critical): ${e.message}`);
    }
    console.log("[SCHEMA_OK] Schema verify complete.");
  } catch (e) {
    console.error("[SCHEMA_VERIFY_ERROR] Schema check fail:", e.message);
  }
}
__name(verifySchema, "verifySchema");
async function getMatchesFromDB(env) {
  try {
    const cached = await env.DB.prepare("SELECT * FROM matches ORDER BY start_time ASC").all();
    return (cached.results || []).map((m) => ({
      ...m,
      team1Name: m.team_a,
      team2Name: m.team_b,
      teamA: m.team_a,
      teamB: m.team_b,
      matchDesc: m.title,
      seriesName: m.series_name || m.title,
      team1ShortName: m.short_title ? m.short_title.split(" vs ")[0] : m.team_a ? m.team_a.substring(0, 3).toUpperCase() : "T1",
      team2ShortName: m.short_title ? m.short_title.split(" vs ")[1] : m.team_b ? m.team_b.substring(0, 3).toUpperCase() : "T2",
      team1Id: m.team_a_id,
      team2Id: m.team_b_id,
      startDate: m.start_time,
      status: m.status,
      lastScore: m.last_score,
      lastWickets: m.last_wickets,
      lastOver: m.last_over,
      lastInnings: m.last_innings
    }));
  } catch (ex) {
    console.error("[DB_READ_ERROR] Matches DB se nahi aaya:", ex.message);
    return [];
  }
}
__name(getMatchesFromDB, "getMatchesFromDB");
var DB_WRITE_FAIL_BLOCK = /* @__PURE__ */ new Map();
async function syncMatchToD1(match, env) {
  const failTime = DB_WRITE_FAIL_BLOCK.get(match.id);
  if (failTime) {
    const elapsed = Date.now() - failTime;
    if (elapsed < 30 * 60 * 1e3) {
      console.log(`[DB_WRITE_FAIL_GUARD ${match.id}]DB write fail ke baad 30 min block chal raha hai(${Math.floor(elapsed / 6e4)}m elapsed).Skip.`);
      return;
    } else {
      DB_WRITE_FAIL_BLOCK.delete(match.id);
    }
  }
  try {
    const existing = await env.DB.prepare("SELECT last_updated, status, team_a_id FROM matches WHERE id = ?").bind(match.id).first();
    const now = Date.now();
    if (existing) {
      await env.DB.prepare(`
                UPDATE matches SET 
                title = ?,
        short_title = ?,
        series_id = ?,
        series_name = ?,
        start_time = ?,
        status = ?,
        team_a = ?,
        team_b = ?,
        team_a_img = ?,
        team_b_img = ?,
        team_a_id = ?,
        team_b_id = ?,
        last_updated = ?,
        last_score = ?,
        last_wickets = ?,
        last_over = ?,
        last_innings = ?
            WHERE id = ?
                `).bind(
        match.title,
        match.shortTitle,
        match.seriesId,
        match.seriesName || "",
        match.startTime,
        match.status,
        match.teamA,
        match.teamB,
        match.teamAImg,
        match.teamBImg,
        match.team1Id,
        match.team2Id,
        now,
        match.lastScore || null,
        match.lastWickets || 0,
        match.lastOver || null,
        match.lastInnings || 1,
        match.id
      ).run();
    } else {
      await env.DB.prepare(`
            INSERT INTO matches(id, series_id, series_name, title, short_title, status, start_time, team_a, team_b, team_a_img, team_b_img, team_a_id, team_b_id, last_updated, last_score, last_wickets, last_over, last_innings)
            VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `).bind(
        match.id,
        match.seriesId,
        match.seriesName || "",
        match.title,
        match.shortTitle,
        match.status,
        match.startTime,
        match.teamA,
        match.teamB,
        match.teamAImg,
        match.teamBImg,
        match.team1Id,
        match.team2Id,
        now,
        match.lastScore || null,
        match.lastWickets || 0,
        match.lastOver || null,
        match.lastInnings || 1
      ).run();
      if (match.status === "Upcoming" || match.status === "Live") {
        const squadCheck = await env.DB.prepare(`SELECT match_id FROM match_squads WHERE match_id = ? `).bind(match.id).first();
        if (!squadCheck) {
          console.log(`\u{1F195} Naya match mila: ${match.id}, squad check queue mein...`);
          const { syncMatchSquad: syncMatchSquad2 } = await Promise.resolve().then(() => (init_squad_engine(), squad_engine_exports));
          await syncMatchSquad2(env, { id: match.id, series_id: match.seriesId, status: match.status }, env.RAPID_API_KEY, env.RAPID_API_HOST);
        }
      }
    }
    if (match.stateClass) {
      await writeMatchStateClass(env, match.id, match.stateClass);
    }
  } catch (e) {
    DB_WRITE_FAIL_BLOCK.set(match.id, Date.now());
    console.error(`[DB_WRITE_FAIL_GUARD ${match.id}]DB write fail hua. 30 min ke liye polling block.Error: ${e.message}`);
  }
}
__name(syncMatchToD1, "syncMatchToD1");
async function readSysConfigTimestamp(env, key) {
  const row = await env.DB.prepare("SELECT value FROM sys_config WHERE key = ?").bind(key).first();
  if (!row || row.value === null || row.value === void 0) return 0;
  const ts = Number(row.value);
  return Number.isFinite(ts) ? ts : 0;
}
__name(readSysConfigTimestamp, "readSysConfigTimestamp");
async function writeSysConfigTimestamp(env, key, timestamp) {
  const ts = Number(timestamp || 0);
  await env.DB.prepare(
    "INSERT OR REPLACE INTO sys_config (key, value, updated_at) VALUES (?, ?, ?)"
  ).bind(key, String(ts), Date.now()).run();
}
__name(writeSysConfigTimestamp, "writeSysConfigTimestamp");
async function clearSysConfigTimestamp(env, key) {
  await env.DB.prepare("DELETE FROM sys_config WHERE key = ?").bind(key).run();
}
__name(clearSysConfigTimestamp, "clearSysConfigTimestamp");
async function readSysConfigValue(env, key) {
  const row = await env.DB.prepare("SELECT value FROM sys_config WHERE key = ?").bind(key).first();
  return row?.value ?? null;
}
__name(readSysConfigValue, "readSysConfigValue");
async function writeSysConfigValue(env, key, value) {
  await env.DB.prepare(
    "INSERT OR REPLACE INTO sys_config (key, value, updated_at) VALUES (?, ?, ?)"
  ).bind(key, String(value ?? ""), Date.now()).run();
}
__name(writeSysConfigValue, "writeSysConfigValue");
function stableHash2(input) {
  const text = String(input || "");
  let hash = 2166136261;
  for (let i = 0; i < text.length; i += 1) {
    hash ^= text.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0).toString(16).padStart(8, "0");
}
__name(stableHash2, "stableHash");
function normalizeSnapshotInt(value) {
  const num = Number(value || 0);
  return Number.isFinite(num) ? num : 0;
}
__name(normalizeSnapshotInt, "normalizeSnapshotInt");
function buildUpcomingSnapshotHash(matches) {
  const rows = (Array.isArray(matches) ? matches : []).map((m) => {
    const matchId = String(m?.id ?? "").trim();
    const startTime = normalizeSnapshotInt(m?.startTime ?? m?.start_time);
    return `${matchId} | ${startTime}`;
  }).filter(Boolean).sort();
  return stableHash2(rows.join("||"));
}
__name(buildUpcomingSnapshotHash, "buildUpcomingSnapshotHash");
function parseSnapshotState(rawValue) {
  if (!rawValue) return null;
  try {
    const parsed = JSON.parse(rawValue);
    if (!parsed || typeof parsed !== "object") return null;
    const hash = String(parsed.hash || "").trim();
    const stableUntil = normalizeSnapshotInt(parsed.stableUntil);
    return { hash, stableUntil };
  } catch {
    return null;
  }
}
__name(parseSnapshotState, "parseSnapshotState");
function buildMatchStateClassKey(matchId) {
  return `${MATCH_STATE_CLASS_PREFIX}${String(matchId)}`;
}
__name(buildMatchStateClassKey, "buildMatchStateClassKey");
async function writeMatchStateClass(env, matchId, stateClass) {
  const key = buildMatchStateClassKey(matchId);
  await env.DB.prepare(
    "INSERT OR REPLACE INTO sys_config (key, value, updated_at) VALUES (?, ?, ?)"
  ).bind(key, String(stateClass || ""), Date.now()).run();
}
__name(writeMatchStateClass, "writeMatchStateClass");
async function fetchPublicLiveMatches(env) {
  const HEADERS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/121.0"
  ];
  console.log("\u{1F680} Custom Scraper Triggered");
  try {
    const response = await fetch("https://www.cricbuzz.com/cricket-match/live-scores", {
      headers: {
        "User-Agent": HEADERS[Math.floor(Math.random() * HEADERS.length)],
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8"
      }
    });
    if (!response.ok) {
      console.error(`Scraper HTTP Error: ${response.status}`);
      return [];
    }
    const data = await response.text();
    const regex = /<a href="\/live-cricket-scores\/(\d+)\/([^"]+)"[^>]*title="([^"]+)"/g;
    let m;
    const matches = [];
    const unique = /* @__PURE__ */ new Set();
    const now = Date.now();
    while ((m = regex.exec(data)) !== null) {
      const matchId = m[1];
      if (!unique.has(matchId)) {
        unique.add(matchId);
        let team1 = "T1", team2 = "T2";
        const teamMatch = m[2].match(/^([a-z]+)-vs-([a-z]+)/);
        if (teamMatch) {
          team1 = teamMatch[1].toUpperCase();
          team2 = teamMatch[2].toUpperCase();
        }
        const title = m[3];
        let status = "Upcoming";
        if (title.toLowerCase().includes("complete") || title.toLowerCase().includes("won")) status = "Completed";
        else if (title.toLowerCase().includes("stumps") || title.toLowerCase().includes("live") || title.toLowerCase().includes("toss") || title.toLowerCase().includes("innings break")) status = "Live";
        else if (title.toLowerCase().includes("abandon")) status = "Abandoned";
        const fullText = `${team1} ${team2} ${title}`.toUpperCase();
        const isPremium = [
          "IPL",
          "INDIAN PREMIER LEAGUE",
          "BBL",
          "BIG BASH",
          "PSL",
          "PAKISTAN SUPER LEAGUE",
          "BPL",
          "BANGLADESH PREMIER LEAGUE",
          "SA20",
          "CPL",
          "HUNDRED",
          "WPL",
          "WORLD CUP",
          "ICC",
          "ASIA CUP",
          "CHAMPIONS TROPHY",
          "T20I",
          "ODI",
          "TEST",
          "WOMEN'S T20",
          "WOMEN'S ODI"
        ].some((kw) => fullText.includes(kw));
        const isExcluded = [
          "DOMESTIC",
          "SHIELD",
          "PLUNKET",
          "RANJI",
          "BLAST",
          "CHALLENGER",
          "TROPHY",
          "CUP",
          "LEAGUE"
        ].some((kw) => {
          if (kw === "TROPHY" && fullText.includes("CHAMPIONS TROPHY")) return false;
          if (kw === "CUP" && (fullText.includes("WORLD CUP") || fullText.includes("ASIA CUP"))) return false;
          if (kw === "LEAGUE" && (fullText.includes("PREMIER LEAGUE") || fullText.includes("SUPER LEAGUE") || fullText.includes("BIG BASH LEAGUE"))) return false;
          return fullText.includes(kw);
        });
        if (!isPremium || isExcluded) {
          continue;
        }
        matches.push({
          id: matchId,
          seriesId: "0",
          seriesName: "Public Scrape",
          title: `${team1} vs ${team2}`,
          shortTitle: `${team1} vs ${team2}`,
          status,
          teamA: team1,
          teamB: team2,
          team1Id: "0",
          team2Id: "0",
          startTime: now,
          lastUpdated: now,
          lastScore: status === "Live" ? "In Progress" : status,
          lastWickets: 0,
          lastOver: "0.0",
          lastInnings: 1,
          teamAImg: "",
          teamBImg: ""
        });
      }
    }
    return matches;
  } catch (e) {
    console.error("Scraper Error:", e.message);
    return [];
  }
}
__name(fetchPublicLiveMatches, "fetchPublicLiveMatches");

// workers/points_engine.js
init_checked_fetch();
init_modules_watch_stub();
var METRICS_CONFIG = {
  "T20": {
    run: 1,
    boundary: 1,
    // Four = 4 runs + 1 bonus = 5
    six: 2,
    // Six = 6 runs + 2 bonus = 8
    half_century: 0,
    century: 0,
    duck: 0,
    wicket: 25,
    lbw_bowled: 0,
    three_wickets: 0,
    four_wickets: 0,
    five_wickets: 0,
    maiden: 0,
    catch: 8,
    stump: 0,
    runout: 0
  },
  "ODI": {
    run: 1,
    boundary: 1,
    six: 2,
    half_century: 0,
    century: 0,
    duck: 0,
    wicket: 25,
    lbw_bowled: 0,
    four_wickets: 0,
    five_wickets: 0,
    maiden: 0,
    catch: 8,
    stump: 0,
    runout: 0
  },
  "TEST": {
    run: 1,
    boundary: 1,
    six: 2,
    half_century: 0,
    century: 0,
    duck: 0,
    wicket: 25,
    lbw_bowled: 0,
    four_wickets: 0,
    five_wickets: 0,
    maiden: 0,
    catch: 8,
    stump: 0,
    runout: 0
  }
};
function calculateStatsMetrics(stats, format = "T20") {
  let metricsPoints = 0;
  let breakdown = {};
  const rules = METRICS_CONFIG[format] || METRICS_CONFIG["T20"];
  if (stats.runs > 0) {
    const runPoints = stats.runs * rules.run;
    metricsPoints += runPoints;
    breakdown.runs = runPoints;
  }
  if (stats.fours > 0) {
    const fourBonus = stats.fours * rules.boundary;
    metricsPoints += fourBonus;
    breakdown.fours = fourBonus;
  }
  if (stats.sixes > 0) {
    const sixBonus = stats.sixes * rules.six;
    metricsPoints += sixBonus;
    breakdown.sixes = sixBonus;
  }
  if (stats.runs >= 100) {
    metricsPoints += rules.century;
    breakdown.century = rules.century;
  } else if (stats.runs >= 50) {
    metricsPoints += rules.half_century;
    breakdown.half_century = rules.half_century;
  }
  if (stats.isOut && stats.runs === 0 && (stats.role === "Batsman" || stats.role === "Allrounder")) {
    metricsPoints += rules.duck;
    breakdown.duck = rules.duck;
  }
  if (stats.wickets > 0) {
    const wicketPoints = stats.wickets * rules.wicket;
    metricsPoints += wicketPoints;
    breakdown.wickets = wicketPoints;
  }
  if (stats.lbwOrBowled > 0) {
    const bonus = stats.lbwOrBowled * rules.lbw_bowled;
    metricsPoints += bonus;
    breakdown.lbw_bowled = bonus;
  }
  if (stats.wickets >= 5) {
    metricsPoints += rules.five_wickets;
    breakdown.five_wickets = rules.five_wickets;
  } else if (stats.wickets >= 4) {
    metricsPoints += rules.four_wickets;
    breakdown.four_wickets = rules.four_wickets;
  } else if (stats.wickets >= 3) {
    metricsPoints += rules.three_wickets;
    breakdown.three_wickets = rules.three_wickets;
  }
  if (stats.maidens > 0) {
    const maidenPoints = stats.maidens * rules.maiden;
    metricsPoints += maidenPoints;
    breakdown.maidens = maidenPoints;
  }
  if (stats.catches > 0) {
    const catchPoints = stats.catches * rules.catch;
    metricsPoints += catchPoints;
    breakdown.catches = catchPoints;
  }
  if (stats.stumpings > 0) {
    const stumpingPoints = stats.stumpings * rules.stump;
    metricsPoints += stumpingPoints;
    breakdown.stumpings = stumpingPoints;
  }
  if (stats.runOuts > 0) {
    const runOutPoints = stats.runOuts * rules.runout;
    metricsPoints += runOutPoints;
    breakdown.run_outs = runOutPoints;
  }
  return {
    stats: metricsPoints,
    breakdown,
    format_used: format
  };
}
__name(calculateStatsMetrics, "calculateStatsMetrics");
function isPrioritySeries2(seriesName) {
  if (!seriesName) return false;
  const s = seriesName.toUpperCase();
  if (s.includes("WORLD CUP")) return true;
  if (s.includes("T20 WORLD CUP")) return true;
  if (s.includes("CHAMPIONS TROPHY")) return true;
  if (s.includes("ASIA CUP")) return true;
  if (s.includes("IPL") || s.includes("INDIAN PREMIER")) return true;
  if (s.includes("PSL") || s.includes("PAKISTAN SUPER")) return true;
  if (s.includes("BBL") || s.includes("BIG BASH")) return true;
  if (s.includes("THE HUNDRED")) return true;
  if (s.includes("WPL") || s.includes("WOMEN'S PREMIER")) return true;
  return false;
}
__name(isPrioritySeries2, "isPrioritySeries");
async function syncMatchMetricsToD1(matchId, env) {
  const API_LOCK_ACTIVE2 = true;
  if (API_LOCK_ACTIVE2) {
    console.log(`[API_LOCK_ACTIVE] Points sync skip: ${matchId}`);
    return 0;
  }
  console.log("STATS_METRICS_V5");
  const match = await env.DB.prepare("SELECT status, start_time, title FROM matches WHERE id = ?").bind(matchId).first();
  if (!match) return 0;
  if (!isPrioritySeries2(match.title)) {
    return 0;
  }
  const now = Date.now();
  const startTime = match.start_time;
  const eightHours = 8 * 60 * 60 * 1e3;
  const twentyMins = 20 * 60 * 1e3;
  if (match.status === "Completed" || match.status === "Abandoned") {
    console.log(`\u23ED\uFE0F Skipping ${matchId}: Status is ${match.status}`);
    return 0;
  }
  const isLiveViable = match.status === "Live" && now < startTime + 12 * 60 * 60 * 1e3;
  const isUpcomingViable = match.status === "Upcoming" && now > startTime - twentyMins;
  if (!isLiveViable && !isUpcomingViable) {
    return 0;
  }
  console.log(`\u{1F4CA} Syncing Informational Stats for Match ${matchId} (Status: ${match.status})...`);
  const apiKey = env.RAPID_API_KEY;
  const apiHost = "cricbuzz-cricket.p.rapidapi.com";
  try {
    const resp = await fetch(`https://${apiHost}/mcenter/v1/${matchId}/scard`, {
      headers: { "x-rapidapi-key": apiKey, "x-rapidapi-host": apiHost }
    });
    if (!resp.ok) throw new Error(`API Error: ${resp.status}`);
    const data = await resp.json();
    if (data.status && (data.status.toLowerCase().includes("complete") || data.status.toLowerCase().includes("result"))) {
      console.log(`\u2705 Match ${matchId} Completed in API. Updating DB Status.`);
      await env.DB.prepare("UPDATE matches SET status = 'Completed' WHERE id = ?").bind(matchId).run();
    }
    const playerStats = extractPlayerStatsFromScorecard(data);
    console.log(`Found stats for ${playerStats.length} players in scorecard.`);
    let commentary = [];
    try {
      const commResp = await fetch(`https://${apiHost}/mcenter/v1/${matchId}/comm`, {
        headers: { "x-rapidapi-key": apiKey, "x-rapidapi-host": apiHost }
      });
      if (commResp.ok) {
        const commData = await commResp.json();
        commentary = (commData.commentaryList || []).slice(0, 20);
      }
    } catch (commErr) {
      console.error("Failed to fetch commentary:", commErr);
    }
    const queries = [];
    for (const stats of playerStats) {
      const fantasy = calculateStatsMetrics(stats, "T20");
      queries.push(
        env.DB.prepare(`
                    INSERT INTO stats_metrics (match_id, player_id, points, breakdown)
                    VALUES (?, ?, ?, ?)
                    ON CONFLICT(match_id, player_id) DO UPDATE SET
                        points = excluded.points,
                        breakdown = excluded.breakdown
                `).bind(matchId, stats.playerId, fantasy.stats, JSON.stringify(fantasy.breakdown))
      );
    }
    if (queries.length > 0) {
      await env.DB.batch(queries);
      console.log(`\u2705 Updated Informational Stats for ${queries.length} players in D1.`);
    }
    try {
      const details = processScorecardData(data);
      await env.DB.prepare(`
                INSERT INTO live_scores (match_id, status_note, team_a_score, team_b_score, current_over, score_details, commentary, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(match_id) DO UPDATE SET
                    status_note = excluded.status_note,
                    team_a_score = excluded.team_a_score,
                    team_b_score = excluded.team_b_score,
                    current_over = excluded.current_over,
                    score_details = excluded.score_details,
                    commentary = excluded.commentary,
                    updated_at = excluded.updated_at
            `).bind(
        matchId,
        details.status,
        details.team1Score,
        details.team2Score,
        details.overs,
        JSON.stringify(details.fullData),
        JSON.stringify(commentary),
        Date.now()
      ).run();
    } catch (scoreErr) {
      console.error("Failed to update live_scores in cron:", scoreErr);
    }
    try {
      if (playerStats.length > 0) {
        await updatePlayingXI(matchId, playerStats, env);
      }
    } catch (xiErr) {
      console.error("Failed to update playing XI:", xiErr);
    }
    return playerStats.length;
  } catch (e) {
    console.error(`Points Sync Failed for ${matchId}:`, e);
    return 0;
  }
}
__name(syncMatchMetricsToD1, "syncMatchMetricsToD1");
async function updatePlayingXI(matchId, playerStats, env) {
  const squadData = await env.DB.prepare("SELECT team_a_roster, team_b_roster FROM match_squads WHERE match_id = ?").bind(matchId).first();
  if (!squadData) return;
  const rosterA = JSON.parse(squadData.team_a_roster || "[]");
  const rosterB = JSON.parse(squadData.team_b_roster || "[]");
  const idSet = new Set(playerStats.map((p) => String(p.playerId)));
  const xiA = rosterA.filter((p) => idSet.has(String(p.id)));
  const xiB = rosterB.filter((p) => idSet.has(String(p.id)));
  if (xiA.length === 0 && xiB.length === 0) return;
  console.log(`Updating Playing XI for ${matchId}: A=${xiA.length}, B=${xiB.length}`);
  await env.DB.prepare(`
        UPDATE match_squads 
        SET playing_11_a = ?, playing_11_b = ?
        WHERE match_id = ?
    `).bind(
    JSON.stringify(xiA),
    JSON.stringify(xiB),
    matchId
  ).run();
}
__name(updatePlayingXI, "updatePlayingXI");
function extractPlayerStatsFromScorecard(data) {
  const stats = [];
  if (!data || !data.scorecard) return stats;
  data.scorecard.forEach((inning) => {
    if (inning.batsman && Array.isArray(inning.batsman)) {
      inning.batsman.forEach((b) => {
        let existing = stats.find((s) => s.playerId === b.id);
        if (!existing) {
          existing = {
            playerId: b.id,
            name: b.name,
            runs: 0,
            fours: 0,
            sixes: 0,
            wickets: 0,
            catches: 0,
            role: "Batsman"
          };
          stats.push(existing);
        }
        existing.runs = parseInt(b.runs || 0);
        existing.fours = parseInt(b.fours || 0);
        existing.sixes = parseInt(b.sixes || 0);
        existing.isOut = b.outDesc !== "not out" && b.outDec !== "not out";
        if (b.outdec) existing.isOut = b.outdec !== "not out";
      });
    } else if (inning.batTeamDetails && inning.batTeamDetails.batsmenData) {
      Object.values(inning.batTeamDetails.batsmenData).forEach((b) => {
        let existing = stats.find((s) => s.playerId === b.batId);
        if (!existing) {
          existing = {
            playerId: b.batId,
            name: b.outDesc || "Batsman",
            runs: 0,
            fours: 0,
            sixes: 0,
            wickets: 0,
            catches: 0,
            role: "Batsman"
          };
          stats.push(existing);
        }
        existing.runs = parseInt(b.runs || 0);
        existing.fours = parseInt(b.fours || 0);
        existing.sixes = parseInt(b.sixes || 0);
        existing.isOut = b.outDesc && b.outDesc !== "not out";
      });
    }
    if (inning.bowler && Array.isArray(inning.bowler)) {
      inning.bowler.forEach((b) => {
        let existing = stats.find((s) => s.playerId === b.id);
        const bowlStats = {
          playerId: b.id,
          wickets: parseInt(b.wickets || 0),
          maidens: parseInt(b.maidens || 0),
          overs: parseFloat(b.overs || 0),
          lbwOrBowled: 0
        };
        if (existing) {
          Object.assign(existing, bowlStats);
        } else {
          stats.push({ ...bowlStats, name: b.name || "Bowler", role: "Bowler", runs: 0, fours: 0, sixes: 0, isOut: false, catches: 0 });
        }
      });
    } else if (inning.bowlTeamDetails && inning.bowlTeamDetails.bowlersData) {
      Object.values(inning.bowlTeamDetails.bowlersData).forEach((b) => {
        let existing = stats.find((s) => s.playerId === b.bowlerId);
        const bowlStats = {
          playerId: b.bowlerId,
          wickets: parseInt(b.wickets || 0),
          maidens: parseInt(b.maidens || 0),
          overs: parseFloat(b.overs || 0),
          lbwOrBowled: 0
        };
        if (existing) {
          Object.assign(existing, bowlStats);
        } else {
          stats.push({ ...bowlStats, name: "Bowler", role: "Bowler", runs: 0, fours: 0, sixes: 0, isOut: false, catches: 0 });
        }
      });
    }
  });
  return stats;
}
__name(extractPlayerStatsFromScorecard, "extractPlayerStatsFromScorecard");
function processScorecardData(data) {
  let status = data.status || "";
  let t1Score = "";
  let t2Score = "";
  let overs = "";
  const innings = data.scorecard || [];
  const t1Inning = innings.find((i) => i.inningsId === 1 || i.inningsid === 1);
  const t2Inning = innings.find((i) => i.inningsId === 2 || i.inningsid === 2);
  if (t1Inning) {
    t1Score = `${t1Inning.runs || 0}/${t1Inning.wickets || 0} (${t1Inning.overs || 0})`;
  }
  if (t2Inning) {
    t2Score = `${t2Inning.runs || 0}/${t2Inning.wickets || 0} (${t2Inning.overs || 0})`;
    status = "2nd Innings";
  }
  const fullData = {
    summary: {
      team1: t1Inning ? { runs: t1Inning.runs, wickets: t1Inning.wickets, overs: t1Inning.overs } : {},
      team2: t2Inning ? { runs: t2Inning.runs, wickets: t2Inning.wickets, overs: t2Inning.overs } : {}
    },
    innings,
    // Pass full innings array (batsmen, bowlers)
    status
  };
  return {
    status: data.status,
    // Keep original status
    team1Score: t1Score,
    team2Score: t2Score,
    overs,
    fullData
  };
}
__name(processScorecardData, "processScorecardData");

// workers/index.js
init_squad_engine();

// workers/load_test_engine.js
init_checked_fetch();
init_modules_watch_stub();
async function executeLoadTest(request, env) {
  const start = Date.now();
  const url = new URL(request.url);
  const batchSize = parseInt(url.searchParams.get("batch") || "10");
  const contestId = "LOAD_TEST_CONTEST_001";
  if (!contestId.startsWith("LOAD_TEST")) {
    return new Response("ABORTED: Unsafe Contest ID", { status: 403 });
  }
  const statements = [];
  const userIds = [];
  for (let i = 0; i < batchSize; i++) {
    const userId = `TEST_USER_${Date.now()}_${Math.random().toString(36).substring(7)}`;
    userIds.push(userId);
    statements.push(env.DB.prepare(`
            INSERT INTO test_participants (id, contest_id, user_id, joined_at)
            VALUES (?, ?, ?, ?)
        `).bind(
      crypto.randomUUID(),
      contestId,
      userId,
      Date.now()
    ));
  }
  statements.push(env.DB.prepare(`
        UPDATE test_contests 
        SET filled_spots = filled_spots + ? 
        WHERE id = ?
    `).bind(batchSize, contestId));
  try {
    const results = await env.DB.batch(statements);
    const duration = Date.now() - start;
    return new Response(JSON.stringify({
      success: true,
      message: `Inserted ${batchSize} participants into SANDBOX.`,
      duration_ms: duration,
      users: userIds.slice(0, 3)
      // sample
    }), { headers: { "Content-Type": "application/json" } });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), { status: 500 });
  }
}
__name(executeLoadTest, "executeLoadTest");

// workers/player_stats_engine.js
init_checked_fetch();
init_modules_watch_stub();
async function processPlayerStats(env) {
  const API_LOCK_ACTIVE2 = true;
  if (API_LOCK_ACTIVE2) {
    console.log("[API_LOCK_ACTIVE] Player stats skip \u2014 lock active.");
    return { processed: 0, logs: ["LOCK_ACTIVE"] };
  }
  const logs = [];
  logs.push("\u{1F4CA} Player Stats Engine Started...");
  const apiKey = "70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee";
  const apiHost = "cricbuzz-cricket.p.rapidapi.com";
  try {
    const now = Date.now();
    const twoDays = 48 * 60 * 60 * 1e3;
    const sevenDays = 7 * 24 * 60 * 60 * 1e3;
    const matches = await env.DB.prepare(`
            SELECT id FROM matches 
            WHERE status = 'Upcoming' AND start_time < ?
        `).bind(now + twoDays).all();
    if (!matches.results || matches.results.length === 0) {
      logs.push("\u2705 No upcoming matches in 48h window.");
      return { processed: 0, logs };
    }
    const matchIds = matches.results.map((m) => m.id);
    const targetMatchIds = matchIds.slice(0, 5);
    const placeholders = targetMatchIds.map(() => "?").join(",");
    const squads = await env.DB.prepare(`
            SELECT team_a_roster, team_b_roster FROM match_squads 
            WHERE match_id IN (${placeholders})
        `).bind(...targetMatchIds).all();
    const candidates = /* @__PURE__ */ new Set();
    for (const row of squads.results) {
      const teamA = JSON.parse(row.team_a_roster || "[]");
      const teamB = JSON.parse(row.team_b_roster || "[]");
      teamA.forEach((p) => candidates.add(p.id));
      teamB.forEach((p) => candidates.add(p.id));
    }
    const candidateArray = Array.from(candidates);
    if (candidateArray.length === 0) {
      logs.push("\u2705 No players found in upcoming squads.");
      return { processed: 0, logs };
    }
    const playersToUpdate = [];
    for (let i = 0; i < candidateArray.length; i += 50) {
      const batch2 = candidateArray.slice(i, i + 50);
      const batchPlaceholders = batch2.map(() => "?").join(",");
      const existing = await env.DB.prepare(`
                SELECT player_id, last_updated FROM player_stats 
                WHERE player_id IN (${batchPlaceholders})
            `).bind(...batch2).all();
      const existingMap = /* @__PURE__ */ new Map();
      existing.results.forEach((r) => existingMap.set(r.player_id, r.last_updated));
      for (const pid of batch2) {
        const lastUpdated = existingMap.get(pid);
        if (!lastUpdated || now - lastUpdated > sevenDays) {
          playersToUpdate.push(pid);
        }
      }
    }
    logs.push(`\u{1F50D} Found ${playersToUpdate.length} players needing stats update.`);
    const batch = playersToUpdate.slice(0, 10);
    if (batch.length === 0) {
      logs.push("\u2705 All player stats are up to date.");
      return { processed: 0, logs };
    }
    logs.push(`\u{1F680} Processing Batch: ${batch.join(", ")}`);
    for (const pid of batch) {
      try {
        const url = `https://${apiHost}/stats/v1/player/${pid}`;
        const resp = await fetch(url, {
          headers: { "x-rapidapi-key": apiKey, "x-rapidapi-host": apiHost }
        });
        if (!resp.ok) {
          logs.push(`\u274C Failed to fetch ${pid}: ${resp.status}`);
          continue;
        }
        const data = await resp.json();
        const { rating, credits } = calculateRating(data);
        const role = normalizeRole(data.role);
        await env.DB.prepare(`
                    INSERT INTO player_stats (player_id, fantasy_rating, credits, role_normalized, last_updated)
                    VALUES (?, ?, ?, ?, ?)
                    ON CONFLICT(player_id) DO UPDATE SET
                        fantasy_rating = excluded.fantasy_rating,
                        credits = excluded.credits,
                        role_normalized = excluded.role_normalized,
                        last_updated = excluded.last_updated
                `).bind(pid, rating, credits, role, now).run();
        logs.push(`\u2705 Saved ${pid}: Rating=${rating}, Credits=${credits}`);
      } catch (e) {
        logs.push(`\u26A0\uFE0F Error processing ${pid}: ${e.message}`);
      }
    }
    return { processed: batch.length, logs };
  } catch (e) {
    console.error("Stats Engine Error:", e);
    return { processed: 0, error: e.message, logs };
  }
}
__name(processPlayerStats, "processPlayerStats");
function calculateRating(data) {
  let rating = 50;
  let credits = 8.5;
  try {
    let impactScore = 0;
    if (data.bat && Array.isArray(data.bat)) {
      const t20 = data.bat.find((x) => x.category === "T20" || x.category === "T20I");
      if (t20) {
        const avg = parseFloat(t20.avg || 0);
        const sr = parseFloat(t20.sr || 0);
        impactScore += avg * 0.5 + sr * 0.1;
      }
    }
    if (data.bowl && Array.isArray(data.bowl)) {
      const t20 = data.bowl.find((x) => x.category === "T20" || x.category === "T20I");
      if (t20) {
        const wkt = parseFloat(t20.wickets || 0);
        const eco = parseFloat(t20.eco || 8);
        const avg = parseFloat(t20.avg || 25);
        impactScore += 30 - avg + (10 - eco) * 3;
      }
    }
    if (impactScore < 20) impactScore = 40 + Math.random() * 10;
    if (impactScore > 100) impactScore = 95;
    rating = parseFloat(impactScore.toFixed(1));
    credits = 8 + (rating - 40) * 0.0416;
    credits = Math.min(10.5, Math.max(8, credits));
    credits = Math.round(credits * 2) / 2;
  } catch (e) {
  }
  return { rating, credits };
}
__name(calculateRating, "calculateRating");
function normalizeRole(rawRole) {
  if (!rawRole) return "BAT";
  const r = rawRole.toUpperCase();
  if (r.includes("WK") || r.includes("KEEPER")) return "WK";
  if (r.includes("ALL") || r.includes("ROUND")) return "AR";
  if (r.includes("BOWL")) return "BOWL";
  return "BAT";
}
__name(normalizeRole, "normalizeRole");

// workers/index.js
var corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "*"
};
var workers_default = {
  async scheduled(event, env, ctx) {
    console.log("CRON ENTRY START");
    console.log("\u23F0 Scheduled Event Triggered", (/* @__PURE__ */ new Date()).toISOString());
    const safeRun = /* @__PURE__ */ __name(async (name, fn) => {
      try {
        await fn();
      } catch (e) {
        console.error(`${name}_FATAL_ERROR`, e);
      }
    }, "safeRun");
    await safeRun("UPCOMING_SEED_ENGINE", () => seedUpcomingMatches(env));
    await safeRun("SQUAD_WARMUP_ENGINE", () => warmupMissingUpcomingSquads(env));
    ctx.waitUntil(safeRun("CRICKET_ENGINE", () => processCricketData(env)));
    ctx.waitUntil(safeRun("PLAYER_STATS_ENGINE", () => processPlayerStats(env)));
    ctx.waitUntil(safeRun("REPAIR_QUEUE", () => processRepairQueue(env)));
    ctx.waitUntil(safeRun("SQUAD_ENGINE", async () => {
      const { results: dbMatches } = await env.DB.prepare(
        "SELECT id, series_id, status, title FROM matches WHERE status IN ('Live', 'In Progress', 'Upcoming') LIMIT 20"
      ).all();
      await processSquads(dbMatches || [], env, env.RAPID_API_KEY, "cricbuzz-cricket.p.rapidapi.com");
    }));
  },
  async fetch(request, env, ctx) {
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: {
          ...corsHeaders,
          "Access-Control-Max-Age": "86400"
        }
      });
    }
    try {
      const url = new URL(request.url);
      const path = url.pathname.replace(/\/$/, "");
      console.log(`Debug Request: ${path}`);
      if (path.startsWith("/v/r/")) {
        const matchId = path.split("/").pop();
        return await handleSocialPreview(matchId, env);
      }
      if (path === "/api/test-force-sync") {
        const mid = url.searchParams.get("matchId");
        if (!mid) return new Response("Missing matchId", { status: 400 });
        const count = await syncMatchMetricsToD1(mid, env);
        return new Response(`Synced ${count} players for ${mid}`, { status: 200 });
      }
      if (path === "/api/test-squad-sync") {
        const mid = url.searchParams.get("matchId");
        const source = url.searchParams.get("source");
        if (!mid) return new Response("Missing matchId", { status: 400 });
        const result = await syncMatchSquad(mid, env, source);
        return new Response(JSON.stringify(result, null, 2), {
          status: 200,
          headers: { "Content-Type": "application/json" }
        });
      }
      if (url.pathname === "/api/ranking") return jsonResponse({ success: false, error: "RANKING_RESTRICTED", message: "Rankings are only available inside Private Rooms for informational purposes." }, 403);
      if (url.pathname === "/api/teams/save") return await handleSaveTeam(request, env);
      if (url.pathname === "/api/teams/get") return await handleGetTeams(url.searchParams, env);
      if (url.pathname === "/api/room/ranking") return await handleGetRoomRanking(url.searchParams, env);
      if (path === "/" || path === "") return new Response("AxevoraLabs Social Interaction API - v3.0", { status: 200 });
      if (path === "/terms" || path === "/terms-and-conditions") return handleStaticPage("terms");
      if (path === "/refund" || path === "/refund-policy" || path === "/cancellation") return handleStaticPage("refund");
      if (path === "/privacy" || path === "/privacy-policy") return handleStaticPage("privacy");
      if (path === "/contact" || path === "/contact-us") return handleStaticPage("contact");
      if (path === "/matches" || path === "/api/get-matches" || path === "/api/matches") return handleGetMatches(env);
      if (path === "/matches/refresh" || path === "/api/refresh-matches") {
        const matches = await processCricketData(env);
        return jsonResponse({ success: true, message: "Triggered D1 Update", matches });
      }
      const clientIP = request.headers.get("CF-Connecting-IP") || "0.0.0.0";
      const country = request.cf?.country || "XX";
      if (path === "/test-squad-sync") {
      } else if (path !== "/health" && !path.startsWith("/api/public")) {
      }
      if (path === "/api/test/load-gen") {
        return await executeLoadTest(request, env);
      }
      if (path === "/scorecard" || path.startsWith("/api/scorecard")) {
        const matchId = url.searchParams.get("matchId") || path.split("/").pop();
        return handleGetScorecard(matchId, env);
      }
      if (path === "/squads" || path === "/api/squads") return handleGetSquads(url.searchParams.get("matchId"), env, request);
      if (path === "/api/player-image" || path === "/player-image") {
        const imageUrl = url.searchParams.get("url");
        if (!imageUrl) {
          return jsonResponse({ success: false, error: "Missing url parameter" }, 400);
        }
        try {
          const imageResp = await fetch(imageUrl, {
            headers: {
              "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
              "Accept": "image/*"
            }
          });
          if (!imageResp.ok) {
            return new Response("Image not found", { status: 404, headers: corsHeaders });
          }
          return new Response(imageResp.body, {
            headers: {
              ...corsHeaders,
              "Content-Type": imageResp.headers.get("Content-Type") || "image/jpeg",
              "Cache-Control": "public, max-age=86400"
              // Cache for 24 hours
            }
          });
        } catch (e) {
          console.error("Image Proxy Error:", e);
          return new Response("Failed to fetch image", { status: 500, headers: corsHeaders });
        }
      }
      if (path === "/api/ranking") {
        return jsonResponse({ success: false, error: "RANKING_RESTRICTED", message: "Rankings are only available inside Private Rooms for informational purposes." }, 403);
      }
      if (path === "/api/calc-ranking") {
        await processRankings(env);
        return jsonResponse({ success: true, message: "Ranking Calc Triggered" });
      }
      if (path === "/api/admin/stats") {
        return handleAdminStats(env);
      }
      if (path === "/api/admin/match/squad") return handleAdminSaveSquad(request, env);
      if (path === "/api/admin/match/participants") {
        const matchId = url.searchParams.get("matchId");
        if (!matchId) return jsonResponse({ success: false, error: "matchId required" }, 400);
        return handleGetMatchParticipants(matchId, env);
      }
      if (path === "/api/user/sync") {
        return handleUserSync(request, env);
      }
      if (path === "/api/rooms/create") return await handleCreateRoom(request, env);
      if (path === "/api/rooms" || path === "/api/rooms/list") {
        const matchId = url.searchParams.get("matchId");
        if (!matchId) return jsonResponse({ success: false, error: "matchId required" }, 400);
        return handleGetRooms(matchId, env);
      }
      if (path === "/api/rooms/join" || path === "/api/join-room") return handleJoinRoom(request, env);
      if (path === "/api/rooms/joined") {
        const uid = url.searchParams.get("userId");
        if (!uid) return jsonResponse({ error: "userId required" }, 400);
        return handleGetUserRooms(uid.trim(), env);
      }
      if (path === "/api/room") {
        const roomId = url.searchParams.get("roomId");
        if (!roomId) return jsonResponse({ success: false, error: "roomId required" }, 400);
        return handleGetRoomById(roomId, env);
      }
      if (path.startsWith("/api/room/")) {
        const roomId = path.split("/").pop();
        return handleGetRoomById(roomId, env);
      }
      if (path === "/api/user/rooms") {
        const userId = url.searchParams.get("userId");
        if (!userId) return jsonResponse({ success: false, error: "userId required" }, 400);
        return handleGetUserRooms(userId, env);
      }
      if (path === "/api/chat/send") return await handleSendChatMessage(request, env);
      if (path === "/api/chat/sync" || path === "/api/chat/messages") {
        const roomId = url.searchParams.get("roomId");
        const lastUpdated = url.searchParams.get("after") || "0";
        if (!roomId) return jsonResponse({ success: false, error: "roomId required" }, 400);
        return handleSyncChatMessages(roomId, lastUpdated, env);
      }
      if (path === "/diag") return handleGlobalDiag(env);
      if (path === "/stats-metrics") return handleGetStatsMetrics(url.searchParams.get("match_id"), env);
      if (path === "/debug-api" || path === "/api/debug-api") return handleDebugApi(env);
      if (path === "/api/matches" || path === "/api/v2/matches") {
        return handleGetMatches(env);
      }
      if (path.startsWith("/api/")) {
        return jsonResponse({ success: false, error: `API Route Not Found: ${path}` }, 404);
      }
      console.log(`\u26A0\uFE0F Unhandled route: ${path} [${request.method}]`);
      return new Response("AxevoraLabs Social Interaction Worker - Access Denied", { status: 403, headers: corsHeaders });
    } catch (e) {
      return new Response(`Worker Error: ${e.message}`, { status: 500, headers: corsHeaders });
    }
  }
};
async function handleGetMatches(env) {
  try {
    const { results } = await env.DB.prepare(`
            SELECT id, series_id, series_name, title, short_title, status, start_time, team_a, team_b, team_a_img, team_b_img, team_a_id, team_b_id, last_updated, last_score, last_wickets, last_over, last_innings 
            FROM matches 
            WHERE status IN ('Live', 'In Progress', 'Innings Break', 'Upcoming', 'Completed', 'Abandoned')
            ORDER BY 
                CASE status 
                    WHEN 'Live' THEN 1 
                    WHEN 'In Progress' THEN 2 
                    WHEN 'Innings Break' THEN 3
                    WHEN 'Upcoming' THEN 4 
                    ELSE 5 
                END, 
                start_time ASC 
            LIMIT 50
        `).all();
    const activeMatches = (results || []).filter((m) => {
      const fullText = `${m.team_a || ""} ${m.team_b || ""} ${m.title || ""} ${m.series_name || ""}`.toUpperCase();
      const isPremium = [
        "IPL",
        "INDIAN PREMIER LEAGUE",
        "BBL",
        "BIG BASH",
        "PSL",
        "PAKISTAN SUPER LEAGUE",
        "BPL",
        "BANGLADESH PREMIER LEAGUE",
        "SA20",
        "CPL",
        "HUNDRED",
        "WPL",
        "WORLD CUP",
        "ICC",
        "ASIA CUP",
        "CHAMPIONS TROPHY",
        "T20I",
        "ODI",
        "TEST",
        "WOMEN'S T20",
        "WOMEN'S ODI"
      ].some((kw) => fullText.includes(kw));
      const isExcluded = [
        "DOMESTIC",
        "SHIELD",
        "PLUNKET",
        "RANJI",
        "BLAST",
        "CHALLENGER",
        "TROPHY",
        "CUP",
        "LEAGUE"
      ].some((kw) => {
        if (kw === "TROPHY" && fullText.includes("CHAMPIONS TROPHY")) return false;
        if (kw === "CUP" && (fullText.includes("WORLD CUP") || fullText.includes("ASIA CUP"))) return false;
        if (kw === "LEAGUE" && (fullText.includes("PREMIER LEAGUE") || fullText.includes("SUPER LEAGUE") || fullText.includes("BIG BASH LEAGUE"))) return false;
        return fullText.includes(kw);
      });
      return isPremium && !isExcluded;
    });
    const matches = activeMatches.map((m) => ({
      id: m.id,
      seriesId: m.series_id,
      seriesName: m.series_name,
      matchDesc: m.title,
      matchFormat: "T20",
      // Default or fetch from db if added later
      startDate: m.start_time,
      endDate: m.start_time + 144e5,
      status: m.status,
      team1Name: m.team_a,
      team2Name: m.team_b,
      team1ShortName: m.team_a,
      team2ShortName: m.team_b,
      team1Id: m.team_a_id,
      team2Id: m.team_b_id,
      teamAImg: m.team_a_img,
      teamBImg: m.team_b_img,
      lastScore: m.last_score,
      lastWickets: m.last_wickets,
      lastOver: m.last_over,
      lastInnings: m.last_innings
    }));
    return jsonResponse({
      success: true,
      matches
    });
  } catch (e) {
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleGetMatches, "handleGetMatches");
async function handleDebugApi(env) {
  const key = env.RAPID_API_KEY;
  const hosts = [
    { name: "LiveScore6", host: "livescore6.p.rapidapi.com", path: "/matches/v2/list-live?Category=cricket" }
  ];
  let results = {};
  for (const h of hosts) {
    try {
      const start = Date.now();
      const url = `https://${h.host}${h.path}`;
      const resp = await fetch(url, {
        headers: { "x-rapidapi-key": key, "x-rapidapi-host": h.host }
      });
      let dataPreview = "No Body";
      let parseDebug = {};
      try {
        const data = await resp.json();
        const stages = data.Stages || [];
        const firstStage = stages[0] || {};
        const events = firstStage.Events || [];
        const firstEvent = events[0] || {};
        parseDebug = {
          hasStages: !!data.Stages,
          stagesCount: stages.length,
          firstStageEvents: events.length,
          sampleEventKeys: Object.keys(firstEvent),
          hasT1: !!firstEvent.T1,
          hasT2: !!firstEvent.T2,
          t1Name: firstEvent.T1 ? firstEvent.T1[0]?.Nm : "N/A",
          eid: firstEvent.Eid
        };
        dataPreview = JSON.stringify(data).substring(0, 500) + "...";
      } catch (e) {
        dataPreview = "Indigestible JSON: " + e.message;
      }
      results[h.name] = {
        status: resp.status,
        ok: resp.ok,
        latency: Date.now() - start,
        parseDebug,
        dataPreview
        // Longer preview
      };
    } catch (e) {
      results[h.name] = { error: e.message };
    }
  }
  return jsonResponse({
    success: true,
    env_key_preview: key ? key.substring(0, 5) + "..." : "MISSING",
    results
  });
}
__name(handleDebugApi, "handleDebugApi");
async function handleAdminStats(env) {
  try {
    const matchesCount = await env.DB.prepare("SELECT COUNT(*) as c FROM matches WHERE status='Live'").first();
    const upcomingCount = await env.DB.prepare("SELECT COUNT(*) as c FROM matches WHERE status='Upcoming'").first();
    const contestsCount = await env.DB.prepare("SELECT COUNT(*) as c FROM contests").first();
    const usersCount = await env.DB.prepare("SELECT COUNT(*) as c FROM users").first();
    return jsonResponse({
      success: true,
      stats: {
        liveMatches: matchesCount?.c || 0,
        upcomingMatches: upcomingCount?.c || 0,
        activeContests: contestsCount?.c || 0,
        totalUsers: usersCount?.c || 0,
        // Payouts/KYC are financial, still Firestore-bound for now, or 0
        pendingPayouts: 0,
        kycPending: 0
      }
    });
  } catch (e) {
    return jsonResponse({ success: false, error: e.message });
  }
}
__name(handleAdminStats, "handleAdminStats");
async function handleGetMatchParticipants(matchId, env) {
  try {
    const { results } = await env.DB.prepare(`
            SELECT p.user_id, p.team_name, p.match_id, u.email 
            FROM contest_participants p 
            JOIN users u ON p.user_id = u.id 
            WHERE p.match_id = ?
            `).bind(matchId.toString()).all();
    return jsonResponse({ success: true, participants: results });
  } catch (e) {
    return jsonResponse({ success: false, error: e.message });
  }
}
__name(handleGetMatchParticipants, "handleGetMatchParticipants");
async function handleGetScorecard(matchId, env) {
  try {
    const score = await env.DB.prepare("SELECT * FROM live_scores WHERE match_id = ?").bind(matchId).first();
    if (score) {
      return jsonResponse({ success: true, scorecard: score, source: "D1_CACHE" });
    }
    return jsonResponse({ success: false, error: "Scorecard not available yet", source: "D1_MISSING" });
  } catch (error) {
    return jsonResponse({ success: false, error: error.message });
  }
}
__name(handleGetScorecard, "handleGetScorecard");
var SQUAD_CACHE = /* @__PURE__ */ new Map();
async function handleGetSquads(rawMatchId, env, request) {
  try {
    const matchIdStr = String(rawMatchId || "").trim();
    if (!matchIdStr) return jsonResponse({ success: false, error: "matchId required" });
    const matchId = Number(matchIdStr);
    const now = Date.now();
    if (SQUAD_CACHE.has(matchIdStr)) {
      const cached = SQUAD_CACHE.get(matchIdStr);
      if (now - cached.ts < 6e4) {
        return jsonResponse({
          success: true,
          source: "WORKER_MEM_CACHE",
          ...cached.data
        });
      }
    }
    const matchStatus = await env.DB.prepare("SELECT status FROM matches WHERE CAST(id AS INTEGER) = CAST(? AS INTEGER)").bind(matchId).first();
    if (matchStatus && (matchStatus.status !== "Upcoming" && matchStatus.status !== "Live")) {
      return jsonResponse({
        success: false,
        reason: "MATCH_NOT_EDITABLE",
        error: "Match is completed or abandoned"
      });
    }
    const d1Squad = await env.DB.prepare(
      "SELECT team_a_roster, team_b_roster, playing_11_a, playing_11_b, last_updated FROM match_squads WHERE CAST(match_id AS INTEGER) = CAST(? AS INTEGER)"
    ).bind(matchId).first();
    let matchInfo = await env.DB.prepare("SELECT team_a_id, team_b_id FROM matches WHERE CAST(id AS INTEGER) = CAST(? AS INTEGER)").bind(matchId).first();
    const team1Id = matchInfo?.team_a_id || "0";
    const team2Id = matchInfo?.team_b_id || "0";
    if (!d1Squad || !d1Squad.team_a_roster) {
      return generateDummySquad(matchId, team1Id, team2Id);
    }
    const rawTeamA = JSON.parse(d1Squad.team_a_roster || "[]");
    const rawTeamB = JSON.parse(d1Squad.team_b_roster || "[]");
    const rawXiA = JSON.parse(d1Squad.playing_11_a || "[]");
    const rawXiB = JSON.parse(d1Squad.playing_11_b || "[]");
    const normalizePlayer = /* @__PURE__ */ __name((p) => {
      const id = p.player_id || p.id || "";
      return {
        id,
        player_id: id,
        name: p.name || "Unknown",
        team_id: p.team_id || p.teamId || "",
        role: p.role || "BAT",
        // Default to BAT if not specified
        credits: p.credits || 9,
        // Default to 9 if 0 or missing
        is_playing: !!p.is_playing,
        imageUrl: p.imageUrl ? p.imageUrl : p.image_id ? `https://static.cricbuzz.com/a/img/v1/i1/c${p.image_id}/i.jpg` : ""
      };
    }, "normalizePlayer");
    const normTeamA = rawTeamA.map(normalizePlayer);
    const normTeamB = rawTeamB.map(normalizePlayer);
    const normXiA = rawXiA.map(normalizePlayer);
    const normXiB = rawXiB.map(normalizePlayer);
    console.log("RAW_D1_DATA", normTeamA.length, normTeamB.length);
    const allMap = /* @__PURE__ */ new Map();
    [...normTeamA, ...normTeamB, ...normXiA, ...normXiB].forEach((p) => {
      const pid = p.player_id || p.id;
      if (pid) allMap.set(pid, p);
    });
    const allIds = Array.from(allMap.keys());
    let statsMap = /* @__PURE__ */ new Map();
    if (allIds.length > 0) {
      const placeholders = allIds.map(() => "?").join(",");
      const stats = await env.DB.prepare(`
                SELECT player_id, fantasy_rating, credits, role_normalized 
                FROM player_stats WHERE player_id IN (${placeholders})
            `).bind(...allIds).all();
      if (stats.results) {
        stats.results.forEach((s) => statsMap.set(s.player_id, s));
      }
    }
    const enrich = /* @__PURE__ */ __name((p) => {
      const pid = p.player_id || p.id || "";
      const stat = statsMap.get(pid);
      const pidHash = simpleHash(pid);
      const role = p.role || stat?.role_normalized || "BAT";
      let credits = 8;
      let rating = 50;
      if (stat) {
        credits = stat.credits || 8;
        rating = stat.fantasy_rating || 50;
      } else {
        const baseCredit = role === "AR" ? 8.5 : 8;
        credits = baseCredit + pidHash % 6 * 0.5;
        let baseRating = 50;
        if (role === "WK") baseRating = 55;
        if (role === "AR") baseRating = 60;
        if (role === "BOWL") baseRating = 52;
        rating = baseRating + pidHash % 40;
      }
      return {
        id: pid,
        name: p.name,
        role,
        credits,
        fantasy_rating: rating,
        teamId: (p.teamId || (allMap.get(pid) === p ? team1Id : team2Id)).toString(),
        teamShortName: p.teamShortName,
        imageUrl: p.imageUrl,
        isCaptain: p.isCaptain || false,
        isWicketKeeper: role === "WK"
      };
    }, "enrich");
    const finalTeamA = normTeamA.map(enrich);
    const finalTeamB = normTeamB.map(enrich);
    const finalXiA = normXiA.map(enrich);
    const finalXiB = normXiB.map(enrich);
    console.log("AFTER_ROLE_MAP", finalTeamA.length + finalTeamB.length);
    const roleOrder = { "WK": 1, "BAT": 2, "AR": 3, "BOWL": 4 };
    const sorter = /* @__PURE__ */ __name((a, b) => {
      const rA = roleOrder[a.role] || 5;
      const rB = roleOrder[b.role] || 5;
      if (rA !== rB) return rA - rB;
      return a.id.localeCompare(b.id);
    }, "sorter");
    finalTeamA.sort(sorter);
    finalTeamB.sort(sorter);
    finalXiA.sort(sorter);
    finalXiB.sort(sorter);
    const allFinal = [...finalTeamA, ...finalTeamB];
    const grouped = { WK: 0, BAT: 0, AR: 0, BOWL: 0 };
    allFinal.forEach((p) => grouped[p.role] = (grouped[p.role] || 0) + 1);
    console.log("FINAL_API_PLAYERS", grouped.WK, grouped.BAT, grouped.AR, grouped.BOWL);
    const responseData = {
      teamA: finalTeamA,
      teamB: finalTeamB,
      xiA: finalXiA,
      xiB: finalXiB,
      matchId,
      team1Id,
      team2Id
    };
    SQUAD_CACHE.set(matchId, { ts: now, data: responseData });
    return jsonResponse({
      success: true,
      source: "D1_RUNTIME_MERGE",
      ...responseData
    });
  } catch (e) {
    console.error("Squad Error:", e);
    return jsonResponse({ success: false, error: "Internal error: " + e.message }, 200);
  }
}
__name(handleGetSquads, "handleGetSquads");
function simpleHash(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = (hash << 5) - hash + str.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash);
}
__name(simpleHash, "simpleHash");
function generateDummySquad(matchId, t1, t2) {
  return jsonResponse({ success: true, source: "DUMMY", teamA: [], teamB: [], matchId });
}
__name(generateDummySquad, "generateDummySquad");
async function handleAdminSaveSquad(request, env) {
  if (request.method !== "POST") return jsonResponse({ error: "Method Not Allowed" }, 405);
  try {
    const body = await request.json();
    const { matchId, teamA, teamB, xiA, xiB } = body;
    if (!matchId || !teamA || !teamB) {
      return jsonResponse({ success: false, error: "Missing required fields: matchId, teamA, teamB" }, 400);
    }
    const match = await env.DB.prepare("SELECT status FROM matches WHERE id = ?").bind(parseInt(matchId)).first();
    if (!match) return jsonResponse({ success: false, error: "Match not found" }, 404);
    if (match.status !== "Upcoming" && match.status !== "Live") {
      if (match.status !== "Upcoming") {
        return jsonResponse({ success: false, error: "Squad is LOCKED. Match is Live or Completed." }, 403);
      }
    }
    await env.DB.prepare(`
            INSERT INTO match_squads (match_id, team_a_roster, team_b_roster, playing_11_a, playing_11_b, last_updated)
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(match_id) DO UPDATE SET
                team_a_roster = excluded.team_a_roster,
                team_b_roster = excluded.team_b_roster,
                playing_11_a = excluded.playing_11_a,
                playing_11_b = excluded.playing_11_b,
                last_updated = excluded.last_updated
        `).bind(
      matchId,
      JSON.stringify(teamA),
      JSON.stringify(teamB),
      JSON.stringify(xiA || []),
      JSON.stringify(xiB || []),
      Date.now()
    ).run();
    console.log(`\xE2\u0153\u2026 Admin Saved Squad for ${matchId}`);
    return jsonResponse({ success: true, message: "Squad Saved Successfully" });
  } catch (e) {
    console.error("Admin Squad Save Error", e);
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleAdminSaveSquad, "handleAdminSaveSquad");
async function handleGlobalDiag(env) {
  return jsonResponse({ status: "ok" });
}
__name(handleGlobalDiag, "handleGlobalDiag");
function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
      "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
      "Pragma": "no-cache",
      "Expires": "0"
    }
  });
}
__name(jsonResponse, "jsonResponse");
function handleStaticPage(type) {
  let title = "Fantasy Cricket API";
  let content = "";
  const style = "body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; padding: 40px; max-width: 800px; margin: 0 auto; line-height: 1.6; color: #333; background: #fafafa; } .card { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); } h1 { color: #2c3e50; border-bottom: 2px solid #eee; padding-bottom: 15px; } h2 { margin-top: 30px; color: #34495e; font-size: 1.2em; } a { color: #3498db; text-decoration: none; } ul { opacity: 0.8; } .footer { margin-top: 50px; text-align: center; font-size: 12px; color: #999; }";
  if (type === "home") {
    title = "Fantasy Cricket API - Skill Platform";
    content = `
            <div class="card">
                <h1>Fantasy Cricket Services</h1>
                <p>Welcome to the secure backend services for Axevora Labs' Skill-Based Cricket Strategy Platform.</p>
                <p><strong>Status:</strong> Systems Operational \xF0\u0178\u0178\xA2</p>
                <p>This platform offers analytics, team management, and strategy simulation tools for cricket enthusiasts. All transactions are for digital services and skill-based contests.</p>
                <p>Managed by <a href="https://axevoralabs.com">Axevora Labs</a>.</p>
            </div>
        `;
  } else if (type === "terms") {
    title = "Terms of Service";
    content = `
            <div class="card">
                <h1>Terms of Service</h1>
                <p><strong>1. Introduction:</strong> These terms govern your use of our Skill-Based Fantasy Sports Platform. By accessing our services, you confirm you are 18+ years of age.</p>
                <p><strong>2. Game of Skill:</strong> Our contests are strictly "Games of Skill" as recognized by the Supreme Court of India. Success depends on knowledge, training, attention, and experience of the player.</p>
                <p><strong>3. Use of Services:</strong> Users pay platform fees to participate in organized skill contests. We strictly prohibit any form of gambling, betting, or wagering.</p>
                <p><strong>4. Restricted States:</strong> Users from Assam, Odisha, Telangana, Nagaland, Sikkim, and Andhra Pradesh are restricted from paid contests.</p>
                <p>For full legal terms, visit: <a href="https://axevoralabs.com/terms">Main Terms Policy</a></p>
            </div>
        `;
  } else if (type === "refund") {
    title = "Refund & Cancellation Policy";
    content = `
            <div class="card">
                <h1>Refund & Cancellation Policy</h1>
                <h2>Cancellation</h2>
                <p>Users may withdraw from a contest anytime before the match deadline. The participation amount will be instantly credited back to the user's unutilized wallet balance.</p>
                <h2>Refunds</h2>
                <p><strong>Failed Transactions:</strong> If amount is deducted but not credited, it will be automatically refunded within 5-7 business days.</p>
                <p><strong>Contest Cancellation:</strong> If a real-world match is abandoned, all contest participation fees are refunded 100% to the user's wallet.</p>
                <p><strong>Finality:</strong> Once a contest is Live, participation is final and non-refundable as the service is considered consumed.</p>
            </div>
        `;
  } else if (type === "privacy") {
    title = "Privacy Policy";
    content = `
            <div class="card">
                <h1>Privacy Policy</h1>
                <p>We respect your privacy. We collect minimal data (Email, Mobile) essential for account security and service delivery.</p>
                <p><strong>Data Usage:</strong> Your data is used strictly for authentication and transaction processing. We do not sell data to third parties.</p>
                <p><strong>Secure Payments:</strong> All financial transactions are processed via regulating PCI-DSS compliant gateways.</p>
            </div>
        `;
  } else if (type === "contact") {
    title = "Contact Us";
    content = `
            <div class="card">
                <h1>Contact Us</h1>
                <p>For support regarding payments, account, or contests, reach out to us:</p>
                <ul>
                    <li><strong>Email:</strong> support@axevoralabs.com</li>
                    <li><strong>Operating Hours:</strong> Mon-Fri, 10 AM - 6 PM IST</li>
                </ul>
                <p><strong>Registered Address:</strong><br>Axevora Labs,<br>India.</p>
            </div>
        `;
  }
  const html = `
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <meta name="robots" content="noindex, nofollow">
            <title>${title}</title>
            <style>${style}</style>
        </head>
        <body>
            ${content}
            <div class="footer">
                &copy; ${(/* @__PURE__ */ new Date()).getFullYear()} Axevora Labs. All Rights Reserved.<br>
                <small>Indian Fantasy Sports Association Compliant</small>
            </div>
        </body>
        </html>
    `;
  return new Response(html, {
    headers: { "Content-Type": "text/html" }
  });
}
__name(handleStaticPage, "handleStaticPage");
async function handleUserSync(request, env) {
  try {
    const { userId, email, displayName } = await request.json();
    if (!userId) {
      return jsonResponse({ success: false, error: "userId required" }, 400);
    }
    const existing = await env.DB.prepare("SELECT id FROM users WHERE id = ?").bind(userId).first();
    if (existing) {
      return jsonResponse({ success: true, message: "User already exists", alreadyExists: true });
    }
    await env.DB.prepare(`
            INSERT INTO users (id, email, display_name, deposit_credits, winning_credits, joined_at, last_active)
            VALUES (?, ?, ?, 0, 0, ?, ?)
        `).bind(userId, email || "", displayName || "User", Date.now(), Date.now()).run();
    return jsonResponse({ success: true, message: "User created successfully", userId });
  } catch (e) {
    console.error("User Sync Error:", e);
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleUserSync, "handleUserSync");
async function handleSaveTeam(request, env) {
  try {
    const body = await request.json();
    const { id, userId, matchId, teamName, players, captainId, viceCaptainId } = body;
    const payloadPlayers = Array.isArray(players) ? players : [];
    if (!userId || !matchId || !players) {
      return jsonResponse({ success: false, error: "Missing required fields" }, 400);
    }
    const finalId = id && id.toString().trim().length > 0 ? id.toString().trim() : `team_${Date.now()}_${userId}`;
    console.log(`[TEAM_SAVE_REQ] teamId=${finalId}, matchId=${matchId}, playersCountFromPayload=${payloadPlayers.length}`);
    console.log(`\u{1F4BE} Saving Team. ID: ${finalId}, Name: ${teamName}`);
    const result = await env.DB.prepare(`
            INSERT INTO teams (id, user_id, match_id, team_name, players_json, captain_id, vice_captain_id, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                team_name = excluded.team_name,
                players_json = excluded.players_json,
                captain_id = excluded.captain_id,
                vice_captain_id = excluded.vice_captain_id
        `).bind(
      finalId,
      userId,
      matchId,
      teamName || "My Team",
      JSON.stringify(players),
      captainId,
      viceCaptainId,
      Date.now()
    ).run();
    console.log(`[TEAM_ROW_INSERTED] teamId=${finalId}`);
    console.log(`[TEAM_PLAYERS_INSERT_START] count=${payloadPlayers.length}`);
    let insertedRows = 0;
    for (const player of payloadPlayers) {
      const playerId = String(player?.player_id ?? player?.playerId ?? player?.id ?? "").trim();
      console.log(`[TEAM_PLAYER_INSERT] teamId=${finalId}, playerId=${playerId || "UNKNOWN"}`);
      insertedRows++;
    }
    console.log(`[TEAM_PLAYERS_INSERT_DONE] insertedRows=${insertedRows}`);
    try {
      const verifyRow = await env.DB.prepare(
        "SELECT COUNT(*) AS count FROM team_players WHERE team_id = ?"
      ).bind(finalId).first();
      const dbPlayers = Number(verifyRow?.count || 0);
      console.log(`[TEAM_DB_VERIFY] teamId=${finalId}, dbPlayers=${dbPlayers}`);
    } catch (verifyError) {
      console.log(`[TEAM_DB_VERIFY] teamId=${finalId}, dbPlayers=QUERY_ERROR, error=${verifyError.message}`);
    }
    console.log("\u2705 D1 Save Result:", JSON.stringify(result));
    return jsonResponse({ success: true, message: "Team processed", id: finalId, d1: result });
  } catch (e) {
    console.error("\u274C D1 Save Error:", e.message);
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleSaveTeam, "handleSaveTeam");
async function handleGetTeams(queryParams, env) {
  try {
    const userId = queryParams.get("userId");
    const matchId = queryParams.get("matchId");
    console.log(`\u{1F50D} Fetching Teams for User: ${userId}, Match: ${matchId}`);
    let query = "SELECT * FROM teams WHERE user_id = ?";
    let params = [userId];
    if (matchId) {
      query += " AND match_id = ?";
      params.push(matchId);
    }
    const { results } = await env.DB.prepare(query).bind(...params).all();
    const formatted = results.map((t) => ({
      id: t.id,
      userId: t.user_id,
      matchId: t.match_id.toString(),
      teamName: t.team_name,
      players: JSON.parse(t.players_json || "[]"),
      captainId: t.captain_id,
      viceCaptainId: t.vice_captain_id,
      totalPoints: t.total_points || 0
    }));
    return jsonResponse({ success: true, teams: formatted });
  } catch (e) {
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleGetTeams, "handleGetTeams");
async function handleGetRoomLeaderboard(queryParams, env) {
  const matchId = queryParams.get("matchId");
  if (!matchId) return jsonResponse({ success: false, error: "matchId required" }, 400);
  try {
    const { results: pointRows } = await env.DB.prepare(
      "SELECT player_id, points FROM fantasy_points WHERE match_id = ?"
    ).bind(matchId).all();
    const pointsMap = {};
    pointRows.forEach((r) => pointsMap[r.player_id] = r.points || 0);
    const { results: teams } = await env.DB.prepare(
      "SELECT id, user_id, team_name, players_json FROM teams WHERE match_id = ?"
    ).bind(matchId).all();
    const leaderboard = teams.map((t) => {
      let total = 0;
      let pIds = [];
      try {
        const parsed = JSON.parse(t.players_json || "[]");
        pIds = Array.isArray(parsed) ? parsed : [];
      } catch (e) {
        pIds = [];
      }
      pIds.forEach((p) => {
        const pid = p.player_id || p.playerId || p.id;
        if (pid) {
          total += pointsMap[pid] || 0;
        }
      });
      return {
        teamId: t.id,
        userId: t.user_id,
        teamName: t.team_name,
        points: total
      };
    });
    leaderboard.sort((a, b) => b.points - a.points);
    return jsonResponse({ success: true, leaderboard });
  } catch (e) {
    console.error("Room Leaderboard Error:", e);
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleGetRoomLeaderboard, "handleGetRoomLeaderboard");
async function handleSocialPreview(matchId, env) {
  try {
    const match = await env.DB.prepare("SELECT * FROM matches WHERE id = ?").bind(matchId).first();
    if (!match) {
      return new Response("Match not found", { status: 404 });
    }
    const title = match.title || `${match.team_a} vs ${match.team_b} - AxevoraLabs`;
    const description = `Live Match Room: Join the conversation now on AxevoraLabs!`;
    const imageUrl = match.team_a_img ? match.team_a_img : "https://axevoralabs.com/icons/Icon-192.png";
    const html = `<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>${title}</title>
    <meta property="og:title" content="${title}">
    <meta property="og:description" content="${description}">
    <meta property="og:image" content="${imageUrl}">
    <meta property="og:type" content="website">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="${title}">
    <meta name="twitter:description" content="${description}">
    <meta name="twitter:image" content="${imageUrl}">
    <meta http-equiv="refresh" content="0; url=https://axevoralabs.com/room/${matchId}">
</head>
<body>
    <p>Redirecting to AxevoraLabs Room...</p>
</body>
</html>`;
    return new Response(html, { headers: { "Content-Type": "text/html" } });
  } catch (e) {
    return new Response("Error: " + e.message, { status: 500 });
  }
}
__name(handleSocialPreview, "handleSocialPreview");
async function handleGetRoomRanking(queryParams, env) {
  const matchId = queryParams.get("matchId");
  const roomId = queryParams.get("roomId");
  if (!matchId) return jsonResponse({ success: false, error: "matchId required" }, 400);
  if (!roomId) return jsonResponse({ success: false, error: "roomId required \u2014 Rankings are only inside Private Rooms." }, 400);
  try {
    const room = await env.DB.prepare(
      "SELECT id, room_type, is_private FROM rooms WHERE id = ?"
    ).bind(roomId).first();
    if (!room) {
      return jsonResponse({ success: false, error: "ROOM_NOT_FOUND", message: "Room not found." }, 404);
    }
    const isPrivate = room.is_private === 1 || room.room_type === "private";
    if (!isPrivate) {
      return jsonResponse({
        success: false,
        error: "RANKING_RESTRICTED",
        message: "Rankings are not available for Global Rooms. Rankings are only for Private Rooms and are for informational/discussion purposes only. No rewards are associated."
      }, 403);
    }
    const leaderboardResponse = await handleGetRoomLeaderboard(queryParams, env);
    const leaderboardData = await leaderboardResponse.json();
    return jsonResponse({
      ...leaderboardData,
      disclaimer: "\u26A0\uFE0F Rankings are for informational/discussion purposes only. No rewards are associated.",
      roomId
    });
  } catch (e) {
    console.error("handleGetRoomRanking Error:", e);
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleGetRoomRanking, "handleGetRoomRanking");
async function handleCreateRoom(request, env) {
  if (request.method !== "POST") return jsonResponse({ error: "Method Not Allowed" }, 405);
  try {
    const body = await request.json();
    const { matchId, creatorId, roomName, roomType, inviteCode, maxMembers } = body;
    if (!matchId || !creatorId || !roomName) {
      return jsonResponse({ success: false, error: "matchId, creatorId, and roomName are required" }, 400);
    }
    const isPrivate = roomType === "private" ? 1 : 0;
    const finalInviteCode = inviteCode || Math.random().toString(36).substring(2, 8).toUpperCase();
    const roomId = `room_${Date.now()}_${creatorId}`;
    await env.DB.prepare(`
            INSERT INTO rooms (id, match_id, creator_id, room_name, room_type, is_private, invite_code, max_members, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
      roomId,
      matchId.toString(),
      creatorId,
      roomName,
      roomType || "private",
      isPrivate,
      finalInviteCode,
      maxMembers || 10,
      Date.now()
    ).run();
    await env.DB.prepare(`
            INSERT OR IGNORE INTO room_members (room_id, user_id, joined_at) VALUES (?, ?, ?)
        `).bind(roomId, creatorId, Date.now()).run();
    console.log(`\u2705 Room Created: ${roomId} (${roomType}) for Match ${matchId}`);
    return jsonResponse({ success: true, roomId, inviteCode: finalInviteCode, message: "Room created successfully" });
  } catch (e) {
    console.error("handleCreateRoom Error:", e);
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleCreateRoom, "handleCreateRoom");
async function handleGetRooms(matchId, env) {
  try {
    const { results } = await env.DB.prepare(`
            SELECT r.*, (SELECT COUNT(*) FROM room_members rm WHERE rm.room_id = r.id) as member_count
            FROM rooms r WHERE r.match_id = ? AND r.is_private = 0
            ORDER BY r.created_at DESC LIMIT 50
        `).bind(matchId.toString()).all();
    return jsonResponse({ success: true, rooms: results || [] });
  } catch (e) {
    console.error("handleGetRooms Error:", e);
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleGetRooms, "handleGetRooms");
async function handleJoinRoom(request, env) {
  if (request.method !== "POST") return jsonResponse({ error: "Method Not Allowed" }, 405);
  try {
    const body = await request.json();
    const { roomId, userId, inviteCode } = body;
    if (!roomId || !userId) return jsonResponse({ success: false, error: "roomId and userId are required" }, 400);
    const room = await env.DB.prepare("SELECT * FROM rooms WHERE id = ?").bind(roomId).first();
    if (!room) return jsonResponse({ success: false, error: "ROOM_NOT_FOUND" }, 404);
    if (room.is_private === 1 && room.invite_code && room.invite_code !== inviteCode) {
      return jsonResponse({ success: false, error: "INVALID_INVITE_CODE" }, 403);
    }
    const memberCount = await env.DB.prepare("SELECT COUNT(*) as c FROM room_members WHERE room_id = ?").bind(roomId).first();
    if (memberCount && memberCount.c >= (room.max_members || 10)) {
      return jsonResponse({ success: false, error: "ROOM_FULL" }, 400);
    }
    await env.DB.prepare(`
            INSERT OR IGNORE INTO room_members (room_id, user_id, joined_at) VALUES (?, ?, ?)
        `).bind(roomId, userId, Date.now()).run();
    return jsonResponse({ success: true, message: "Joined room successfully", roomId });
  } catch (e) {
    console.error("handleJoinRoom Error:", e);
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleJoinRoom, "handleJoinRoom");
async function handleGetRoomById(roomId, env) {
  try {
    if (!roomId) return jsonResponse({ success: false, error: "roomId required" }, 400);
    const room = await env.DB.prepare(`
            SELECT r.*, (SELECT COUNT(*) FROM room_members rm WHERE rm.room_id = r.id) as member_count
            FROM rooms r WHERE r.id = ?
        `).bind(roomId).first();
    if (!room) return jsonResponse({ success: false, error: "ROOM_NOT_FOUND" }, 404);
    return jsonResponse({ success: true, room });
  } catch (e) {
    console.error("handleGetRoomById Error:", e);
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleGetRoomById, "handleGetRoomById");
async function handleGetUserRooms(userId, env) {
  try {
    if (!userId) return jsonResponse({ success: false, error: "userId required" }, 400);
    const { results } = await env.DB.prepare(`
            SELECT r.*, rm.joined_at as member_since,
                   (SELECT COUNT(*) FROM room_members rm2 WHERE rm2.room_id = r.id) as member_count
            FROM rooms r
            JOIN room_members rm ON r.id = rm.room_id
            WHERE rm.user_id = ?
            ORDER BY rm.joined_at DESC
        `).bind(userId).all();
    return jsonResponse({ success: true, rooms: results || [] });
  } catch (e) {
    console.error("handleGetUserRooms Error:", e);
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleGetUserRooms, "handleGetUserRooms");
async function handleSendChatMessage(request, env) {
  if (request.method !== "POST") return jsonResponse({ error: "Method Not Allowed" }, 405);
  try {
    const body = await request.json();
    const { roomId, userId, content, messageType } = body;
    if (!roomId || !userId || !content) {
      return jsonResponse({ success: false, error: "roomId, userId, and content required" }, 400);
    }
    const msgId = `msg_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`;
    const now = Date.now();
    await env.DB.prepare(`
            INSERT INTO chat_messages (id, room_id, user_id, message_type, content, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
        `).bind(msgId, roomId, userId, messageType || "text", content, now).run();
    return jsonResponse({ success: true, messageId: msgId, timestamp: now });
  } catch (e) {
    console.error("handleSendChatMessage Error:", e);
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleSendChatMessage, "handleSendChatMessage");
async function handleSyncChatMessages(roomId, lastUpdated, env) {
  try {
    const afterMs = parseInt(lastUpdated) || 0;
    const { results } = await env.DB.prepare(`
            SELECT c.*, u.name as user_name, u.photo_url as user_photo
            FROM chat_messages c
            LEFT JOIN users u ON c.user_id = u.id
            WHERE c.room_id = ? AND c.created_at > ?
            ORDER BY c.created_at ASC
            LIMIT 100
        `).bind(roomId, afterMs).all();
    return jsonResponse({ success: true, messages: results || [] });
  } catch (e) {
    console.error("handleSyncChatMessages Error:", e);
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleSyncChatMessages, "handleSyncChatMessages");
async function handleGetStatsMetrics(matchId, env) {
  if (!matchId) return jsonResponse({ success: false, error: "match_id required" }, 400);
  try {
    const { results } = await env.DB.prepare(
      "SELECT * FROM stats_metrics WHERE match_id = ?"
    ).bind(matchId).all();
    return jsonResponse({ success: true, metrics: results });
  } catch (e) {
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleGetStatsMetrics, "handleGetStatsMetrics");

// C:/Users/tittoo/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/wrangler/templates/middleware/middleware-ensure-req-body-drained.ts
init_checked_fetch();
init_modules_watch_stub();
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
init_checked_fetch();
init_modules_watch_stub();
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

// .wrangler/tmp/bundle-TcfayS/middleware-insertion-facade.js
var __INTERNAL_WRANGLER_MIDDLEWARE__ = [
  middleware_ensure_req_body_drained_default,
  middleware_miniflare3_json_error_default
];
var middleware_insertion_facade_default = workers_default;

// C:/Users/tittoo/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/wrangler/templates/middleware/common.ts
init_checked_fetch();
init_modules_watch_stub();
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

// .wrangler/tmp/bundle-TcfayS/middleware-loader.entry.ts
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
  middleware_loader_entry_default as default,
  jsonResponse
};
//# sourceMappingURL=index.js.map
