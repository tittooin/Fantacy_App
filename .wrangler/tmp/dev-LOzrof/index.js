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

// .wrangler/tmp/bundle-4f76us/checked-fetch.js
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
  ".wrangler/tmp/bundle-4f76us/checked-fetch.js"() {
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
  processSquads: () => processSquads,
  syncMatchSquad: () => syncMatchSquad
});
async function processSquads(env) {
  console.log("\u{1F465} Starting Squad Engine (API Limit Protected)...");
  const apiKey = env.RAPID_API_KEY;
  const apiHost = "livescore6.p.rapidapi.com";
  try {
    const now = Date.now();
    const tossWindow = 45 * 60 * 1e3;
    const { results: matches } = await env.DB.prepare(`
            SELECT m.id, m.series_id, m.status, m.start_time, s.last_updated 
            FROM matches m
            LEFT JOIN match_squads s ON m.id = s.match_id
            WHERE (
                (m.status = 'Upcoming' AND m.start_time BETWEEN ? AND ?)
                OR m.status = 'Live'
            )
        `).bind(now, now + tossWindow).all();
    if (!matches || matches.length === 0) {
      console.log("No matches in toss window or live.");
      return;
    }
    console.log(`Checking Playing XI for ${matches.length} matches...`);
    for (const match of matches) {
      const lastUpd = match.last_updated || 0;
      const diff = now - lastUpd;
      let shouldUpdate = false;
      if (match.status === "Live" && diff > 10 * 6e4) {
        shouldUpdate = true;
      } else if (match.status === "Upcoming" && diff > 15 * 6e4) {
        shouldUpdate = true;
      }
      if (shouldUpdate) {
        await syncMatchSquad(env, match, apiKey, apiHost);
      }
    }
  } catch (e) {
    console.error("Squad Engine Error:", e);
  }
}
async function syncMatchSquad(env, match, key, host) {
  const matchId = match.id;
  const seriesId = match.series_id || match.seriesId || "0";
  let finalSquads = { teamA: [], teamB: [], xiA: [], xiB: [] };
  let dataFound = false;
  try {
    console.log(`\u{1F4E1} Syncing Squad for Match ${matchId} (Series ${seriesId})`);
    const matchDetail = await env.DB.prepare("SELECT team_a, team_b, team_a_id, team_b_id FROM matches WHERE id = ?").bind(matchId).first();
    if (!matchDetail) {
      console.log("Match not found, skipping.");
      return null;
    }
    const teamAId = matchDetail.team_a_id;
    const teamBId = matchDetail.team_b_id;
    const teamAName = matchDetail.team_a || "Team A";
    const teamBName = matchDetail.team_b || "Team B";
    const apiHost = host;
    const matchSquadUrl = `https://${apiHost}/series/v1/${seriesId}/squads/${matchId}`;
    let resp = await fetch(matchSquadUrl, {
      headers: {
        "x-rapidapi-key": key,
        "x-rapidapi-host": apiHost,
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "application/json"
      }
    });
    if (resp.ok && resp.status !== 204) {
      const data = await resp.json();
      if (data.items && data.items.length > 0) {
        const teams = data.items;
        if (teams.length >= 2) {
          finalSquads.teamA = mapPlayers(teams[0]?.players, teamAId, teamAName);
          finalSquads.teamB = mapPlayers(teams[1]?.players, teamBId, teamBName);
          dataFound = true;
        }
      }
    }
    if (!dataFound && seriesId !== "0") {
      console.log(`\u26A0\uFE0F Match Squad empty/204. Trying Series Squads Fallback...`);
      const seriesSquadsUrl = `https://${apiHost}/series/v1/${seriesId}/squads`;
      resp = await fetch(seriesSquadsUrl, {
        headers: { "x-rapidapi-key": key, "x-rapidapi-host": apiHost, "User-Agent": "Mozilla/5.0" }
      });
      if (resp.ok && resp.status !== 204) {
        const data = await resp.json();
        if (data.squads) {
          const squadA = findSquadId(data.squads, matchDetail.team_a, teamAId);
          const squadB = findSquadId(data.squads, matchDetail.team_b, teamBId);
          if (squadA) finalSquads.teamA = await fetchSquadPlayers(squadA, seriesId, key, apiHost, teamAId, teamAName);
          if (squadB) finalSquads.teamB = await fetchSquadPlayers(squadB, seriesId, key, apiHost, teamBId, teamBName);
          if (finalSquads.teamA.length > 0 || finalSquads.teamB.length > 0) {
            dataFound = true;
          }
        }
      }
    }
    const currentData = await env.DB.prepare("SELECT team_a_roster FROM match_squads WHERE match_id = ?").bind(matchId).first();
    const hasExistingData = currentData && currentData.team_a_roster && currentData.team_a_roster !== "[]";
    if (!dataFound) {
      console.log(`\u26A0\uFE0F No data found (API 204/Empty).`);
      if (hasExistingData) {
        console.log("Preserving existing manual data, updating timestamp only.");
        await env.DB.prepare("UPDATE match_squads SET last_updated = ? WHERE match_id = ?").bind(Date.now(), matchId).run();
        return null;
      } else {
        console.log("Saving empty state to prevent loop.");
      }
    } else {
      console.log(`\u2705 Squad Data Found! Saving...`);
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
      JSON.stringify(finalSquads.teamA),
      JSON.stringify(finalSquads.teamB),
      JSON.stringify(finalSquads.xiA),
      JSON.stringify(finalSquads.xiB),
      Date.now()
    ).run();
    return finalSquads;
  } catch (e) {
    console.error(`Failed squad sync for ${matchId}:`, e);
    return null;
  }
}
function findSquadId(squadsList, teamName, teamId) {
  if (!squadsList || !teamName) return null;
  const nameLower = teamName.toLowerCase();
  const found = squadsList.find((s) => {
    const sName = (s.squadType || s.teamName || "").toLowerCase();
    return sName.includes(nameLower) || nameLower.includes(sName);
  });
  return found ? found.squadId : null;
}
async function fetchSquadPlayers(squadId, seriesId, key, host, teamId, teamShortName) {
  const u = `https://${host}/series/v1/${seriesId}/squads/${squadId}`;
  try {
    const r = await fetch(u, { headers: { "x-rapidapi-key": key, "x-rapidapi-host": host, "User-Agent": "Mozilla/5.0" } });
    if (r.ok) {
      const d = await r.json();
      if (d.player) return mapPlayers(d.player, teamId, teamShortName);
    }
  } catch (e) {
  }
  return [];
}
function mapPlayers(players, teamId, teamShortName) {
  if (!players || !Array.isArray(players)) return [];
  return players.filter((p) => !p.isHeader).map((p) => ({
    id: (p.id || "").toString(),
    name: p.name || "Unknown",
    role: mapRole(p.role),
    imageUrl: p.imageId ? `https://static.cricbuzz.com/a/img/v1/i1/c${p.imageId}/i.jpg` : "",
    // Changed from 'image' to 'imageUrl'
    isCaptain: p.captain || false,
    isWicketKeeper: (p.role || "").toLowerCase().includes("wk") || (p.role || "").toLowerCase().includes("keeper"),
    teamId: teamId ? teamId.toString() : "0",
    // Inject Team ID
    teamShortName: teamShortName || ""
    // Inject Team Short Name for UI badges
  }));
}
function mapRole(role) {
  if (!role) return "Batsman";
  const r = role.toLowerCase();
  if (r.includes("keeper") || r.includes("wk")) return "Wicket Keeper";
  if (r.includes("bowl")) return "Bowler";
  if (r.includes("all") || r.includes("rounder")) return "All Rounder";
  return "Batsman";
}
var init_squad_engine = __esm({
  "workers/squad_engine.js"() {
    init_checked_fetch();
    init_modules_watch_stub();
    __name(processSquads, "processSquads");
    __name(syncMatchSquad, "syncMatchSquad");
    __name(findSquadId, "findSquadId");
    __name(fetchSquadPlayers, "fetchSquadPlayers");
    __name(mapPlayers, "mapPlayers");
    __name(mapRole, "mapRole");
  }
});

// .wrangler/tmp/bundle-4f76us/middleware-loader.entry.ts
init_checked_fetch();
init_modules_watch_stub();

// .wrangler/tmp/bundle-4f76us/middleware-insertion-facade.js
init_checked_fetch();
init_modules_watch_stub();

// workers/index.js
init_checked_fetch();
init_modules_watch_stub();

// workers/cricket_engine.js
init_checked_fetch();
init_modules_watch_stub();

// workers/points_engine.js
init_checked_fetch();
init_modules_watch_stub();
var POINTS_CONFIG = {
  "T20": {
    run: 1,
    boundary: 1,
    six: 2,
    half_century: 8,
    century: 16,
    duck: -2,
    wicket: 25,
    lbw_bowled: 8,
    three_wickets: 4,
    four_wickets: 8,
    five_wickets: 16,
    maiden: 12,
    catch: 8,
    stump: 12,
    runout: 6
  },
  "ODI": {
    // Placeholder for ODI rules
    run: 1,
    boundary: 1,
    six: 2,
    half_century: 4,
    // ODI usually has lower bonus
    century: 8,
    duck: -3,
    wicket: 25,
    lbw_bowled: 8,
    four_wickets: 4,
    five_wickets: 8,
    maiden: 4,
    catch: 8,
    stump: 12,
    runout: 6
  },
  "TEST": {
    // Placeholder for TEST rules
    run: 1,
    boundary: 1,
    six: 2,
    half_century: 4,
    century: 8,
    duck: -4,
    wicket: 16,
    lbw_bowled: 8,
    four_wickets: 4,
    five_wickets: 8,
    maiden: 0,
    // No points for maiden in test usually
    catch: 8,
    stump: 12,
    runout: 6
  }
};
function calculateFantasyPoints(stats, format = "T20") {
  let points = 0;
  let breakdown = {};
  const rules = POINTS_CONFIG[format] || POINTS_CONFIG["T20"];
  if (stats.runs > 0) {
    const runPoints = stats.runs * rules.run;
    points += runPoints;
    breakdown.runs = runPoints;
  }
  if (stats.fours > 0) {
    const fourBonus = stats.fours * rules.boundary;
    points += fourBonus;
    breakdown.fours = fourBonus;
  }
  if (stats.sixes > 0) {
    const sixBonus = stats.sixes * rules.six;
    points += sixBonus;
    breakdown.sixes = sixBonus;
  }
  if (stats.runs >= 100) {
    points += rules.century;
    breakdown.century = rules.century;
  } else if (stats.runs >= 50) {
    points += rules.half_century;
    breakdown.half_century = rules.half_century;
  }
  if (stats.isOut && stats.runs === 0 && (stats.role === "Batsman" || stats.role === "Allrounder")) {
    points += rules.duck;
    breakdown.duck = rules.duck;
  }
  if (stats.wickets > 0) {
    const wicketPoints = stats.wickets * rules.wicket;
    points += wicketPoints;
    breakdown.wickets = wicketPoints;
  }
  if (stats.lbwOrBowled > 0) {
    const bonus = stats.lbwOrBowled * rules.lbw_bowled;
    points += bonus;
    breakdown.lbw_bowled = bonus;
  }
  if (stats.wickets >= 5) {
    points += rules.five_wickets;
    breakdown.five_wickets = rules.five_wickets;
  } else if (stats.wickets >= 4) {
    points += rules.four_wickets;
    breakdown.four_wickets = rules.four_wickets;
  } else if (stats.wickets >= 3) {
    points += rules.three_wickets;
    breakdown.three_wickets = rules.three_wickets;
  }
  if (stats.maidens > 0) {
    const maidenPoints = stats.maidens * rules.maiden;
    points += maidenPoints;
    breakdown.maidens = maidenPoints;
  }
  if (stats.catches > 0) {
    const catchPoints = stats.catches * rules.catch;
    points += catchPoints;
    breakdown.catches = catchPoints;
  }
  if (stats.stumpings > 0) {
    const stumpingPoints = stats.stumpings * rules.stump;
    points += stumpingPoints;
    breakdown.stumpings = stumpingPoints;
  }
  if (stats.runOuts > 0) {
    const runOutPoints = stats.runOuts * rules.runout;
    points += runOutPoints;
    breakdown.run_outs = runOutPoints;
  }
  return {
    points,
    breakdown,
    format_used: format
  };
}
__name(calculateFantasyPoints, "calculateFantasyPoints");
async function syncMatchPointsToD1(matchId, env) {
  console.log(`\u{1F4CA} Syncing Points for Match ${matchId}...`);
  const apiKey = env.RAPID_API_KEY;
  const apiHost = "cricbuzz-cricket.p.rapidapi.com";
  try {
    const resp = await fetch(`https://${apiHost}/mcenter/v1/${matchId}/scard`, {
      headers: { "x-rapidapi-key": apiKey, "x-rapidapi-host": apiHost }
    });
    if (!resp.ok) throw new Error(`API Error: ${resp.status}`);
    const data = await resp.json();
    const playerStats = extractPlayerStatsFromScorecard(data);
    console.log(`Found stats for ${playerStats.length} players in scorecard.`);
    const queries = [];
    for (const stats of playerStats) {
      const fantasy = calculateFantasyPoints(stats, "T20");
      queries.push(
        env.DB.prepare(`
                    INSERT INTO fantasy_points (match_id, player_id, points, breakdown)
                    VALUES (?, ?, ?, ?)
                    ON CONFLICT(match_id, player_id) DO UPDATE SET
                        points = excluded.points,
                        breakdown = excluded.breakdown
                `).bind(matchId, stats.playerId, fantasy.points, JSON.stringify(fantasy.breakdown))
      );
    }
    if (queries.length > 0) {
      await env.DB.batch(queries);
      console.log(`\u2705 Updated points for ${queries.length} players in D1.`);
    }
    return playerStats.length;
  } catch (e) {
    console.error(`Points Sync Failed for ${matchId}:`, e);
    return 0;
  }
}
__name(syncMatchPointsToD1, "syncMatchPointsToD1");
function extractPlayerStatsFromScorecard(data) {
  const stats = [];
  if (!data || !data.scorecard) return stats;
  data.scorecard.forEach((inning) => {
    if (inning.batTeamDetails && inning.batTeamDetails.batsmenData) {
      Object.values(inning.batTeamDetails.batsmenData).forEach((b) => {
        stats.push({
          playerId: b.batId,
          name: b.outDesc || "Batsman",
          runs: parseInt(b.runs || 0),
          fours: parseInt(b.fours || 0),
          sixes: parseInt(b.sixes || 0),
          isOut: b.outDesc && b.outDesc !== "not out",
          role: "Batsman"
          // Heuristic
        });
      });
    }
    if (inning.bowlTeamDetails && inning.bowlTeamDetails.bowlersData) {
      Object.values(inning.bowlTeamDetails.bowlersData).forEach((b) => {
        const existing = stats.find((s) => s.playerId === b.bowlerId);
        const bowlStats = {
          playerId: b.bowlerId,
          wickets: parseInt(b.wickets || 0),
          maidens: parseInt(b.maidens || 0),
          overs: parseFloat(b.overs || 0),
          lbwOrBowled: 0
          // Cricbuzz doesn't directly provide LBW/Bowled count in scard summary usually, needs detailed parsing or generic bonus
        };
        if (existing) {
          Object.assign(existing, bowlStats);
        } else {
          stats.push({ ...bowlStats, name: "Bowler", role: "Bowler", runs: 0, fours: 0, sixes: 0, isOut: false });
        }
      });
    }
  });
  return stats;
}
__name(extractPlayerStatsFromScorecard, "extractPlayerStatsFromScorecard");

// workers/cricket_engine.js
async function processCricketData(env) {
  console.log("\u{1F3CF} Cricket Engine Started (Cricbuzz)...");
  const apiKey = env.RAPID_API_KEY;
  const apiHost = "cricbuzz-cricket.p.rapidapi.com";
  try {
    const matches = await fetchMatchesFromAPI(apiKey, apiHost, env);
    console.log(`\u{1F4E1} Fetched ${matches.length} matches from API`);
    for (const match of matches) {
      await syncMatchToD1(match, env);
    }
    const cached = await env.DB.prepare("SELECT * FROM matches ORDER BY start_time ASC").all();
    const mappedResults = cached.results.map((m) => ({
      ...m,
      // Map D1 snake_case to Frontend expected keys
      team1Name: m.team_a,
      team2Name: m.team_b,
      teamA: m.team_a,
      teamB: m.team_b,
      matchDesc: m.title,
      seriesName: m.series_name || m.title,
      // Use DB Series Name, Fallback to Title
      team1ShortName: m.short_title ? m.short_title.split(" vs ")[0] : m.team_a ? m.team_a.substring(0, 3).toUpperCase() : "T1",
      team2ShortName: m.short_title ? m.short_title.split(" vs ")[1] : m.team_b ? m.team_b.substring(0, 3).toUpperCase() : "T2",
      team1Id: m.team_a_id,
      team2Id: m.team_b_id,
      startDate: m.start_time,
      status: m.status
    }));
    console.log(`\u2705 Returns ${mappedResults.length} matches from D1 (Mapped)`);
    return mappedResults;
  } catch (e) {
    console.error("\u274C Cricket Engine Error:", e);
    try {
      const cached = await env.DB.prepare("SELECT * FROM matches ORDER BY start_time ASC").all();
      return cached.results.map((m) => ({
        ...m,
        team1Name: m.team_a,
        team2Name: m.team_b,
        teamA: m.team_a,
        teamB: m.team_b,
        matchDesc: m.title,
        startDate: m.start_time
      }));
    } catch (ex) {
      return [];
    }
  }
}
__name(processCricketData, "processCricketData");
async function syncMatchToD1(match, env) {
  try {
    const existing = await env.DB.prepare("SELECT last_updated, status, team_a_id FROM matches WHERE id = ?").bind(match.id).first();
    if (existing) {
      const existingStatus = existing.status;
      await env.DB.prepare(`
                UPDATE matches SET 
                title = ?,
                short_title = ?,
                series_id = ?,
                series_name = ?,
                start_time = ?,
                status = ?,
                team_a_img = ?,
                team_b_img = ?,
                team_a_id = ?,
                team_b_id = ?,
                last_updated = ?
                WHERE id = ?
            `).bind(
        match.title,
        match.shortTitle,
        match.seriesId,
        match.seriesName || "",
        match.startTime,
        match.status,
        match.teamAImg,
        match.teamBImg,
        match.team1Id,
        match.team2Id,
        Date.now(),
        match.id
      ).run();
    } else {
      await env.DB.prepare(`
            INSERT INTO matches (id, series_id, series_name, title, short_title, status, start_time, team_a, team_b, team_a_img, team_b_img, team_a_id, team_b_id, last_updated)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
        Date.now()
      ).run();
      if (match.status === "Upcoming" || match.status === "Live") {
        const squadCheck = await env.DB.prepare(`SELECT match_id FROM match_squads WHERE match_id = ?`).bind(match.id).first();
        if (!squadCheck) {
          console.log(`\u{1F195} New match detected: ${match.id}, queuing squad check...`);
          const { syncMatchSquad: syncMatchSquad2 } = await Promise.resolve().then(() => (init_squad_engine(), squad_engine_exports));
          await syncMatchSquad2(env, { id: match.id, series_id: match.seriesId, status: match.status }, env.RAPID_API_KEY, env.RAPID_API_HOST);
        }
      }
    }
  } catch (e) {
    console.error(`Error syncing match ${match.id}:`, e);
  }
}
__name(syncMatchToD1, "syncMatchToD1");
async function fetchMatchesFromAPI(key, host, env) {
  let parsed = [];
  const endpoints = [
    { path: "/matches/v1/live", key: "fetch_live", ttl: 3e5 },
    // 5 Mins
    { path: "/matches/v1/upcoming", key: "fetch_upcoming", ttl: 9e5 },
    // 15 Mins
    { path: "/matches/v1/recent", key: "fetch_recent", ttl: 18e5 }
    // 30 Mins
  ];
  for (const ep of endpoints) {
    try {
      const dbKey = `last_${ep.key}`;
      const lastFetch = await env.DB.prepare("SELECT value FROM sys_config WHERE key = ?").bind(dbKey).first();
      if (lastFetch && Date.now() - parseInt(lastFetch.value) < ep.ttl) {
        console.log(`\u23F3 Skipping ${ep.path} (Limit < ${ep.ttl / 6e4}m)`);
        continue;
      }
      const url = `https://${host}${ep.path}`;
      console.log(`\u{1F4E1} Fetching: ${url}`);
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
        console.log(`\u2705 ${ep.path}: Found ${matches.length} matches`);
        parsed = [...parsed, ...matches];
        await env.DB.prepare("INSERT OR REPLACE INTO sys_config (key, value, updated_at) VALUES (?, ?, ?)").bind(dbKey, Date.now().toString(), Date.now()).run();
      } else {
        console.error(`\u26A0\uFE0F API Error ${ep.path}: ${resp.status}`);
      }
    } catch (e) {
      console.error(`Fetch Failed ${ep.path}:`, e);
    }
  }
  if (parsed.length === 0) return [];
  const unique = /* @__PURE__ */ new Map();
  parsed.forEach((m) => {
    if (m.id) unique.set(m.id, m);
  });
  return Array.from(unique.values());
}
__name(fetchMatchesFromAPI, "fetchMatchesFromAPI");
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
  const state = info.state || "";
  if (state === "Complete" || state === "Mom" || state.includes("Won")) status = "Completed";
  else if (state === "In Progress" || state === "Live" || state === "Toss" || state === "Stumps" || state === "Innings Break") status = "Live";
  else if (state === "Preview" || state === "Upcoming") status = "Upcoming";
  else if (state === "Abandoned" || state === "No Result") status = "Abandoned";
  const t1 = info.team1 || {};
  const t2 = info.team2 || {};
  return {
    id: info.matchId.toString(),
    seriesId: (info.seriesId || "0").toString(),
    seriesName: info.seriesName || "Unknown Series",
    title: `${t1.teamName || "T1"} vs ${t2.teamName || "T2"}`,
    shortTitle: `${t1.teamSName || "T1"} vs ${t2.teamSName || "T2"}`,
    status,
    matchFormat: info.matchFormat ? info.matchFormat.toUpperCase() : "T20",
    // COMPATIBILITY FIELDS (For Frontend)
    team1Name: t1.teamName || "Team A",
    team2Name: t2.teamName || "Team B",
    team1ShortName: t1.teamSName || "T1",
    team2ShortName: t2.teamSName || "T2",
    matchDesc: `${t1.teamName} vs ${t2.teamName}`,
    startDate: parseInt(info.startDate) || Date.now(),
    endDate: parseInt(info.endDate) || parseInt(info.startDate) + 144e5,
    // Fallback +4h
    venue: info.venueInfo ? info.venueInfo.ground : "TBD",
    startTime: parseInt(info.startDate) || Date.now(),
    // Ensure MS
    teamA: t1.teamName || "Team A",
    teamB: t2.teamName || "Team B",
    teamAImg: t1.imageId ? `https://static.cricbuzz.com/a/img/v1/i1/c${t1.imageId}/i.jpg` : "",
    teamBImg: t2.imageId ? `https://static.cricbuzz.com/a/img/v1/i1/c${t2.imageId}/i.jpg` : "",
    team1Id: (t1.teamId || "0").toString(),
    team2Id: (t2.teamId || "0").toString(),
    lastUpdated: Date.now()
  };
}
__name(formatCricbuzzMatch, "formatCricbuzzMatch");

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
async function verifySignature(ts, body, signature, secret) {
  if (!ts || !signature || !secret) throw new Error("Missing verification headers/config");
  const now = Math.floor(Date.now() / 1e3);
  const webhookTimeMs = parseInt(ts, 10);
  const webhookTimeSeconds = Math.floor(webhookTimeMs / 1e3);
  if (Math.abs(now - webhookTimeSeconds) > 300) {
    console.error(`Timestamp Expired: Now ${now}, Hook ${webhookTimeSeconds}`);
    throw new Error("Webhook Timestamp expired");
  }
  const data = ts + body;
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
    "SELECT player_id, total_points FROM fantasy_points WHERE match_id = ?"
  ).bind(matchId).all();
  const pointsMap = {};
  pointRows.forEach((r) => pointsMap[r.player_id] = r.total_points || 0);
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
    const body = await request.json();
    const { userId, brand, credits } = body;
    if (!userId || !brand || !credits) return jsonResponse({ error: "Missing fields" }, 400);
    const user = await env.DB.prepare("SELECT winning_credits FROM users WHERE id = ?").bind(userId).first();
    const currentWinnings = user ? user.winning_credits || 0 : 0;
    if (currentWinnings < credits) {
      return jsonResponse({ error: "Insufficient Winning Credits" }, 402);
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
    const body = await request.json();
    const { requestId, code, action } = body;
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

// workers/index.js
var corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "*"
};
var workers_default = {
  async scheduled(event, env, ctx) {
    console.log("\u23F0 Scheduled Event Triggered");
    ctx.waitUntil(processCricketData(env));
    ctx.waitUntil(processLivePoints(env));
    ctx.waitUntil(processLeaderboards(env));
    ctx.waitUntil(processEconomy(env));
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
    const url = new URL(request.url);
    const path = url.pathname.replace(/\/$/, "");
    if (url.pathname === "/api/contests") return await handleGetContests(request, env);
    if (url.pathname === "/api/contests/join") return await handleJoinContest(request, env);
    if (url.pathname === "/api/contests/joined") {
      const uid = url.searchParams.get("userId");
      if (!uid) return jsonResponse({ error: "userId required" }, 400);
      return await handleGetUserContests(uid.trim(), env);
    }
    if (url.pathname === "/api/leaderboard") return await handleGetLeaderboard(request, env);
    if (url.pathname === "/api/teams/save") return await handleSaveTeam(request, env);
    if (url.pathname === "/api/teams/get") return await handleGetTeams(url.searchParams, env);
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
    if (path === "/") return handleStaticPage("home");
    if (path === "/terms" || path === "/terms-and-conditions") return handleStaticPage("terms");
    if (path === "/refund" || path === "/refund-policy" || path === "/cancellation") return handleStaticPage("refund");
    if (path === "/privacy" || path === "/privacy-policy") return handleStaticPage("privacy");
    if (path === "/contact" || path === "/contact-us") return handleStaticPage("contact");
    if (path === "/matches" || path === "/api/get-matches" || path === "/api/matches") return handleGetMatches(env);
    if (path === "/matches/refresh" || path === "/api/refresh-matches") {
      const matches = await processCricketData(env);
      return jsonResponse({ success: true, message: "Triggered D1 Update", matches });
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
    if (path === "/api/leaderboard") {
      const contestId = url.searchParams.get("contestId");
      if (!contestId) return jsonResponse({ success: false, error: "contestId required" }, 400);
      return handleGetLeaderboard(contestId, env);
    }
    if (path === "/api/calc-leaderboard") {
      await processLeaderboards(env);
      return jsonResponse({ success: true, message: "Leaderboard Calc Triggered" });
    }
    if (path === "/api/admin/stats") {
      return handleAdminStats(env);
    }
    if (path === "/api/admin/payouts/distribute") {
      if (request.method !== "POST") return jsonResponse({ error: "Method Not Allowed" }, 405);
      const body = await request.json();
      if (!body.matchId) return jsonResponse({ error: "Match ID required" }, 400);
      await processPayoutsForMatch(env, body.matchId);
      return jsonResponse({ success: true, message: `Payout Process Initiated for ${body.matchId}` });
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
    if (path === "/api/admin/contests/create") return handleAdminCreateContest(request, env);
    if (path === "/api/contests" || path === "/api/contests/list") {
      const matchId = url.searchParams.get("matchId");
      if (!matchId) return jsonResponse({ success: false, error: "matchId required" }, 400);
      return handleGetContests(matchId, env);
    }
    if (path === "/api/contest") {
      const contestId = url.searchParams.get("contestId");
      if (!contestId) return jsonResponse({ success: false, error: "contestId required" }, 400);
      return handleGetContestById(contestId, env);
    }
    if (path === "/api/user/contests") {
      const userId = url.searchParams.get("userId");
      if (!userId) return jsonResponse({ success: false, error: "userId required" }, 400);
      return handleGetUserContests(userId, env);
    }
    if (path === "/diag") return handleGlobalDiag(env);
    if (path === "/fantasy-points") return handleGetFantasyPoints(url.searchParams.get("match_id"), env);
    if (path === "/debug-api" || path === "/api/debug-api") return handleDebugApi(env);
    if (path.startsWith("/api/")) {
      return jsonResponse({ success: false, error: `API Route Not Found: ${path}` }, 404);
    }
    console.log(`\u26A0\uFE0F Unhandled route: ${path} [${request.method}]`);
    return new Response("Fantasy Cricket Worker (D1-Core) - Access Denied", { status: 403, headers: corsHeaders });
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
    const body = await request.json();
    const { userId, amount } = body;
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
async function handleJoinContest(request, env) {
  try {
    const body = await request.json();
    const { userId, contestId, matchId, teamName, playerIds, teamId } = body;
    if (!userId || !contestId || !matchId || !teamId) {
      return jsonResponse({ success: false, error: "MISSING_FIELDS" }, 200);
    }
    const [user, contest, userCount] = await Promise.all([
      env.DB.prepare("SELECT deposit_credits, winning_credits FROM users WHERE id = ?").bind(userId).first(),
      env.DB.prepare("SELECT status, entry_fee, filled_spots, total_spots FROM contests WHERE id = ?").bind(contestId).first(),
      env.DB.prepare("SELECT COUNT(*) as count FROM contest_participants WHERE contest_id = ? AND user_id = ?").bind(contestId, userId).first()
    ]);
    if (!contest) return jsonResponse({ success: false, error: "CONTEST_NOT_FOUND" }, 200);
    if (contest.status?.toLowerCase() !== "upcoming") {
      return jsonResponse({ success: false, error: "CONTEST_ALREADY_STARTED" }, 200);
    }
    if (contest.filled_spots >= contest.total_spots) {
      return jsonResponse({ success: false, error: "CONTEST_FULL" }, 200);
    }
    if (userCount && userCount.count >= 20) {
      return jsonResponse({ success: false, error: "LIMIT_EXCEEDED_20_TEAMS" }, 200);
    }
    if (!user) return jsonResponse({ success: false, error: "USER_NOT_FOUND" }, 200);
    const deposit = user.deposit_credits || 0;
    const winnings = user.winning_credits || 0;
    const totalBalance = deposit + winnings;
    const entryFee = contest.entry_fee || 0;
    if (totalBalance < entryFee) {
      return jsonResponse({
        success: false,
        error: "INSUFFICIENT_BALANCE",
        required: entryFee,
        available: totalBalance
      }, 200);
    }
    let deductDeposit = entryFee;
    let deductWinnings = 0;
    if (deposit < entryFee) {
      deductDeposit = deposit;
      deductWinnings = entryFee - deductDeposit;
    }
    const txnId = `join_${Date.now()}_${userId}`;
    const participationId = crypto.randomUUID();
    const statements = [
      // A. Deduct Wallet (Atomic guard in WHERE)
      env.DB.prepare(`
                UPDATE users 
                SET deposit_credits = deposit_credits - ?, 
                    winning_credits = winning_credits - ? 
                WHERE id = ? AND (deposit_credits + winning_credits) >= ?
            `).bind(deductDeposit, deductWinnings, userId, entryFee),
      // B. Increment spots (Atomic guard to prevent overfill)
      env.DB.prepare(`
                UPDATE contests 
                SET filled_spots = filled_spots + 1 
                WHERE id = ? AND filled_spots < total_spots
            `).bind(contestId),
      // C. Insert Join Record
      env.DB.prepare(`
                INSERT INTO contest_participants (id, contest_id, user_id, team_id, match_id, player_ids, team_name, joined_at) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            `).bind(
        participationId,
        contestId,
        userId,
        teamId,
        matchId,
        JSON.stringify(playerIds || []),
        teamName || "User Team",
        Date.now()
      ),
      // D. Log Transaction
      env.DB.prepare(`
                INSERT INTO transactions (id, user_id, type, amount, contest_id, match_id, created_at, status)
                VALUES (?, ?, 'contest_join', ?, ?, ?, ?, 'success')
            `).bind(txnId, userId, entryFee, contestId, matchId, Date.now())
    ];
    try {
      const results = await env.DB.batch(statements);
      if (results[0].meta.changes === 0) throw new Error("BALANCE_CONCURRENCY_ERROR");
      if (results[1].meta.changes === 0) throw new Error("CONTEST_FULL_RACE_ERROR");
      return jsonResponse({
        success: true,
        message: "Contest Joined Successfully",
        remainingBalance: totalBalance - entryFee
      }, 200);
    } catch (txnError) {
      console.error("Atomic Join Failed:", txnError);
      return jsonResponse({
        success: false,
        error: txnError.message || "JOIN_TRANSACTION_FAILED"
      }, 200);
    }
  } catch (e) {
    console.error("Join Contest Global Error", e);
    return jsonResponse({ success: false, error: "SERVER_ERROR" }, 200);
  }
}
__name(handleJoinContest, "handleJoinContest");
async function handleAdminCreateContest(request, env) {
  if (request.method !== "POST") return jsonResponse({ error: "Method Not Allowed" }, 405);
  try {
    const body = await request.json();
    const { id, matchId, entryFee, totalSpots, prizePool, category, isGuaranteed, isFlexible, winningBreakdown } = body;
    if (!id || !matchId) return jsonResponse({ success: false, error: "id and matchId required" }, 400);
    await env.DB.prepare(`
            INSERT OR REPLACE INTO contests (
                id, match_id, entry_fee, total_spots, filled_spots, prize_pool, 
                category, is_guaranteed, is_flexible, winning_breakdown, status, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
      id,
      matchId.toString(),
      entryFee,
      totalSpots,
      0,
      // filled_spots starts at 0
      prizePool,
      category,
      isGuaranteed ? 1 : 0,
      isFlexible ? 1 : 0,
      JSON.stringify(winningBreakdown || []),
      "Upcoming",
      Date.now()
    ).run();
    console.log(`\u2705 D1 Contest Created: ${id} for Match ${matchId}`);
    return jsonResponse({ success: true, message: "Contest Created in D1" });
  } catch (e) {
    console.error("D1 Create Contest Error:", e);
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleAdminCreateContest, "handleAdminCreateContest");
async function handleGetContestById(contestId, env) {
  try {
    const contest = await env.DB.prepare(
      "SELECT * FROM contests WHERE id = ?"
    ).bind(contestId).first();
    if (!contest) return jsonResponse({ success: false, error: "Contest not found" }, 404);
    const formatted = {
      ...contest,
      matchId: contest.match_id,
      entryFee: contest.entry_fee,
      totalSpots: contest.total_spots,
      filledSpots: contest.filled_spots,
      prizePool: contest.prize_pool,
      isGuaranteed: !!contest.is_guaranteed,
      isFlexible: !!contest.is_flexible,
      winningBreakdown: JSON.parse(contest.winning_breakdown || "[]")
    };
    return jsonResponse({ success: true, contest: formatted });
  } catch (e) {
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleGetContestById, "handleGetContestById");
async function handleGetContests(matchId, env) {
  try {
    console.log(`\u{1F50D} Fetching Contests for MatchID: ${matchId}`);
    const { results } = await env.DB.prepare(
      "SELECT * FROM contests WHERE match_id = ? AND status IN ('Upcoming', 'Live') ORDER BY created_at DESC"
    ).bind(matchId.toString()).all();
    console.log(`\u2705 Found ${results ? results.length : 0} contests for ${matchId} from D1`);
    if (!results) return jsonResponse({ success: true, contests: [] });
    const contests = results.map((c) => ({
      ...c,
      matchId: c.match_id,
      entryFee: c.entry_fee,
      totalSpots: c.total_spots,
      filledSpots: c.filled_spots,
      prizePool: c.prize_pool,
      isGuaranteed: !!c.is_guaranteed,
      isFlexible: !!c.is_flexible,
      winningBreakdown: JSON.parse(c.winning_breakdown || "[]")
    }));
    return jsonResponse({ success: true, contests });
  } catch (e) {
    console.error("Fetch API Error:", e);
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleGetContests, "handleGetContests");
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
async function handleGetLeaderboard(contestId, env) {
  try {
    const row = await env.DB.prepare(
      "SELECT data FROM contest_leaderboards WHERE contest_id = ?"
    ).bind(contestId).first();
    if (row && row.data) {
      return jsonResponse({ success: true, leaderboard: JSON.parse(row.data) });
    }
    return jsonResponse({ success: true, leaderboard: [] });
  } catch (e) {
    return jsonResponse({ success: false, error: e.message });
  }
}
__name(handleGetLeaderboard, "handleGetLeaderboard");
async function handleGetMatches(env) {
  try {
    const { results } = await env.DB.prepare("SELECT * FROM matches ORDER BY start_time ASC").all();
    return jsonResponse({ success: true, matches: results });
  } catch (error) {
    return jsonResponse({ success: false, error: error.message });
  }
}
__name(handleGetMatches, "handleGetMatches");
async function handleGetScorecard(matchId, env) {
  try {
    const score = await env.DB.prepare("SELECT * FROM live_scores WHERE match_id = ?").bind(matchId).first();
    const now = Date.now();
    const cacheTime = 120 * 1e3;
    if (score && now - (score.updated_at || 0) < cacheTime) {
      return jsonResponse({ success: true, scorecard: score, source: "D1_CACHE" });
    }
    console.log(`\u{1F504} Fetching fresh scorecard for ${matchId}...`);
    const apiKey = env.RAPID_API_KEY;
    const apiHost = "cricbuzz-cricket.p.rapidapi.com";
    try {
      const resp = await fetch(`https://${apiHost}/mcenter/v1/${matchId}/scard`, {
        headers: {
          "x-rapidapi-key": apiKey,
          "x-rapidapi-host": apiHost
        }
      });
      if (!resp.ok) {
        if (score) return jsonResponse({ success: true, scorecard: score, source: "D1_STALE_API_FAIL" });
        throw new Error(`API Error ${resp.status}`);
      }
      const data = await resp.json();
      const details = processScorecardData(data);
      await env.DB.prepare(`
                INSERT INTO live_scores (match_id, status_note, team_a_score, team_b_score, current_over, score_details, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(match_id) DO UPDATE SET
                    status_note = excluded.status_note,
                    team_a_score = excluded.team_a_score,
                    team_b_score = excluded.team_b_score,
                    current_over = excluded.current_over,
                    score_details = excluded.score_details,
                    updated_at = excluded.updated_at
            `).bind(
        matchId,
        details.status,
        details.team1Score,
        details.team2Score,
        details.overs,
        JSON.stringify(details.fullData),
        now
      ).run();
      return jsonResponse({
        success: true,
        scorecard: {
          match_id: matchId,
          status_note: details.status,
          team_a_score: details.team1Score,
          team_b_score: details.team2Score,
          current_over: details.overs,
          score_details: JSON.stringify(details.fullData),
          // Return stringified as app expects
          updated_at: now
        },
        source: "API_FRESH"
      });
    } catch (apiError) {
      console.error("ScoreAPI Error:", apiError);
      if (score) return jsonResponse({ success: true, scorecard: score, source: "D1_STALE_ERROR" });
      return jsonResponse({ success: false, error: "Failed to fetch scorecard" });
    }
  } catch (error) {
    return jsonResponse({ success: false, error: error.message });
  }
}
__name(handleGetScorecard, "handleGetScorecard");
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
    status,
    team1Score: t1Score,
    team2Score: t2Score,
    overs,
    fullData
  };
}
__name(processScorecardData, "processScorecardData");
async function handleGetSquads(matchId, env, request) {
  try {
    if (!matchId) return jsonResponse({ success: false, error: "matchId required" });
    const d1Squad = await env.DB.prepare(
      "SELECT team_a_roster, team_b_roster, playing_11_a, playing_11_b, last_updated FROM match_squads WHERE match_id = ?"
    ).bind(matchId).first();
    const now = Date.now();
    const staleThreshold = 24 * 60 * 60 * 1e3;
    let matchInfo;
    try {
      matchInfo = await env.DB.prepare("SELECT team_a_id, team_b_id, series_id FROM matches WHERE id = ?").bind(matchId).first();
    } catch (e) {
      console.error("SQL Error fetching series_id, falling back to basic query:", e);
      matchInfo = await env.DB.prepare("SELECT team_a_id, team_b_id FROM matches WHERE id = ?").bind(matchId).first();
    }
    const team1Id = matchInfo?.team_a_id || 0;
    const team2Id = matchInfo?.team_b_id || 0;
    const seriesId = matchInfo?.series_id || 0;
    const force = new URL(request.url).searchParams.get("force") === "true";
    if (d1Squad && d1Squad.team_a_roster && !force) {
      const age = now - (d1Squad.last_updated || 0);
      const teamA = JSON.parse(d1Squad.team_a_roster || "[]");
      const teamB = JSON.parse(d1Squad.team_b_roster || "[]");
      if (age < staleThreshold && (teamA.length > 0 || teamB.length > 0)) {
        return jsonResponse({
          success: true,
          source: "D1_CACHE",
          teamA: teamA.map((p) => ({ ...p, teamId: (p.teamId || team1Id).toString() })),
          teamB: teamB.map((p) => ({ ...p, teamId: (p.teamId || team2Id).toString() })),
          xiA: JSON.parse(d1Squad.playing_11_a || "[]"),
          xiB: JSON.parse(d1Squad.playing_11_b || "[]"),
          matchId,
          team1Id,
          team2Id
        });
      } else {
        console.log(`\u26A0\uFE0F Cache Exists but is EMPTY or Stale. forcing refresh for ${matchId}`);
      }
    }
    console.log(`\u{1F504} Squad stale/missing for ${matchId} (Series ${seriesId}), fetching...`);
    const mockMatch = { id: matchId, status: "Upcoming", series_id: seriesId };
    await syncMatchSquad(env, mockMatch, env.RAPID_API_KEY, "cricbuzz-cricket.p.rapidapi.com");
    const d1Retry = await env.DB.prepare(
      "SELECT team_a_roster, team_b_roster, playing_11_a, playing_11_b FROM match_squads WHERE match_id = ?"
    ).bind(matchId).first();
    if (d1Retry && d1Retry.team_a_roster) {
      const teamAFresh = JSON.parse(d1Retry.team_a_roster || "[]");
      const teamBFresh = JSON.parse(d1Retry.team_b_roster || "[]");
      return jsonResponse({
        success: true,
        source: "D1_FRESH",
        teamA: teamAFresh.map((p) => ({ ...p, teamId: (p.teamId || team1Id).toString() })),
        teamB: teamBFresh.map((p) => ({ ...p, teamId: (p.teamId || team2Id).toString() })),
        xiA: JSON.parse(d1Retry.playing_11_a || "[]"),
        xiB: JSON.parse(d1Retry.playing_11_b || "[]"),
        team1Id,
        team2Id
      });
    }
    return jsonResponse({ success: false, error: "Squad unavailable" }, 200);
  } catch (e) {
    console.error("Squad Error:", e);
    return jsonResponse({ success: false, error: "Internal error: " + e.message }, 200);
  }
}
__name(handleGetSquads, "handleGetSquads");
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
async function handleGetFantasyPoints(matchId, env) {
  if (!matchId) return jsonResponse({ success: false, error: "Match ID required" }, 400);
  try {
    const points = await env.DB.prepare("SELECT * FROM fantasy_points WHERE match_id = ?").bind(matchId).all();
    const formatted = points.results.map((p) => ({
      ...p,
      breakdown: JSON.parse(p.breakdown || "{}")
    }));
    return jsonResponse({ success: true, points: formatted });
  } catch (e) {
    return jsonResponse({ success: false, error: e.message });
  }
}
__name(handleGetFantasyPoints, "handleGetFantasyPoints");
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
async function handleGetUserContests(userId, env) {
  try {
    const { results } = await env.DB.prepare(`
            SELECT cp.*, c.category, c.entry_fee, c.prize_pool, m.title as match_title
            FROM contest_participants cp
            JOIN contests c ON cp.contest_id = c.id
            LEFT JOIN matches m ON cp.match_id = m.id
            WHERE cp.user_id = ?
            ORDER BY cp.joined_at DESC
        `).bind(userId).all();
    return jsonResponse({ success: true, contests: results });
  } catch (e) {
    console.error("D1 Get User Contests Error:", e);
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleGetUserContests, "handleGetUserContests");
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
    const body = await request.json();
    const { id, userId, matchId, teamName, players, captainId, viceCaptainId } = body;
    if (!userId || !matchId || !players) {
      return jsonResponse({ success: false, error: "Missing required fields" }, 400);
    }
    const finalId = id && id.toString().trim().length > 0 ? id.toString().trim() : `team_${Date.now()}_${userId}`;
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
async function handleAdminListUsers(request, env) {
  try {
    const { results } = await env.DB.prepare("SELECT id, name, email, deposit_credits, winning_credits, joined_at FROM users ORDER BY joined_at DESC LIMIT 200").all();
    return jsonResponse({ success: true, users: results });
  } catch (e) {
    return jsonResponse({ success: false, error: e.message }, 500);
  }
}
__name(handleAdminListUsers, "handleAdminListUsers");

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

// .wrangler/tmp/bundle-4f76us/middleware-insertion-facade.js
var __INTERNAL_WRANGLER_MIDDLEWARE__ = [
  middleware_ensure_req_body_drained_default
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

// .wrangler/tmp/bundle-4f76us/middleware-loader.entry.ts
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
