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
var STALE_LIVE_RECONCILE_ENABLED = true;
var UPCOMING_EMPTY_CHECK_KEY = "upcoming_empty_checked_at";
var UPCOMING_EMPTY_CHECK_COOLDOWN_MS = 6 * 60 * 60 * 1e3;
var PREDICTIVE_CHECK_COOLDOWN_MS = 5 * 60 * 1e3;
var LIVE_SNAPSHOT_HASH_KEY = "live_snapshot_hash";
var LIVE_SNAPSHOT_SKIP_WINDOW_MS = 60 * 60 * 1e3;
var UPCOMING_SNAPSHOT_HASH_KEY = "upcoming_snapshot_hash";
var UPCOMING_SNAPSHOT_SKIP_WINDOW_MS = 4 * 60 * 60 * 1e3;
var MATCH_STATE_CLASS_PREFIX = "match_state_class:";
var TERMINAL_COMPLETED_TOKENS = ["won", "beat", "defeated", "result", "match over", "innings win"];
var TERMINAL_ABANDONED_TOKENS = ["abandoned", "no result", "cancelled", "match abandoned"];
var NON_TERMINAL_STATE_TOKENS = ["rain", "delay", "delayed", "wet outfield", "inspection", "toss delayed", "start delayed", "bad light", "interruption"];
async function processCricketData(env) {
  console.log("\u{1F3CF} Cricket Engine Shuru (Predictive Guarded Verification Mode)...");
  await verifySchema(env);
  if (API_LOCK_ACTIVE) {
    console.log("[API_LOCK_ACTIVE] Sab external API calls band hain. Sirf DB se data return ho raha hai.");
    return await getMatchesFromDB(env);
  }
  const apiKey = env.RAPID_API_KEY;
  const apiHost = "cricbuzz-cricket.p.rapidapi.com";
  try {
    const matches = await fetchMatchesWithPredictiveGuard(apiKey, apiHost, env);
    if (matches && matches.length > 0) {
      console.log(`\u{1F4E1} API se ${matches.length} matches mila`);
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
  const apiKey = env.RAPID_API_KEY;
  const apiHost = "cricbuzz-cricket.p.rapidapi.com";
  if (!apiKey) {
    console.log("[UPCOMING_SEED_SKIP] RAPID_API_KEY missing.");
    return;
  }
  const incomingMatches = await fetchEndpoint("/matches/v1/upcoming", apiKey, apiHost);
  if (!Array.isArray(incomingMatches) || incomingMatches.length === 0) {
    await writeSysConfigTimestamp(env, UPCOMING_EMPTY_CHECK_KEY, nowMs);
    const emptyHash = buildUpcomingSnapshotHash([]);
    const stableUntil = upcomingSnapshotState?.hash === emptyHash ? nowMs + UPCOMING_SNAPSHOT_SKIP_WINDOW_MS : 0;
    await writeSysConfigValue(env, UPCOMING_SNAPSHOT_HASH_KEY, JSON.stringify({
      hash: emptyHash,
      stableUntil
    }));
    console.log("[UPCOMING_SEED_NO_DATA] /upcoming returned no matches.");
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
async function updateDBTimestamp(env, key) {
  const now = Date.now().toString();
  await env.DB.prepare("INSERT OR REPLACE INTO sys_config (key, value, updated_at) VALUES (?, ?, ?)").bind(key, now, Date.now()).run();
}
__name(updateDBTimestamp, "updateDBTimestamp");
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
function buildLiveSnapshotHash(matches) {
  const rows = (Array.isArray(matches) ? matches : []).map((m) => {
    const matchId = String(m?.id ?? "").trim();
    const status = String(m?.status ?? "").trim();
    const lastUpdated = normalizeSnapshotInt(m?.lastUpdated ?? m?.last_updated);
    return `${matchId} | ${status} | ${lastUpdated}`;
  }).filter(Boolean).sort();
  return stableHash2(rows.join("||"));
}
__name(buildLiveSnapshotHash, "buildLiveSnapshotHash");
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
async function readMatchStateClass(env, matchId) {
  const key = buildMatchStateClassKey(matchId);
  const row = await env.DB.prepare("SELECT value FROM sys_config WHERE key = ?").bind(key).first();
  return String(row?.value || "").trim();
}
__name(readMatchStateClass, "readMatchStateClass");
async function writeMatchStateClass(env, matchId, stateClass) {
  const key = buildMatchStateClassKey(matchId);
  await env.DB.prepare(
    "INSERT OR REPLACE INTO sys_config (key, value, updated_at) VALUES (?, ?, ?)"
  ).bind(key, String(stateClass || ""), Date.now()).run();
}
__name(writeMatchStateClass, "writeMatchStateClass");
function normalizeStateText(value) {
  return String(value || "").trim().toLowerCase();
}
__name(normalizeStateText, "normalizeStateText");
function hasAnyToken(text, tokens) {
  return tokens.some((token) => text.includes(token));
}
__name(hasAnyToken, "hasAnyToken");
function classifyMatchStateClass(stateText, statusText) {
  const haystack = `${normalizeStateText(stateText)} ${normalizeStateText(statusText)}`.trim();
  if (!haystack) return "UNKNOWN";
  if (hasAnyToken(haystack, TERMINAL_ABANDONED_TOKENS)) return "TERMINAL_ABANDONED";
  if (hasAnyToken(haystack, TERMINAL_COMPLETED_TOKENS)) return "TERMINAL_COMPLETED";
  if (hasAnyToken(haystack, NON_TERMINAL_STATE_TOKENS)) return "NON_TERMINAL";
  return "UNKNOWN";
}
__name(classifyMatchStateClass, "classifyMatchStateClass");
function deriveNonTerminalStatus(startTimeMs, nowMs) {
  return startTimeMs > nowMs ? "Upcoming" : "Live";
}
__name(deriveNonTerminalStatus, "deriveNonTerminalStatus");
async function persistLiveStateClasses(env, liveApiMatches) {
  if (!Array.isArray(liveApiMatches) || liveApiMatches.length === 0) return;
  const writes = [];
  for (const match of liveApiMatches) {
    const matchId = String(match?.id || "").trim();
    const stateClass = String(match?.stateClass || "").trim();
    if (!matchId || !stateClass) continue;
    writes.push(writeMatchStateClass(env, matchId, stateClass));
  }
  if (writes.length > 0) {
    await Promise.all(writes);
  }
}
__name(persistLiveStateClasses, "persistLiveStateClasses");
async function restoreTerminalStatusesFromNonTerminalApi(env, liveApiMatches, nowMs) {
  if (!Array.isArray(liveApiMatches) || liveApiMatches.length === 0) return;
  for (const match of liveApiMatches) {
    const matchId = String(match?.id || "").trim();
    if (!matchId) continue;
    if (String(match?.stateClass || "") !== "NON_TERMINAL") continue;
    const restoredStatus = deriveNonTerminalStatus(normalizeSnapshotInt(match?.startTime), nowMs);
    await env.DB.prepare(`
            UPDATE matches
            SET status = ?, last_updated = ?
        WHERE id = ?
            AND status IN('Completed', 'Finished', 'Abandoned')
        `).bind(restoredStatus, nowMs, matchId).run();
  }
}
__name(restoreTerminalStatusesFromNonTerminalApi, "restoreTerminalStatusesFromNonTerminalApi");
function buildPredictiveCheckedKey(matchId) {
  return `predictive_checked: ${String(matchId)}`;
}
__name(buildPredictiveCheckedKey, "buildPredictiveCheckedKey");
function normalizeSnapshotValue(value) {
  if (value === null || value === void 0) return "";
  return String(value);
}
__name(normalizeSnapshotValue, "normalizeSnapshotValue");
function isPredictiveStateUnchanged(dbMatch, apiMatch) {
  if (!dbMatch) return false;
  if (!apiMatch) {
    return String(dbMatch.status || "") === "Upcoming";
  }
  const dbStatus = normalizeSnapshotValue(dbMatch.status);
  const apiStatus = normalizeSnapshotValue(apiMatch.status);
  if (dbStatus !== apiStatus) return false;
  const dbScore = normalizeSnapshotValue(dbMatch.last_score);
  const apiScore = normalizeSnapshotValue(apiMatch.lastScore);
  const dbWickets = Number(dbMatch.last_wickets || 0);
  const apiWickets = Number(apiMatch.lastWickets || 0);
  const dbOver = normalizeSnapshotValue(dbMatch.last_over);
  const apiOver = normalizeSnapshotValue(apiMatch.lastOver);
  const dbInnings = Number(dbMatch.last_innings || 0);
  const apiInnings = Number(apiMatch.lastInnings || 0);
  return dbScore === apiScore && dbWickets === apiWickets && dbOver === apiOver && dbInnings === apiInnings;
}
__name(isPredictiveStateUnchanged, "isPredictiveStateUnchanged");
function buildStaleLiveKey(matchId) {
  return `stale_live: ${String(matchId)}`;
}
__name(buildStaleLiveKey, "buildStaleLiveKey");
async function clearStaleLiveTracker(env, key) {
  await env.DB.prepare("DELETE FROM sys_config WHERE key = ?").bind(key).run();
}
__name(clearStaleLiveTracker, "clearStaleLiveTracker");
async function selfHealStaleUpcomingMatches(env, nowMs) {
  const SIX_HOURS = 6 * 60 * 60 * 1e3;
  await env.DB.prepare(`
        UPDATE matches
        SET status = 'In Progress', last_updated = ?
        WHERE status = 'Upcoming'
        AND start_time IS NOT NULL
        AND CAST(start_time AS INTEGER) > 0
        AND CAST(start_time AS INTEGER) < ?
        AND CAST(start_time AS INTEGER) >= ?
        `).bind(nowMs, nowMs, nowMs - SIX_HOURS).run();
  await env.DB.prepare(`
        UPDATE matches
        SET status = 'Completed', last_updated = ?
        WHERE status = 'Upcoming'
        AND start_time IS NOT NULL
        AND CAST(start_time AS INTEGER) > 0
        AND CAST(start_time AS INTEGER) < ?
        `).bind(nowMs, nowMs - SIX_HOURS).run();
}
__name(selfHealStaleUpcomingMatches, "selfHealStaleUpcomingMatches");
async function reconcileStaleLiveMatches(env, liveApiMatches, nowMs) {
  if (STALE_LIVE_RECONCILE_ENABLED !== true) return;
  if (!Array.isArray(liveApiMatches)) return;
  const dbLive = await env.DB.prepare(`
        SELECT id, status, start_time, last_updated
        FROM matches
        WHERE status IN('Live', 'In Progress', 'Innings Break')
        `).all();
  const dbLiveMatches = dbLive.results || [];
  if (dbLiveMatches.length === 0) return;
  for (const match of dbLiveMatches) {
    const matchId = String(match.id ?? "").trim();
    if (!matchId) continue;
    const trackerKey = buildStaleLiveKey(matchId);
    const stateClass = await readMatchStateClass(env, matchId);
    if (stateClass === "NON_TERMINAL") {
      console.log(`[RECONCILE_BLOCKED_NON_TERMINAL] matchId = ${matchId}`);
      await clearStaleLiveTracker(env, trackerKey);
      continue;
    }
    const closeAllowedByStateAuthority = stateClass === "TERMINAL_COMPLETED" || stateClass === "TERMINAL_ABANDONED";
    if (!closeAllowedByStateAuthority) {
      await clearStaleLiveTracker(env, trackerKey);
      continue;
    }
    const terminalStatus = stateClass === "TERMINAL_ABANDONED" ? "Abandoned" : "Completed";
    await env.DB.prepare(`
            UPDATE matches
            SET status = ?, last_updated = ?
        WHERE id = ?
            AND status IN('Live', 'In Progress', 'Innings Break')
        `).bind(terminalStatus, nowMs, match.id).run();
    await clearStaleLiveTracker(env, trackerKey);
  }
}
__name(reconcileStaleLiveMatches, "reconcileStaleLiveMatches");
async function fetchEndpoint(path, key, host) {
  try {
    const url = `https://${host}${path}`;
    const resp = await fetch(url, {
      headers: {
        "x-rapidapi-key": key,
        "x-rapidapi-host": host,
        "User-Agent": "Mozilla/5.0"
      }
    });
    if (resp.ok) {
      const data = await resp.json();
      const matches = parseCricbuzzMatches(data);
      console.log(`\u2705 ${path}: Found ${matches.length} matches`);
      return matches;
    } else {
      console.error(`\u26A0\uFE0F API Error ${path}: ${resp.status}`);
      return null;
    }
  } catch (e) {
    console.error(`Fetch Failed ${path}:`, e);
    return null;
  }
}
__name(fetchEndpoint, "fetchEndpoint");
async function fetchMatchesWithPredictiveGuard(key, host, env) {
  let parsed = [];
  const now = Date.now();
  const FIVE_MINUTES = 5 * 60 * 1e3;
  try {
    await selfHealStaleUpcomingMatches(env, now);
  } catch (_) {
  }
  const activeMatches = await env.DB.prepare(`
        SELECT id, status, start_time, last_updated, last_score, last_wickets, last_over, last_innings
        FROM matches
        WHERE status IN ('Live', 'In Progress', 'Innings Break', 'Upcoming')
    `).all();
  const liveMatches = activeMatches.results.filter(
    (m) => ["Live", "In Progress", "Innings Break"].includes(m.status)
  );
  const upcomingMatches = activeMatches.results.filter((m) => m.status === "Upcoming");
  const liveSnapshotState = parseSnapshotState(
    await readSysConfigValue(env, LIVE_SNAPSHOT_HASH_KEY)
  );
  if (liveMatches.length === 0) {
    const startingMatch2 = upcomingMatches.find((m) => now >= m.start_time);
    if (!startingMatch2) {
      console.log("[CONTROL_UNLOCK_SKIP] DB mein koi live match nahi. 0 API calls.");
      return [];
    }
  }
  if (liveSnapshotState && liveSnapshotState.stableUntil > now && liveSnapshotState.hash) {
    return [];
  }
  await env.DB.prepare(
    "INSERT OR IGNORE INTO sys_config (key, value, updated_at) VALUES ('last_live_api_call', '0', 0)"
  ).run();
  const lockResult = await env.DB.prepare(
    `UPDATE sys_config
         SET value = ?, updated_at = ?
         WHERE key = 'last_live_api_call'
         AND (value IS NULL OR CAST(value AS INTEGER) < ?)`
  ).bind(now.toString(), now, now - FIVE_MINUTES).run();
  if (!lockResult.meta || lockResult.meta.changes !== 1) {
    const lockRow = await env.DB.prepare(
      "SELECT value FROM sys_config WHERE key = 'last_live_api_call'"
    ).first();
    const remainSec = lockRow ? Math.ceil((FIVE_MINUTES - (now - parseInt(lockRow.value || "0"))) / 1e3) : 0;
    console.log(`[CONTROL_UNLOCK_AUTORELOCK] D1 lock active. ~${remainSec}s remaining. 0 API calls.`);
    return [];
  }
  const dueMatches = liveMatches.filter((m) => {
    const lastFetch = m.last_updated || 0;
    return now >= lastFetch + 12 * 60 * 1e3;
  });
  const predictiveCandidates = [];
  for (const match of dueMatches) {
    const checkedAt = await readSysConfigTimestamp(env, buildPredictiveCheckedKey(match.id));
    if (checkedAt > 0 && now - checkedAt < PREDICTIVE_CHECK_COOLDOWN_MS) {
      continue;
    }
    predictiveCandidates.push(match);
  }
  let startingMatch = upcomingMatches.find((m) => now >= m.start_time) || null;
  if (startingMatch) {
    const checkedAt = await readSysConfigTimestamp(env, buildPredictiveCheckedKey(startingMatch.id));
    if (checkedAt > 0 && now - checkedAt < PREDICTIVE_CHECK_COOLDOWN_MS) {
      startingMatch = null;
    }
  }
  const shouldFetchLive = (predictiveCandidates.length > 0 || !!startingMatch) === true;
  if (shouldFetchLive !== true) {
    console.log("[CONTROL_UNLOCK_SKIP] Predictive window closed. 0 API calls.");
    return [];
  }
  console.log("[CONTROL_UNLOCK_STARTED] Lock acquired. 1 API call allow: /live");
  const data = await fetchEndpoint("/matches/v1/live", key, host);
  if (data) {
    await persistLiveStateClasses(env, data);
    await restoreTerminalStatusesFromNonTerminalApi(env, data, now);
    const liveSnapshotHash = buildLiveSnapshotHash(data);
    const previousLiveHash = liveSnapshotState?.hash || "";
    const sameLiveSnapshot = !!liveSnapshotHash && previousLiveHash === liveSnapshotHash;
    await writeSysConfigValue(env, LIVE_SNAPSHOT_HASH_KEY, JSON.stringify({
      hash: liveSnapshotHash,
      stableUntil: sameLiveSnapshot ? now + LIVE_SNAPSHOT_SKIP_WINDOW_MS : 0
    }));
    if (sameLiveSnapshot) {
      return [];
    }
    parsed.push(...data);
    await updateDBTimestamp(env, "last_fetch_live");
    const attempted = [...predictiveCandidates];
    if (startingMatch && !attempted.some((m) => String(m.id) === String(startingMatch.id))) {
      attempted.push(startingMatch);
    }
    const liveApiById = new Map((data || []).map((m) => [String(m?.id || ""), m]));
    for (const candidate of attempted) {
      const candidateId = String(candidate?.id || "").trim();
      if (!candidateId) continue;
      const apiMatch = liveApiById.get(candidateId);
      const unchanged = isPredictiveStateUnchanged(candidate, apiMatch);
      const keyName = buildPredictiveCheckedKey(candidateId);
      if (unchanged) {
        await writeSysConfigTimestamp(env, keyName, now);
      } else {
        await clearSysConfigTimestamp(env, keyName);
      }
    }
    try {
      await reconcileStaleLiveMatches(env, data, now);
    } catch (_) {
    }
  }
  console.log("[CONTROL_UNLOCK_DISABLED] /upcoming endpoint disabled.");
  console.log("[CONTROL_UNLOCK_DISABLED] /recent endpoint disabled.");
  if (parsed.length === 0) return [];
  const unique = /* @__PURE__ */ new Map();
  parsed.forEach((m) => {
    if (m.id) unique.set(m.id, m);
  });
  return Array.from(unique.values());
}
__name(fetchMatchesWithPredictiveGuard, "fetchMatchesWithPredictiveGuard");
function parseCricbuzzMatches(data) {
  let matches = [];
  if (data.typeMatches && Array.isArray(data.typeMatches)) {
    data.typeMatches.forEach((tm) => {
      if (tm.seriesMatches) {
        tm.seriesMatches.forEach((sm) => {
          const wrapper = sm.seriesAdWrapper || {};
          if (wrapper.matches) {
            wrapper.matches.forEach((m) => {
              const parsed = formatCricbuzzMatch(m.matchInfo);
              if (parsed) matches.push(parsed);
            });
          }
        });
      }
    });
  }
  return matches;
}
__name(parseCricbuzzMatches, "parseCricbuzzMatches");
function formatCricbuzzMatch(info) {
  if (!info || !info.matchId) return null;
  let status = "Upcoming";
  const state = String(info.state || "").trim();
  const stateUpper = state.toUpperCase();
  const rawStatusText = String(info.status || "").trim();
  const startTimeMs = parseInt(info.startDate) || Date.now();
  const nowMs = Date.now();
  const stateClass = classifyMatchStateClass(state, rawStatusText);
  if (stateClass === "TERMINAL_COMPLETED") status = "Completed";
  else if (stateClass === "TERMINAL_ABANDONED") status = "Abandoned";
  else if (stateClass === "NON_TERMINAL") status = deriveNonTerminalStatus(startTimeMs, nowMs);
  else if (stateUpper === "IN PROGRESS" || stateUpper === "LIVE" || stateUpper === "TOSS" || stateUpper === "STUMPS" || stateUpper === "INNINGS BREAK") status = deriveNonTerminalStatus(startTimeMs, nowMs);
  else if (stateUpper === "PREVIEW" || stateUpper === "UPCOMING") status = "Upcoming";
  const t1 = info.team1 || {};
  const t2 = info.team2 || {};
  const score = rawStatusText;
  return {
    id: info.matchId.toString(),
    seriesId: (info.seriesId || "0").toString(),
    seriesName: info.seriesName || "Unknown Series",
    title: `${t1.teamName || "T1"} vs ${t2.teamName || "T2"}`,
    shortTitle: `${t1.teamSName || "T1"} vs ${t2.teamSName || "T2"}`,
    status,
    stateClass,
    matchFormat: info.matchFormat ? info.matchFormat.toUpperCase() : "T20",
    // COMPATIBILITY FIELDS
    team1Name: t1.teamName || "Team A",
    team2Name: t2.teamName || "Team B",
    team1ShortName: t1.teamSName || "T1",
    team2ShortName: t2.teamSName || "T2",
    matchDesc: `${t1.teamName} vs ${t2.teamName}`,
    startDate: startTimeMs,
    endDate: parseInt(info.endDate) || parseInt(info.startDate) + 144e5,
    venue: info.venueInfo ? info.venueInfo.ground : "TBD",
    startTime: startTimeMs,
    teamA: t1.teamName || "Team A",
    teamB: t2.teamName || "Team B",
    teamAImg: t1.imageId ? `https://static.cricbuzz.com/a/img/v1/i1/c${t1.imageId}/i.jpg` : "",
    teamBImg: t2.imageId ? `https://static.cricbuzz.com/a/img/v1/i1/c${t2.imageId}/i.jpg` : "",
    team1Id: (t1.teamId || "0").toString(),
    team2Id: (t2.teamId || "0").toString(),
    lastUpdated: normalizeSnapshotInt(
      info.lastUpdated || info.lastUpdatedTime || info.lastUpdatedTs || info.startDate
    ),
    lastScore: score,
    lastWickets: 0,
    lastOver: "0.0",
    lastInnings: 1
  };
}
__name(formatCricbuzzMatch, "formatCricbuzzMatch");

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

// workers/contest_engine.js
init_checked_fetch();
init_modules_watch_stub();

// workers/payment_service.js
init_checked_fetch();
init_modules_watch_stub();
async function createCashfreeOrder(userId, amount, env) {
  try {
    const appId = env.CASHFREE_APP_ID;
    const secretKey = env.CASHFREE_SECRET_KEY;
    const useSandbox = env.CASHFREE_IS_SANDBOX === "true";
    if (!appId || !secretKey) {
      throw new Error("Cashfree credentials missing in backend config");
    }
    const baseUrl = useSandbox ? "https://sandbox.cashfree.com/pg/orders" : "https://api.cashfree.com/pg/orders";
    const orderId = `order_${Date.now()}_${userId.substring(0, 5)}`;
    const payload = {
      order_id: orderId,
      order_amount: amount,
      order_currency: "INR",
      customer_details: {
        customer_id: userId,
        customer_phone: "9999999999",
        customer_name: `User ${userId.substring(0, 5)}`
      },
      order_meta: {
        return_url: `https://fantacy-app.pages.dev/wallet?order_id={order_id}`,
        notify_url: `${env.WORKER_URL}/api/payment-webhook`
      }
    };
    const response = await fetch(baseUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-client-id": appId,
        "x-client-secret": secretKey,
        "x-api-version": "2023-08-01"
      },
      body: JSON.stringify(payload)
    });
    const data = await response.json();
    if (response.status === 200 || response.status === 201) {
      const transactionData = await savePendingTransaction(userId, orderId, amount, env);
      const sessionId = data.payment_session_id;
      const wrapperLink = `${env.WORKER_URL}/pay?session_id=${sessionId}&env=${useSandbox ? "sandbox" : "prod"}`;
      return {
        success: true,
        orderId,
        transactionData,
        paymentLink: wrapperLink,
        // Return our Wrapper Link
        raw: data
      };
    } else {
      console.error("Cashfree Error:", data);
      throw new Error(data.message || "Failed to create order");
    }
  } catch (error) {
    console.error("Create Order Exception:", error);
    return { success: false, error: error.message };
  }
}
__name(createCashfreeOrder, "createCashfreeOrder");
async function savePendingTransaction(userId, orderId, amount, env) {
  const transaction = {
    id: orderId,
    // Vital: This ensures Firestore Doc ID matches Order ID
    userId,
    type: "deposit",
    amount: Number(amount),
    status: "pending",
    orderId,
    createdAt: (/* @__PURE__ */ new Date()).toISOString(),
    gateway: "cashfree"
  };
  return transaction;
}
__name(savePendingTransaction, "savePendingTransaction");

// workers/webhook_handler.js
init_checked_fetch();
init_modules_watch_stub();
async function verifySignature(ts, body2, signature, secret) {
  if (!ts || !signature || !secret) throw new Error("Missing verification headers/config");
  const now = Math.floor(Date.now() / 1e3);
  const webhookTimeMs = parseInt(ts, 10);
  const webhookTimeSeconds = Math.floor(webhookTimeMs / 1e3);
  if (Math.abs(now - webhookTimeSeconds) > 300) {
    console.error(`Timestamp Expired: Now ${now}, Hook ${webhookTimeSeconds}`);
    throw new Error("Webhook Timestamp expired");
  }
  const data = ts + body2;
  const encoder = new TextEncoder();
  const keyData = encoder.encode(secret);
  const msgData = encoder.encode(data);
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    keyData,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const sigBuf = await crypto.subtle.sign("HMAC", cryptoKey, msgData);
  let binary = "";
  const bytes = new Uint8Array(sigBuf);
  const len = bytes.byteLength;
  for (let i = 0; i < len; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  const computedSig = btoa(binary);
  if (computedSig !== signature) {
    throw new Error(`Signature Mismatch: Computed ${computedSig} vs Header ${signature}`);
  }
}
__name(verifySignature, "verifySignature");
async function handleCashfreeWebhook(request, env) {
  try {
    const signature = request.headers.get("x-webhook-signature");
    const timestamp = request.headers.get("x-webhook-timestamp");
    const bodyText = await request.text();
    console.log(`[Webhook Debug] TS: ${timestamp}, Sig: ${signature ? "Present" : "Missing"}`);
    try {
      await verifySignature(timestamp, bodyText, signature, env.CASHFREE_SECRET_KEY);
      console.log("\u2705 Webhook Verified/Authentic");
    } catch (sigError) {
      console.error(`[Webhook Sig Failed] ${sigError.message}`);
      throw sigError;
    }
    const data = JSON.parse(bodyText);
    if (data.type === "PAYMENT_SUCCESS_WEBHOOK" || data.type === "PAYMENT_SUCCESS") {
      const orderId = data.data.order.order_id;
      const amount = data.data.order.order_amount;
      return {
        action: "UPDATE_WALLET",
        orderId,
        amount,
        status: "SUCCESS",
        gatewayData: data
      };
    } else if (data.type === "PAYMENT_FAILED_WEBHOOK") {
      return {
        action: "UPDATE_TRANSACTION_FAILED",
        orderId: data.data.order.order_id,
        gatewayData: data
      };
    }
    return { action: "IGNORE", reason: "Unknown Event Type" };
  } catch (e) {
    console.error("Webhook Verification Error:", e.message);
    return { action: "ERROR", error: e.message };
  }
}
__name(handleCashfreeWebhook, "handleCashfreeWebhook");

// workers/leaderboard_engine.js
init_checked_fetch();
init_modules_watch_stub();
async function processLeaderboards(env) {
  console.log("Starting Leaderboard Calculation Cycle (Optimized)...");
  try {
    const recentCutoff = Date.now() - 20 * 60 * 1e3;
    const { results: activeMatches } = await env.DB.prepare(
      `SELECT id, status, last_updated FROM matches 
             WHERE status = 'Live' 
             OR (status = 'Completed' AND last_updated > ?)`
    ).bind(recentCutoff).all();
    if (!activeMatches || activeMatches.length === 0) {
      console.log("No active matches to process.");
      return;
    }
    for (const match of activeMatches) {
      await calculateLeaderboardForMatch(env, match.id);
    }
  } catch (e) {
    console.error("Leaderboard Cycle Error:", e);
  }
}
__name(processLeaderboards, "processLeaderboards");
async function calculateLeaderboardForMatch(env, matchId) {
  console.log(`Calculating for Match: ${matchId}`);
  const { results: pointRows } = await env.DB.prepare(
    "SELECT player_id, points FROM fantasy_points WHERE match_id = ?"
  ).bind(matchId).all();
  const pointsMap = {};
  pointRows.forEach((r) => pointsMap[r.player_id] = r.points || 0);
  const { results: participants } = await env.DB.prepare(
    "SELECT contest_id, user_id, team_name, player_ids, team_id FROM contest_participants WHERE match_id = ?"
  ).bind(matchId).all();
  if (!participants || participants.length === 0) return;
  const contestGroups = {};
  for (const p of participants) {
    if (!contestGroups[p.contest_id]) contestGroups[p.contest_id] = [];
    contestGroups[p.contest_id].push(p);
  }
  const stmt = env.DB.prepare(
    "INSERT OR REPLACE INTO contest_leaderboards (contest_id, match_id, data, last_updated) VALUES (?, ?, ?, ?)"
  );
  const batch = [];
  for (const contestId in contestGroups) {
    const entries = contestGroups[contestId];
    const leaderboard = entries.map((entry) => {
      let total = 0;
      let pIds = [];
      try {
        pIds = JSON.parse(entry.player_ids || "[]");
      } catch (e) {
        pIds = [];
      }
      pIds.forEach((pid) => {
        total += pointsMap[pid] || 0;
      });
      return {
        userId: entry.user_id,
        teamName: entry.team_name,
        points: total,
        teamId: entry.team_id
      };
    });
    leaderboard.sort((a, b) => b.points - a.points);
    let rank = 1;
    for (let i = 0; i < leaderboard.length; i++) {
      if (i > 0 && leaderboard[i].points < leaderboard[i - 1].points) {
        rank = i + 1;
      }
      leaderboard[i].rank = rank;
    }
    batch.push(stmt.bind(
      contestId,
      matchId,
      JSON.stringify(leaderboard),
      Date.now()
    ));
  }
  if (batch.length > 0) {
    await env.DB.batch(batch);
    console.log(`Updated ${batch.length} contests for Match ${matchId}`);
  }
}
__name(calculateLeaderboardForMatch, "calculateLeaderboardForMatch");

// workers/index.js
init_squad_engine();

// workers/payout_engine.js
init_checked_fetch();
init_modules_watch_stub();
async function processPayoutsForMatch(env, matchId) {
  console.log(`\u{1F4B0} Starting Payout Cycle for Match: ${matchId}`);
  try {
    const match = await env.DB.prepare("SELECT status FROM matches WHERE id = ?").bind(matchId).first();
    if (!match || match.status !== "Completed" && match.status !== "Finished") {
      console.log("Match not completed yet. Skipping payouts.");
      return;
    }
    const { results: contests } = await env.DB.prepare("SELECT * FROM contests WHERE match_id = ?").bind(matchId).all();
    console.log(`Found ${contests.length} contests for match.`);
    for (const contest of contests) {
      if (contest.status === "Distributed" || contest.status === "Cancelled") {
        continue;
      }
      await distributePrizes(env, contest);
    }
  } catch (e) {
    console.error(`\u274C Payout Error for ${matchId}:`, e);
  }
}
__name(processPayoutsForMatch, "processPayoutsForMatch");
async function distributePrizes(env, contest) {
  const contestId = contest.id;
  const breakdown = parseWinningBreakdown(contest.winning_breakdown || contest.winningBreakdown);
  if (!breakdown || breakdown.length === 0) {
    console.log(`No payout structure for ${contestId}`);
    return;
  }
  console.log(`\u{1F9EE} Calculating Payouts for Contest ${contestId}...`);
  const lbRow = await env.DB.prepare("SELECT data FROM contest_leaderboards WHERE contest_id = ?").bind(contestId).first();
  if (!lbRow || !lbRow.data) {
    console.log(`No leaderboard found for ${contestId}. Skipping.`);
    return;
  }
  const leaderboard = JSON.parse(lbRow.data);
  const winners = [];
  for (const entry of leaderboard) {
    const rank = entry.rank;
    const prize = getPrizeForRank(rank, breakdown);
    if (prize > 0) {
      winners.push({
        userId: entry.userId || entry.user_id,
        // Safety check for field name
        amount: prize,
        rank
      });
    }
  }
  if (winners.length === 0) {
    console.log("No winners found.");
    return;
  }
  console.log(`\u{1F4B8} Distributing to ${winners.length} winners...`);
  await processD1Payouts(env, winners, contestId);
  await env.DB.prepare("UPDATE contests SET status = 'Distributed' WHERE id = ?").bind(contestId).run();
  console.log(`\u2705 Payouts Complete for ${contestId}`);
}
__name(distributePrizes, "distributePrizes");
function getPrizeForRank(rank, breakdown) {
  for (const tier of breakdown) {
    if (rank >= tier.rankStart && rank <= tier.rankEnd) {
      return tier.amount;
    }
  }
  return 0;
}
__name(getPrizeForRank, "getPrizeForRank");
function parseWinningBreakdown(field) {
  if (!field) return [];
  try {
    if (typeof field === "string") return JSON.parse(field);
    return field;
  } catch (e) {
    return [];
  }
}
__name(parseWinningBreakdown, "parseWinningBreakdown");
async function processD1Payouts(env, winners, contestId) {
  for (const w of winners) {
    const txnId = `win_${contestId}_${w.userId}`;
    try {
      await env.DB.prepare(`
                UPDATE users SET winning_credits = winning_credits + ? WHERE id = ?
            `).bind(w.amount, w.userId).run();
      await env.DB.prepare(`
                INSERT INTO transactions (id, user_id, type, amount, contest_id, created_at, status)
                VALUES (?, ?, 'winnings', ?, ?, ?, 'success')
            `).bind(txnId, w.userId, w.amount, contestId, Date.now()).run();
    } catch (e) {
      console.error(`Failed to payout user ${w.userId} for contest ${contestId}:`, e);
    }
  }
}
__name(processD1Payouts, "processD1Payouts");

// workers/voucher_engine.js
init_checked_fetch();
init_modules_watch_stub();
async function handleVoucherRequest(request, env) {
  if (request.method !== "POST") return jsonResponse({ error: "Method Not Allowed" }, 405);
  try {
    const { userId, brand, amount } = body;
    if (!userId || !brand || !amount) return jsonResponse({ error: "Missing fields" }, 400);
    const user = await env.DB.prepare("SELECT winning_credits FROM users WHERE id = ?").bind(userId).first();
    const currentBenefits = user ? user.winning_credits || 0 : 0;
    if (currentBenefits < amount) {
      return jsonResponse({ error: "Insufficient Benefits for this claim" }, 402);
    }
    const reqId = `vr_${Date.now()}_${Math.random().toString(36).substring(7)}`;
    const statements = [
      env.DB.prepare(`
                UPDATE users SET winning_credits = winning_credits - ? 
                WHERE id = ? AND winning_credits >= ?
            `).bind(credits, userId, credits),
      env.DB.prepare(`
                INSERT INTO voucher_requests (id, user_id, brand, credits, status, created_at)
                VALUES (?, ?, ?, ?, 'pending', ?)
            `).bind(reqId, userId, brand, credits, Date.now()),
      env.DB.prepare(`
                INSERT INTO transactions (id, user_id, type, amount, created_at, status)
                VALUES (?, ?, 'voucher_request', ?, ?, 'pending')
            `).bind(reqId, userId, credits, Date.now())
    ];
    const results = await env.DB.batch(statements);
    if (results[0].meta.changes === 0) {
      return jsonResponse({ error: "Deduction failed (Balance changed or User not found)" }, 409);
    }
    return jsonResponse({ success: true, message: "Request Submitted", requestId: reqId });
  } catch (e) {
    return jsonResponse({ error: e.message }, 500);
  }
}
__name(handleVoucherRequest, "handleVoucherRequest");
async function handleVoucherUserHistory(userId, env) {
  try {
    const { results } = await env.DB.prepare(`
            SELECT * FROM voucher_requests 
            WHERE user_id = ? 
            ORDER BY created_at DESC
        `).bind(userId).all();
    return jsonResponse({ success: true, history: results });
  } catch (e) {
    return jsonResponse({ error: e.message }, 500);
  }
}
__name(handleVoucherUserHistory, "handleVoucherUserHistory");
async function handleAdminVoucherList(env) {
  try {
    const pending = await env.DB.prepare("SELECT * FROM voucher_requests WHERE status = 'pending' ORDER BY created_at ASC").all();
    const history = await env.DB.prepare("SELECT * FROM voucher_requests WHERE status != 'pending' ORDER BY created_at DESC LIMIT 20").all();
    return jsonResponse({
      success: true,
      pending: pending.results,
      history: history.results
    });
  } catch (e) {
    return jsonResponse({ error: e.message }, 500);
  }
}
__name(handleAdminVoucherList, "handleAdminVoucherList");
async function handleAdminApproveVoucher(request, env) {
  if (request.method !== "POST") return jsonResponse({ error: "Method Not Allowed" }, 405);
  try {
    const body2 = await request.json();
    const { requestId, code, action } = body2;
    if (!requestId || !action) return jsonResponse({ error: "Missing fields" }, 400);
    if (action === "approve") {
      if (!code) return jsonResponse({ error: "Voucher Code Required" }, 400);
      const statements = [
        env.DB.prepare(`
                    UPDATE voucher_requests 
                    SET status = 'approved', voucher_code = ?, approved_at = ?
                    WHERE id = ? AND status = 'pending'
                `).bind(code, Date.now(), requestId),
        env.DB.prepare("UPDATE transactions SET status = 'success' WHERE id = ?").bind(requestId)
      ];
      const results = await env.DB.batch(statements);
      if (results[0].meta.changes === 0) return jsonResponse({ error: "ALREADY_PROCESSED" }, 409);
      return jsonResponse({ success: true, message: "Voucher Approved" });
    } else if (action === "reject") {
      const req = await env.DB.prepare("SELECT user_id, credits FROM voucher_requests WHERE id = ? AND status = 'pending'").bind(requestId).first();
      if (!req) return jsonResponse({ error: "Request not found or already processed" }, 404);
      const statements = [
        env.DB.prepare("UPDATE users SET winning_credits = winning_credits + ? WHERE id = ?").bind(req.credits, req.user_id),
        env.DB.prepare(`
                    UPDATE voucher_requests 
                    SET status = 'rejected', approved_at = ?
                    WHERE id = ? AND status = 'pending'
                 `).bind(Date.now(), requestId),
        env.DB.prepare("UPDATE transactions SET status = 'rejected' WHERE id = ?").bind(requestId)
      ];
      const results = await env.DB.batch(statements);
      if (results[1].meta.changes === 0) return jsonResponse({ error: "ALREADY_PROCESSED" }, 409);
      return jsonResponse({ success: true, message: "Request Rejected & Refunded" });
    }
    return jsonResponse({ error: "Invalid Action" }, 400);
  } catch (e) {
    return jsonResponse({ error: e.message }, 500);
  }
}
__name(handleAdminApproveVoucher, "handleAdminApproveVoucher");

// workers/economy_engine.js
init_checked_fetch();
init_modules_watch_stub();
async function processEconomy(env) {
  console.log("\u{1F3ED} Economy Engine Triggered");
  try {
    const { results: upcomingMatches } = await env.DB.prepare(
      "SELECT id, title, start_time FROM matches WHERE status = 'Upcoming'"
    ).all();
    console.log(`\u{1F50D} Found ${upcomingMatches.length} upcoming matches.`);
    for (const match of upcomingMatches) {
      await initializeMatch(env, match);
      await monitorTraffic(env, match.id);
    }
  } catch (e) {
    console.error("\u274C Economy Engine Error:", e);
  }
}
__name(processEconomy, "processEconomy");
async function initializeMatch(env, match) {
  const matchId = match.id.toString();
  const state = await env.DB.prepare("SELECT * FROM auto_contests WHERE match_id = ?").bind(matchId).first();
  if (!state) {
    console.log(`\u{1F195} Initializing Economy for Match: ${match.title} (${matchId})`);
    await createContestIdempotent(env, matchId, 0, "Practice Arena", 100);
    await createContestIdempotent(env, matchId, 5, "Starter Contest", 100);
    await createContestIdempotent(env, matchId, 10, "Head to Head", 2);
    await env.DB.prepare("INSERT INTO auto_contests (match_id, last_tier_unlocked, created_at) VALUES (?, ?, ?)").bind(matchId, 10, Date.now()).run();
  }
}
__name(initializeMatch, "initializeMatch");
async function monitorTraffic(env, matchId) {
  const state = await env.DB.prepare("SELECT * FROM auto_contests WHERE match_id = ?").bind(matchId).first();
  if (!state) return;
  let currentTier = state.last_tier_unlocked || 0;
  let nextTierFee = 0;
  let nextTierName = "";
  let nextTierSpots = 100;
  if (currentTier === 10) {
    nextTierFee = 29;
    nextTierName = "Hot Contest";
  } else if (currentTier === 29) {
    nextTierFee = 49;
    nextTierName = "Mega Contest";
  } else {
    return;
  }
  const { results: activeContests } = await env.DB.prepare(
    "SELECT filled_spots, total_spots FROM contests WHERE match_id = ? AND entry_fee = ?"
  ).bind(matchId, currentTier).all();
  let shouldUnlock = false;
  for (const c of activeContests) {
    if (c.total_spots > 0 && c.filled_spots / c.total_spots > 0.5) {
      shouldUnlock = true;
      break;
    }
  }
  if (shouldUnlock) {
    console.log(`\u{1F680} Traffic Detected! Unlocking \u20B9${nextTierFee} for ${matchId}`);
    const success = await createContestIdempotent(env, matchId, nextTierFee, nextTierName, nextTierSpots);
    if (success) {
      await env.DB.prepare("UPDATE auto_contests SET last_tier_unlocked = ? WHERE match_id = ?").bind(nextTierFee, matchId).run();
    }
  }
}
__name(monitorTraffic, "monitorTraffic");
async function createContestIdempotent(env, matchId, entryFee, category, totalSpots) {
  const existing = await env.DB.prepare(
    "SELECT id FROM contests WHERE match_id = ? AND entry_fee = ?"
  ).bind(matchId, entryFee).first();
  if (existing) {
    return false;
  }
  const contestId = crypto.randomUUID();
  const isPractice = entryFee === 0;
  await env.DB.prepare(`
        INSERT INTO contests (
            id, match_id, entry_fee, total_spots, filled_spots, 
            category, is_guaranteed, is_flexible, 
            status, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
    contestId,
    matchId,
    entryFee,
    totalSpots,
    0,
    // filled_spots
    category,
    0,
    // is_guaranteed (False)
    1,
    // is_flexible (True - important for dynamic pool)
    "Upcoming",
    Date.now()
  ).run();
  console.log(`\u2705 Created Contest: ${category} (\u20B9${entryFee}) for ${matchId}`);
  return true;
}
__name(createContestIdempotent, "createContestIdempotent");

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
        const { rating, credits: credits2 } = calculateRating(data);
        const role = normalizeRole(data.role);
        await env.DB.prepare(`
                    INSERT INTO player_stats (player_id, fantasy_rating, credits, role_normalized, last_updated)
                    VALUES (?, ?, ?, ?, ?)
                    ON CONFLICT(player_id) DO UPDATE SET
                        fantasy_rating = excluded.fantasy_rating,
                        credits = excluded.credits,
                        role_normalized = excluded.role_normalized,
                        last_updated = excluded.last_updated
                `).bind(pid, rating, credits2, role, now).run();
        logs.push(`\u2705 Saved ${pid}: Rating=${rating}, Credits=${credits2}`);
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
  let credits2 = 8.5;
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
    credits2 = 8 + (rating - 40) * 0.0416;
    credits2 = Math.min(10.5, Math.max(8, credits2));
    credits2 = Math.round(credits2 * 2) / 2;
  } catch (e) {
  }
  return { rating, credits: credits2 };
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

// workers/refund_engine.js
init_checked_fetch();
init_modules_watch_stub();

// workers/index.js
var corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "*"
};
var MAJOR_LEAGUE_SERIES_KEYWORDS = [
  "IPL",
  "INDIAN PREMIER",
  "PSL",
  "PAKISTAN SUPER",
  "BIG BASH",
  "BBL",
  "THE HUNDRED",
  "WOMEN'S PREMIER",
  "WPL",
  "SA20",
  "ILT20",
  "CARIBBEAN PREMIER",
  "CPL",
  "MAJOR LEAGUE CRICKET",
  "MLC",
  "LANKA PREMIER",
  "LPL"
];
var INTERNATIONAL_TEAM_NAMES = /* @__PURE__ */ new Set([
  "AFGHANISTAN",
  "AFG",
  "AUSTRALIA",
  "AUS",
  "BANGLADESH",
  "BAN",
  "CANADA",
  "CAN",
  "ENGLAND",
  "ENG",
  "HONG KONG",
  "HKG",
  "INDIA",
  "IND",
  "IRELAND",
  "IRE",
  "NAMIBIA",
  "NAM",
  "NETHERLANDS",
  "NED",
  "NEPAL",
  "NEP",
  "NEW ZEALAND",
  "NZ",
  "OMAN",
  "OMA",
  "PAKISTAN",
  "PAK",
  "PAPUA NEW GUINEA",
  "PNG",
  "SCOTLAND",
  "SCO",
  "SOUTH AFRICA",
  "SA",
  "SRI LANKA",
  "SL",
  "UNITED ARAB EMIRATES",
  "UAE",
  "USA",
  "WEST INDIES",
  "WI",
  "ZIMBABWE",
  "ZIM"
]);
function normalizeMatchFilterText(value) {
  return String(value || "").trim().toUpperCase();
}
__name(normalizeMatchFilterText, "normalizeMatchFilterText");
function normalizeMatchStatus(value) {
  return String(value || "").trim().toUpperCase();
}
__name(normalizeMatchStatus, "normalizeMatchStatus");
function isActiveStatusBypass(status) {
  return status === "LIVE" || status === "STARTED" || status === "IN PROGRESS" || status === "INNINGS BREAK";
}
__name(isActiveStatusBypass, "isActiveStatusBypass");
function isTerminalVisibilityStatus(status) {
  return status === "COMPLETED" || status === "FINISHED" || status === "ABANDONED" || status === "CANCELLED" || status === "CANCELED";
}
__name(isTerminalVisibilityStatus, "isTerminalVisibilityStatus");
function isAboutToStartBypass(status, startTime, nowMs) {
  const start = Number(startTime || 0);
  if (!Number.isFinite(start) || start <= 0) return false;
  const activeOrUpcoming = status === "UPCOMING" || isActiveStatusBypass(status);
  return activeOrUpcoming && start <= nowMs + 15 * 60 * 1e3;
}
__name(isAboutToStartBypass, "isAboutToStartBypass");
function isStartedBypass(status, startTime, nowMs) {
  const start = Number(startTime || 0);
  if (!Number.isFinite(start) || start <= 0) return false;
  return start <= nowMs && !isTerminalVisibilityStatus(status);
}
__name(isStartedBypass, "isStartedBypass");
function isMajorLeagueSeries(seriesName) {
  const normalizedSeries = normalizeMatchFilterText(seriesName);
  if (!normalizedSeries) return false;
  return MAJOR_LEAGUE_SERIES_KEYWORDS.some((keyword) => normalizedSeries.includes(keyword));
}
__name(isMajorLeagueSeries, "isMajorLeagueSeries");
function isInternationalTeamName(teamName) {
  const normalizedTeam = normalizeMatchFilterText(teamName);
  if (!normalizedTeam) return false;
  if (INTERNATIONAL_TEAM_NAMES.has(normalizedTeam)) return true;
  const withoutWomenSuffix = normalizedTeam.replace(/\s+WOMEN$/, "").replace(/\s+W$/, "");
  if (INTERNATIONAL_TEAM_NAMES.has(withoutWomenSuffix)) return true;
  const withoutAgeSuffix = withoutWomenSuffix.replace(/\s+U19$/, "").replace(/\s+UNDER[\s-]?19$/, "");
  return INTERNATIONAL_TEAM_NAMES.has(withoutAgeSuffix);
}
__name(isInternationalTeamName, "isInternationalTeamName");
function shouldServeCuratedMatch(matchRow) {
  if (!matchRow || typeof matchRow !== "object") return false;
  const seriesName = matchRow.series_name || matchRow.seriesName || matchRow.title || "";
  if (isPrioritySeries(seriesName) || isMajorLeagueSeries(seriesName)) {
    return true;
  }
  const teamA = matchRow.team_a || matchRow.teamA || "";
  const teamB = matchRow.team_b || matchRow.teamB || "";
  if (isInternationalTeamName(teamA) && isInternationalTeamName(teamB)) {
    return true;
  }
  if (teamA && teamB && teamA !== "TBA" && teamB !== "TBA" && teamA !== "T1" && teamB !== "T2") {
    return true;
  }
  return false;
}
__name(shouldServeCuratedMatch, "shouldServeCuratedMatch");
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
    ctx.waitUntil(safeRun("POINTS_ENGINE", () => processLivePoints(env)));
    ctx.waitUntil(safeRun("LEADERBOARD_ENGINE", () => processLeaderboards(env)));
    ctx.waitUntil(safeRun("ECONOMY_ENGINE", () => processEconomy(env)));
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
      if (url.pathname === "/api/wallet/balance") {
        const uid = url.searchParams.get("userId");
        if (!uid) return jsonResponse({ error: "userId required" }, 400);
        return await handleGetWalletBalance(uid.trim(), env);
      }
      if (url.pathname === "/api/wallet/transactions" || url.pathname === "/api/transactions/my") {
        const uid = url.searchParams.get("userId");
        if (!uid) return jsonResponse({ error: "userId required" }, 400);
        return await handleGetTransactionHistory(uid.trim(), env);
      }
      if (url.pathname === "/api/wallet/withdraw") return await handleWithdrawRequest(request, env);
      if (url.pathname === "/api/admin/withdrawals") return await handleAdminListWithdrawals(request, env);
      if (url.pathname === "/api/admin/payout/status") return await handleAdminUpdateWithdrawalStatus(request, env);
      if (url.pathname === "/api/admin/payout/reward") return await handleAdminIssueReward(request, env);
      if (url.pathname === "/api/admin/user/search") return await handleAdminUserSearch(request, env);
      if (url.pathname === "/api/admin/users") return await handleAdminListUsers(request, env);
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
      if (path === "/pay") return handlePaymentRedirect(url.searchParams, env);
      if (path === "/api/create-payment") return handleCreatePayment(request, env);
      if (path === "/api/payment-webhook") return handlePaymentWebhook(request, env);
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
      if (path === "/api/admin/payouts/distribute") {
        if (request.method !== "POST") return jsonResponse({ error: "Method Not Allowed" }, 405);
        const body2 = await request.json();
        if (!body2.matchId) return jsonResponse({ error: "Match ID required" }, 400);
        await processPayoutsForMatch(env, body2.matchId);
        return jsonResponse({ success: true, message: `Payout Process Initiated for ${body2.matchId}` });
      }
      if (path === "/api/admin/match/squad") return handleAdminSaveSquad(request, env);
      if (path === "/api/admin/match/participants") {
        const matchId = url.searchParams.get("matchId");
        if (!matchId) return jsonResponse({ success: false, error: "matchId required" }, 400);
        return handleGetMatchParticipants(matchId, env);
      }
      if (path === "/api/voucher/request") return handleVoucherRequest(request, env);
      if (path === "/api/voucher/my") {
        const uid = url.searchParams.get("userId");
        if (!uid) return jsonResponse({ error: "UserId required" }, 400);
        return handleVoucherUserHistory(uid, env);
      }
      if (path === "/api/debug/all-users") {
        const { results } = await env.DB.prepare("SELECT * FROM users").all();
        return jsonResponse({ users: results });
      }
      if (path === "/api/user/sync") {
        return handleUserSync(request, env);
      }
      if (path === "/api/admin/voucher/list") return handleAdminVoucherList(env);
      if (path === "/api/admin/voucher/approve") return handleAdminApproveVoucher(request, env);
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
      if (path === "/diag") return handleGlobalDiag(env);
      if (path === "/stats-metrics") return handleGetStatsMetrics(url.searchParams.get("match_id"), env);
      if (path === "/debug-api" || path === "/api/debug-api") return handleDebugApi(env);
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
async function handleCreatePayment(request, env) {
  try {
    const body2 = await request.json();
    const { userId, amount } = body2;
    if (!userId || !amount) {
      return jsonResponse({ success: false, error: "UserId and Amount required" }, 400);
    }
    const result = await createCashfreeOrder(userId, amount, env);
    if (result.success && result.transactionData) {
      const t = result.transactionData;
      await env.DB.prepare(`
                INSERT INTO transactions (id, user_id, type, amount, created_at, status)
                VALUES (?, ?, 'deposit', ?, ?, 'pending')
            `).bind(t.id, t.userId, t.amount, Date.now()).run();
      delete result.transactionData;
    }
    return jsonResponse(result);
  } catch (e) {
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleCreatePayment, "handleCreatePayment");
async function handlePaymentWebhook(request, env) {
  try {
    const result = await handleCashfreeWebhook(request, env);
    if (result.action === "UPDATE_WALLET") {
      const { orderId, amount } = result;
      const updateRes = await env.DB.prepare(`
                UPDATE transactions 
                SET status = 'success' 
                WHERE id = ? AND status = 'pending'
            `).bind(orderId).run();
      if (updateRes.meta.changes > 0) {
        const txn = await env.DB.prepare("SELECT user_id FROM transactions WHERE id = ?").bind(orderId).first();
        const userId = txn.user_id;
        await env.DB.prepare(`
                    UPDATE users SET deposit_credits = deposit_credits + ? WHERE id = ?
                `).bind(amount, userId).run();
        console.log(`\u2705 Wallet Updated for ${userId}: +${amount}`);
      } else {
        console.log(`\u26A0\uFE0F Transaction ${orderId} already processed or not found.`);
      }
    } else if (result.action === "UPDATE_TRANSACTION_FAILED") {
      await env.DB.prepare(`
                UPDATE transactions SET status = 'failed' WHERE id = ?
            `).bind(result.orderId).run();
    }
    return new Response("OK", { status: 200 });
  } catch (e) {
    console.error("Webhook Handler Failed:", e);
    return new Response("Error", { status: 500 });
  }
}
__name(handlePaymentWebhook, "handlePaymentWebhook");
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
async function handleGetMatches(env) {
  try {
    const { results } = await env.DB.prepare("SELECT * FROM matches ORDER BY start_time ASC").all();
    const { results: lineupRows } = await env.DB.prepare(`
            SELECT DISTINCT CAST(match_id AS TEXT) AS match_id
            FROM match_squads
            WHERE playing_11_a IS NOT NULL OR playing_11_b IS NOT NULL
        `).all();
    const { results: joinedRows } = await env.DB.prepare(`
            SELECT DISTINCT CAST(match_id AS TEXT) AS match_id
            FROM contest_participants
        `).all();
    const lineupMatchSet = new Set((lineupRows || []).map((r) => String(r.match_id || "").trim()).filter(Boolean));
    const joinedMatchSet = new Set((joinedRows || []).map((r) => String(r.match_id || "").trim()).filter(Boolean));
    const nowMs = Date.now();
    const curatedMatches = Array.isArray(results) ? results.filter((match) => {
      const matchId = String(match?.id || "").trim();
      const status = normalizeMatchStatus(match?.status);
      const startTime = Number(match?.start_time || 0);
      const activeMatchBypass = isActiveStatusBypass(status) || lineupMatchSet.has(matchId) || joinedMatchSet.has(matchId) || isAboutToStartBypass(status, startTime, nowMs) || isStartedBypass(status, startTime, nowMs);
      if (activeMatchBypass) return true;
      return shouldServeCuratedMatch(match);
    }) : [];
    return jsonResponse({ success: true, matches: curatedMatches });
  } catch (error) {
    return jsonResponse({ success: false, error: error.message });
  }
}
__name(handleGetMatches, "handleGetMatches");
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
      let credits2 = 8;
      let rating = 50;
      if (stat) {
        credits2 = stat.credits || 8;
        rating = stat.fantasy_rating || 50;
      } else {
        const baseCredit = role === "AR" ? 8.5 : 8;
        credits2 = baseCredit + pidHash % 6 * 0.5;
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
        credits: credits2,
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
    const body2 = await request.json();
    const { matchId, teamA, teamB, xiA, xiB } = body2;
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
async function handleGetWalletBalance(userId, env) {
  try {
    console.log(`D1: Fetching balance for [${userId}]`);
    const user = await ensureUserInD1(userId, env);
    if (!user) {
      console.log(`D1: User NOT found for [${userId}] after sync attempt`);
    } else {
      console.log(`D1: Found user, winnings: ${user.winning_credits}`);
    }
    const deposit = user ? user.deposit_credits || 0 : 0;
    const winnings = user ? user.winning_credits || 0 : 0;
    return jsonResponse({
      success: true,
      balance: {
        deposit,
        winnings,
        total: deposit + winnings
      }
    });
  } catch (e) {
    console.error("D1 Error:", e);
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleGetWalletBalance, "handleGetWalletBalance");
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
function handlePaymentRedirect(params, env) {
  const sessionId = params.get("session_id");
  const environment = params.get("env") || "prod";
  if (!sessionId) return new Response("Missing Session ID", { status: 400 });
  const sdkUrl = "https://sdk.cashfree.com/js/v3/cashfree.js";
  const html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <!-- Prevent Caching -->
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <title>Redirecting to Payment...</title>
    <script src="${sdkUrl}"><\/script>
    <style>
        body { font-family: sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; background: #f0f2f5; }
        .loader { border: 4px solid #f3f3f3; border-top: 4px solid #3498db; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
        .container { text-align: center; }
        p { margin-top: 20px; color: #555; }
    </style>
</head>
<body>
    <div class="container">
        <div class="loader" style="margin:0 auto;"></div>
        <p>Redirecting to Secure Payment Gateway...</p>
        <p style="font-size:12px; color:#999">Session: ${sessionId.substring(0, 10)}...</p>
    </div>
    <script>
        window.onload = function() {
            try {
                console.log("Initializing Cashfree v3...");
                // V3 Factory - try without new first, or check type
                const cashfree = Cashfree({
                    mode: "${environment === "sandbox" ? "sandbox" : "production"}"
                });
                console.log("Cashfree Instance:", cashfree); 
                console.log("Redirecting...");
                cashfree.checkout({
                    paymentSessionId: "${sessionId}",
                    redirectTarget: "_self"
                });
            } catch(e) {
                console.error("Initialization Error:", e);
                document.body.innerHTML = "<p style='color:red; text-align:center'>Error: " + e.message + "<br><br>Check Console for details.</p>";
            }
        };
    <\/script>
</body>
</html>
    `;
  return new Response(html, {
    headers: {
      "Content-Type": "text/html",
      "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
      "Pragma": "no-cache",
      "Expires": "0",
      ...corsHeaders
    }
  });
}
__name(handlePaymentRedirect, "handlePaymentRedirect");
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
async function handleGetTransactions(userId, env) {
  try {
    const { results } = await env.DB.prepare(
      "SELECT * FROM transactions WHERE user_id = ? ORDER BY created_at DESC LIMIT 50"
    ).bind(userId).all();
    return jsonResponse({
      success: true,
      transactions: results
    });
  } catch (e) {
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleGetTransactions, "handleGetTransactions");
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
async function ensureUserInD1(userId, env) {
  if (!userId) return null;
  return await env.DB.prepare("SELECT * FROM users WHERE id = ?").bind(userId).first();
}
__name(ensureUserInD1, "ensureUserInD1");
async function processLivePoints(env) {
  console.log("\u{1F504} Processing Live Points for all active matches...");
  try {
    const { results: liveMatches } = await env.DB.prepare(
      "SELECT id FROM matches WHERE status = 'Live' OR status = 'Upcoming'"
      // Also check Upcoming in case of early start
    ).all();
    if (!liveMatches || liveMatches.length === 0) {
      console.log("No live matches to sync points for.");
      return;
    }
    for (const match of liveMatches) {
      await syncMatchPointsToD1(match.id, env);
    }
  } catch (e) {
    console.error("processLivePoints Error:", e);
  }
}
__name(processLivePoints, "processLivePoints");
async function handleSaveTeam(request, env) {
  try {
    const body2 = await request.json();
    const { id, userId, matchId, teamName, players, captainId, viceCaptainId } = body2;
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
async function handleWithdrawRequest(request, env) {
  if (request.method !== "POST") return jsonResponse({ error: "Method Not Allowed" }, 405);
  try {
    const { userId, amount, method, details } = await request.json();
    if (!userId || !amount || !method) return jsonResponse({ success: false, error: "MISSING_FIELDS" }, 400);
    const user = await env.DB.prepare("SELECT winning_credits FROM users WHERE id = ?").bind(userId).first();
    if (!user || user.winning_credits < amount) {
      return jsonResponse({ success: false, error: "INSUFFICIENT_WINNINGS" }, 200);
    }
    const requestId = `payout_${Date.now()}_${userId}`;
    const statements = [
      env.DB.prepare("UPDATE users SET winning_credits = winning_credits - ? WHERE id = ? AND winning_credits >= ?").bind(amount, userId, amount),
      env.DB.prepare("INSERT INTO payout_requests (id, user_id, amount, method, details, status, created_at) VALUES (?, ?, ?, ?, ?, 'pending', ?)").bind(requestId, userId, amount, method, details || "", Date.now()),
      env.DB.prepare("INSERT INTO transactions (id, user_id, type, amount, created_at, status) VALUES (?, ?, 'withdrawal_request', ?, ?, 'pending')").bind(requestId, userId, amount, Date.now())
    ];
    const results = await env.DB.batch(statements);
    if (results[0].meta.changes === 0) throw new Error("INSUFFICIENT_BALANCE_RACE");
    return jsonResponse({ success: true, message: "Withdrawal requested" });
  } catch (e) {
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleWithdrawRequest, "handleWithdrawRequest");
async function handleAdminListWithdrawals(request, env) {
  try {
    const { results } = await env.DB.prepare("SELECT * FROM payout_requests WHERE status = 'pending' ORDER BY created_at ASC").all();
    return jsonResponse({ success: true, withdrawals: results });
  } catch (e) {
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleAdminListWithdrawals, "handleAdminListWithdrawals");
async function handleAdminUpdateWithdrawalStatus(request, env) {
  if (request.method !== "POST") return jsonResponse({ error: "Method Not Allowed" }, 405);
  try {
    const { requestId, status, note } = await request.json();
    if (!requestId || !status) return jsonResponse({ success: false, error: "MISSING_FIELDS" }, 400);
    const pr = await env.DB.prepare("SELECT * FROM payout_requests WHERE id = ?").bind(requestId).first();
    if (!pr) return jsonResponse({ success: false, error: "REQUEST_NOT_FOUND" }, 404);
    if (pr.status !== "pending") return jsonResponse({ success: false, error: "ALREADY_PROCESSED" }, 400);
    if (status === "approved") {
      const statements = [
        env.DB.prepare("UPDATE payout_requests SET status = 'approved', admin_note = ?, processed_at = ? WHERE id = ? AND status = 'pending'").bind(note || "Processed", Date.now(), requestId),
        env.DB.prepare("UPDATE transactions SET status = 'success' WHERE id = ?").bind(requestId)
      ];
      const results = await env.DB.batch(statements);
      if (results[0].meta.changes === 0) return jsonResponse({ success: false, error: "ALREADY_PROCESSED_OR_NOT_FOUND" }, 409);
    } else if (status === "rejected") {
      const statements = [
        env.DB.prepare("UPDATE users SET winning_credits = winning_credits + ? WHERE id = ?").bind(pr.amount, pr.user_id),
        env.DB.prepare("UPDATE payout_requests SET status = 'rejected', admin_note = ?, processed_at = ? WHERE id = ? AND status = 'pending'").bind(note || "Rejected by Admin", Date.now(), requestId),
        env.DB.prepare("UPDATE transactions SET status = 'rejected' WHERE id = ?").bind(requestId)
      ];
      const results = await env.DB.batch(statements);
      if (results[1].meta.changes === 0) {
        return jsonResponse({ success: false, error: "ALREADY_PROCESSED" }, 409);
      }
    }
    return jsonResponse({ success: true, message: `Status updated to ${status}` });
  } catch (e) {
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleAdminUpdateWithdrawalStatus, "handleAdminUpdateWithdrawalStatus");
async function handleAdminIssueReward(request, env) {
  if (request.method !== "POST") return jsonResponse({ error: "Method Not Allowed" }, 405);
  try {
    const { userId, amount, note } = await request.json();
    if (!userId || !amount) return jsonResponse({ success: false, error: "MISSING_FIELDS" }, 400);
    await env.DB.prepare("UPDATE users SET winning_credits = winning_credits + ? WHERE id = ?").bind(amount, userId).run();
    const txnId = `reward_${Date.now()}_${userId}`;
    await env.DB.prepare("INSERT INTO transactions (id, user_id, type, amount, created_at, status) VALUES (?, ?, 'reward', ?, ?, 'success')").bind(txnId, userId, amount, Date.now()).run();
    return jsonResponse({ success: true, message: "Reward issued" });
  } catch (e) {
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleAdminIssueReward, "handleAdminIssueReward");
async function handleAdminUserSearch(request, env) {
  const url = new URL(request.url);
  const email = url.searchParams.get("email");
  if (!email) return jsonResponse({ success: false, error: "Email required" }, 400);
  try {
    const user = await env.DB.prepare("SELECT id, name, email FROM users WHERE email = ?").bind(email).first();
    if (!user) return jsonResponse({ success: false, message: "User not found" });
    return jsonResponse({ success: true, user });
  } catch (e) {
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleAdminUserSearch, "handleAdminUserSearch");
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
async function handleAdminListUsers(request, env) {
  try {
    const { results } = await env.DB.prepare("SELECT id, name, email, deposit_credits, winning_credits, joined_at FROM users ORDER BY joined_at DESC LIMIT 200").all();
    return jsonResponse({ success: true, users: results });
  } catch (e) {
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleAdminListUsers, "handleAdminListUsers");
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
    const body2 = await request.json();
    const { matchId, creatorId, roomName, roomType, inviteCode, maxMembers } = body2;
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
    const body2 = await request.json();
    const { roomId, userId, inviteCode } = body2;
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
async function handleGetTransactionHistory(userId, env) {
  return handleGetTransactions(userId, env);
}
__name(handleGetTransactionHistory, "handleGetTransactionHistory");

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
