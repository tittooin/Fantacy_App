/**
 * Debug Script: Test RapidAPI Response
 * Hindi: Worker ki problem debug karne ke liye
 */

const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const RAPID_API_HOST = 'free-cricbuzz-cricket-api.p.rapidapi.com';

async function testRapidAPI() {
    try {
        console.log('📡 Testing RapidAPI /matches endpoint...\n');

        const url = `https://${RAPID_API_HOST}/matches`;

        const response = await fetch(url, {
            headers: {
                'x-rapidapi-key': RAPID_API_KEY,
                'x-rapidapi-host': RAPID_API_HOST
            }
        });

        console.log(`Status: ${response.status} ${response.statusText}`);
        console.log(`Headers:`, Object.fromEntries(response.headers));

        if (!response.ok) {
            const errorText = await response.text();
            console.error('\n❌ Error Response:', errorText);
            return;
        }

        const data = await response.json();
        console.log('\n✅ Response received!');
        console.log('Response structure:', JSON.stringify(data, null, 2).substring(0, 1000));

        // Test parsing
        console.log('\n🔍 Testing parseMatches function...');
        const matches = parseMatches(data);
        console.log(`✅ Parsed ${matches.length} matches`);

        if (matches.length > 0) {
            console.log('\nFirst match:', JSON.stringify(matches[0], null, 2));
        }

    } catch (error) {
        console.error('❌ Error:', error.message);
        console.error('Stack:', error.stack);
    }
}

function parseMatches(data) {
    const matches = [];

    try {
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
        console.error('❌ Parse error:', error);
        throw error;
    }

    return matches;
}

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
        lastUpdated: Date.now()
    };
}

// Run test
testRapidAPI();
