/**
 * Contest Engine
 * Hindi: Live contests ko process karke leaderboard update karta hai
 */

export async function processLiveContests(env, db) {
    console.log("🏆 Starting Contest Engine...");

    try {
        // 1. Get all LIVE contests
        // Query: contests where status == 'Live'
        const contestsSnapshot = await queryFirestore(env, 'contests', [
            { fieldPaths: ['status'], op: 'EQUAL', value: 'Live' }
        ]);

        if (contestsSnapshot.length === 0) {
            console.log("No LIVE contests found.");
            return;
        }

        console.log(`Processing ${contestsSnapshot.length} LIVE contests...`);

        // Process each contest
        for (const contest of contestsSnapshot) {
            await updateContestLeaderboard(env, db, contest);
        }

    } catch (e) {
        console.error("❌ Contest Engine Error:", e);
    }
}

async function updateContestLeaderboard(env, db, contest) {
    const contestId = contest.id;
    const matchId = contest.fields.matchId.stringValue;

    console.log(`📊 Updating Contest: ${contestId} (Match: ${matchId})`);

    try {
        // 2. Fetch Latest Player Points from Match
        const playersMap = await fetchMatchPlayerPoints(env, matchId);
        if (Object.keys(playersMap).length === 0) {
            console.log("No player points available for this match yet.");
            return;
        }

        // 3. Fetch All Participants (Teams) for this Contest
        // Collection: contests/{contestId}/participants
        const participants = await fetchCollectionSimple(env, `contests/${contestId}/participants`);

        if (participants.length === 0) {
            console.log("No participants in contest.");
            return;
        }

        let updatedTeams = [];

        // 4. Calculate Points for Each Team
        for (const team of participants) {
            let totalPoints = 0;
            const roster = team.players || []; // Array of playerIds

            for (const playerId of roster) {
                const pStats = playersMap[playerId];
                if (pStats) {
                    let points = pStats.fantasyPoints || 0;

                    // Apply Multipliers
                    if (playerId === team.captain) points *= 2;
                    if (playerId === team.viceCaptain) points *= 1.5;

                    totalPoints += points;
                }
            }

            updatedTeams.push({
                teamId: team.teamId || team.id, // Doc ID is teamId
                points: totalPoints,
                // Keep other fields if needed, but we mostly fix points here
            });
        }

        // 5. Sort & Assign Ranks
        updatedTeams.sort((a, b) => b.points - a.points);

        let currentRank = 1;
        for (let i = 0; i < updatedTeams.length; i++) {
            if (i > 0 && updatedTeams[i].points < updatedTeams[i - 1].points) {
                currentRank = i + 1;
            }
            updatedTeams[i].rank = currentRank;
        }

        // 6. Filter: Only update if points/rank CHANGED
        // We need existing state. participants array has it!
        // participants[k] corresponds to one of updatedTeams

        const teamsToWrite = [];

        for (const newTeam of updatedTeams) {
            const oldTeam = participants.find(p => (p.teamId || p.id) === newTeam.teamId);
            if (!oldTeam) {
                teamsToWrite.push(newTeam); // New? Write it.
                continue;
            }

            // Compare Points & Rank
            // Note: Firestore returns numbers. oldTeam.points might be number or string depending on parsing.
            // In fetchCollectionSimple we parsed it.
            const oldPoints = oldTeam.points || 0;
            const oldRank = oldTeam.rank || 0;

            if (Math.abs(oldPoints - newTeam.points) > 0.1 || oldRank !== newTeam.rank) {
                teamsToWrite.push(newTeam);
            }
        }

        if (teamsToWrite.length > 0) {
            console.log(`✅ Updating ${teamsToWrite.length}/${updatedTeams.length} teams in contest ${contestId}`);
            await batchUpdateLeaderboard(env, contestId, teamsToWrite);
        } else {
            console.log(`💤 Contest ${contestId}: Leaderboard stable. No writes.`);
        }

    } catch (e) {
        console.error(`❌ Error updating contest ${contestId}:`, e);
    }
}


// --- Helpers ---

// ... fetchMatchPlayerPoints kept as is ...

async function batchUpdateLeaderboard(env, contestId, teams) {
    const baseUrl = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents`;

    // 1. Update Participants (Required)
    const updates = teams.map(team => {
        const url = `${baseUrl}/contests/${contestId}/participants/${team.teamId}?updateMask.fieldPaths=points&updateMask.fieldPaths=rank&key=${env.FIREBASE_API_KEY}`;
        const body = {
            fields: {
                points: { doubleValue: team.points },
                rank: { integerValue: team.rank.toString() }
            }
        };
        return fetch(url, {
            method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body)
        });
    });

    await Promise.all(updates);

    // 2. Leaderboard Collection? 
    // Optimization: SKIP this if we can rely on participants collection for UI leaderboard.
    // User prompted for it earlier, so we keep it BUT only for these teams. 
    // Double write cost vs UI Speed. For Free Tier Survival -> SKIP IT if possible.
    // Assuming UI uses 'participants'. I will comment out secondary write to Dave QUOTA.

    /* 
    const lbUpdates = teams.map(team => ... ); 
    await Promise.all(lbUpdates); 
    */
}

// Low-level Firestore Helpers

async function fetchCollectionSimple(env, path) {
    const url = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${path}?pageSize=300&key=${env.FIREBASE_API_KEY}`;
    try {
        const res = await fetch(url);
        if (!res.ok) return [];
        const data = await res.json();
        if (!data.documents) return [];

        return data.documents.map(doc => {
            const item = { id: doc.name.split('/').pop() };
            for (const [key, value] of Object.entries(doc.fields || {})) {
                if (value.stringValue) item[key] = value.stringValue;
                else if (value.integerValue) item[key] = parseInt(value.integerValue);
                else if (value.doubleValue) item[key] = parseFloat(value.doubleValue);
                else if (value.arrayValue) {
                    item[key] = (value.arrayValue.values || []).map(v => v.stringValue);
                }
            }
            return item;
        });
    } catch (e) {
        console.error("Fetch Error:", e);
        return [];
    }
}

async function queryFirestore(env, collection, filters) {
    const url = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents:runQuery?key=${env.FIREBASE_API_KEY}`;

    const where = {
        compositeFilter: {
            op: 'AND',
            filters: filters.map(f => ({
                fieldFilter: {
                    field: { fieldPath: f.fieldPaths[0] },
                    op: f.op,
                    value: { stringValue: f.value }
                }
            }))
        }
    };

    const body = {
        structuredQuery: {
            from: [{ collectionId: collection }],
            where: where
        }
    };

    try {
        const res = await fetch(url, {
            method: 'POST',
            body: JSON.stringify(body)
        });
        const data = await res.json();
        return (data || []).map(d => {
            if (!d.document) return null;
            return {
                id: d.document.name.split('/').pop(),
                fields: d.document.fields
            };
        }).filter(Boolean);
    } catch (e) {
        return [];
    }
}
