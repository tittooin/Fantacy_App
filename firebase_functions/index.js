const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

// RapidAPI Configuration
// Hindi: RapidAPI ki settings
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const RAPID_API_HOST = 'free-cricbuzz-cricket-api1.p.rapidapi.com';
const RAPID_API_BASE_URL = `https://${RAPID_API_HOST}`;

/**
 * Helper: RapidAPI se data fetch karna
 * Hindi: RapidAPI se data laane ke liye helper function
 */
async function fetchFromRapidAPI(endpoint) {
    try {
        console.log(`📡 [RapidAPI] GET ${endpoint}`);

        const response = await axios.get(`${RAPID_API_BASE_URL}${endpoint}`, {
            headers: {
                'x-rapidapi-key': RAPID_API_KEY,
                'x-rapidapi-host': RAPID_API_HOST
            }
        });

        console.log(`✅ [RapidAPI] 200 OK - ${endpoint}`);
        return response.data;
    } catch (error) {
        console.error(`❌ [RapidAPI] Error on ${endpoint}:`, error.message);
        throw error;
    }
}

/**
 * Cloud Function: Manual Refresh (Admin Only)
 * Hindi: Admin button se manually matches refresh karne ke liye
 */
exports.refreshMatches = functions.https.onCall(async (data, context) => {
    // Verify admin (optional - add auth check)
    // if (!context.auth || !context.auth.token.admin) {
    //   throw new functions.https.HttpsError('permission-denied', 'Admin only');
    // }

    try {
        console.log('🔄 [Manual Refresh] Starting...');

        // 1. Fetch matches from RapidAPI
        const matchesData = await fetchFromRapidAPI('/matches');

        // 2. Parse and save to Firestore
        const matches = parseMatches(matchesData);
        await saveMatchesToFirestore(matches);

        console.log(`✅ [Manual Refresh] Saved ${matches.length} matches`);

        return {
            success: true,
            count: matches.length,
            message: `Successfully refreshed ${matches.length} matches`
        };
    } catch (error) {
        console.error('❌ [Manual Refresh] Error:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});

/**
 * Scheduled Function: Auto Polling (Every 5 minutes)
 * Hindi: Har 5 minute mein automatically matches update karne ke liye
 */
exports.pollMatches = functions.pubsub
    .schedule('every 5 minutes')
    .onRun(async (context) => {
        try {
            console.log('⏰ [Scheduled Poll] Starting...');

            // 1. Fetch matches
            const matchesData = await fetchFromRapidAPI('/matches');
            const matches = parseMatches(matchesData);

            // 2. Save to Firestore
            await saveMatchesToFirestore(matches);

            // 3. Fetch live matches for detailed updates
            const liveData = await fetchFromRapidAPI('/live');
            const liveMatches = parseMatches(liveData);

            // 4. Update scorecards for live matches
            for (const match of liveMatches) {
                await updateMatchScorecard(match.id);
            }

            console.log(`✅ [Scheduled Poll] Updated ${matches.length} matches, ${liveMatches.length} live`);
        } catch (error) {
            console.error('❌ [Scheduled Poll] Error:', error);
        }
    });

/**
 * Cloud Function: Fetch Scorecard
 * Hindi: Specific match ka scorecard fetch karne ke liye
 */
exports.fetchScorecard = functions.https.onCall(async (data, context) => {
    const { matchId } = data;

    if (!matchId) {
        throw new functions.https.HttpsError('invalid-argument', 'matchId required');
    }

    try {
        const scorecardData = await fetchFromRapidAPI(`/scorecard?matchId=${matchId}`);

        // Save to Firestore
        await admin.firestore()
            .collection('scorecards')
            .doc(matchId.toString())
            .set({
                ...scorecardData,
                lastUpdated: admin.firestore.FieldValue.serverTimestamp()
            });

        return { success: true, data: scorecardData };
    } catch (error) {
        console.error('❌ [Scorecard] Error:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});

/**
 * Helper: Parse matches from RapidAPI response
 * Hindi: RapidAPI response ko parse karke matches nikalna
 */
function parseMatches(data) {
    const matches = [];

    try {
        // Handle different response structures
        if (data.typeMatches) {
            for (const type of data.typeMatches) {
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
                }
            }
        }
    } catch (error) {
        console.error('❌ [Parse] Error:', error);
    }

    return matches;
}

/**
 * Helper: Format match data
 * Hindi: Match data ko Firestore format mein convert karna
 */
function formatMatch(info) {
    return {
        id: info.matchId?.toString() || '',
        seriesName: info.seriesName || 'Series',
        matchDesc: info.matchDesc || 'Match',
        matchFormat: info.matchFormat || 'T20',
        team1: {
            name: info.team1?.teamName || 'Team 1',
            shortName: info.team1?.teamSName || 'T1',
            imageId: info.team1?.imageId?.toString() || '1'
        },
        team2: {
            name: info.team2?.teamName || 'Team 2',
            shortName: info.team2?.teamSName || 'T2',
            imageId: info.team2?.imageId?.toString() || '1'
        },
        startDate: info.startDate || 0,
        endDate: info.endDate || 0,
        venue: info.venueInfo?.ground || 'Venue',
        status: info.status || info.state || 'Upcoming',
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    };
}

/**
 * Helper: Save matches to Firestore
 * Hindi: Matches ko Firestore mein save karna
 */
async function saveMatchesToFirestore(matches) {
    const batch = admin.firestore().batch();

    for (const match of matches) {
        const docRef = admin.firestore()
            .collection('matches')
            .doc(match.id);

        batch.set(docRef, match, { merge: true });
    }

    await batch.commit();
    console.log(`💾 [Firestore] Saved ${matches.length} matches`);
}

/**
 * Helper: Update match scorecard
 * Hindi: Match ka scorecard update karna
 */
async function updateMatchScorecard(matchId) {
    try {
        const scorecardData = await fetchFromRapidAPI(`/scorecard?matchId=${matchId}`);

        await admin.firestore()
            .collection('scorecards')
            .doc(matchId.toString())
            .set({
                ...scorecardData,
                lastUpdated: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });

        console.log(`💾 [Scorecard] Updated for match ${matchId}`);
    } catch (error) {
        console.error(`❌ [Scorecard] Error for match ${matchId}:`, error.message);
    }
}
