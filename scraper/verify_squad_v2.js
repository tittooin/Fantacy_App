
import { processSquads } from '../workers/squad_engine.js';

// Mock Environment
const env = {
    DB: {
        prepare: (query) => {
            // Mock Query Execution
            return {
                bind: (...args) => ({
                    all: async () => {
                        console.log(`\n🔍 Executing SQL: ${query.substring(0, 100)}...`);
                        console.log(`   Params: ${args}`);

                        // Scenario 1: Fetch Candidate (Match 139216)
                        if (query.includes('FROM matches m')) {
                            // Simulate Match 139216 in Initial State (0)
                            return {
                                results: [{
                                    id: '139216',
                                    series_id: '11253',
                                    status: 'Upcoming', // Simulate Upcoming to trigger State 0 -> 1
                                    start_time: Date.now() + 100000,
                                    current_state: 0 // Never Fetched
                                }]
                            };
                        }
                        return { results: [] };
                    },
                    first: async () => {
                        if (query.includes('SELECT team_a')) {
                            return { team_a: 'India', team_b: 'Pakistan', team_a_id: '2', team_b_id: '3' };
                        }
                        return null;
                    },
                    run: async () => {
                        console.log(`   ✅ DB WRITE EXECUTED`);
                        return { success: true };
                    }
                })
            };
        }
    }
};

async function runVerification() {
    console.log("🧪 STARTING VERIFICATION SIMULATION (Match 139216)");
    console.log("   Scenario: Initial Fetch (State 0 -> 1)");

    await processSquads(env);

    console.log("\n🧪 VERIFICATION COMPLETE");
}

runVerification();
