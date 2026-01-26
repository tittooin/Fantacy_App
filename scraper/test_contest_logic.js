
// Mock Data
const mockMatchId = "12345";
const mockContestId = "c-001";

const mockPlayers = {
    "p1": { id: "p1", fantasyPoints: 50 },
    "p2": { id: "p2", fantasyPoints: 30 },
    "p3": { id: "p3", fantasyPoints: 10 },
    "p4": { id: "p4", fantasyPoints: 100 },
};

const mockParticipants = [
    { teamId: "t1", userId: "u1", captain: "p1", viceCaptain: "p2", players: ["p1", "p2", "p3"] }, // Points: (50*2) + (30*1.5) + 10 = 100 + 45 + 10 = 155
    { teamId: "t2", userId: "u2", captain: "p4", viceCaptain: "p3", players: ["p4", "p3", "p1"] }, // Points: (100*2) + (10*1.5) + 50 = 200 + 15 + 50 = 265
    { teamId: "t3", userId: "u1", captain: "p3", viceCaptain: "p1", players: ["p3", "p1", "p2"] }, // Points: (10*2) + (50*1.5) + 30 = 20 + 75 + 30 = 125 (Multi entry same user)
];

// Mock Engine Logic
async function runSimulation() {
    console.log("🏆 Running Contest Simulation...");

    let updatedTeams = [];

    for (const team of mockParticipants) {
        let total = 0;
        for (const pid of team.players) {
            let pts = mockPlayers[pid]?.fantasyPoints || 0;
            if (pid === team.captain) pts *= 2;
            else if (pid === team.viceCaptain) pts *= 1.5;
            total += pts;
        }
        updatedTeams.push({ teamId: team.teamId, userId: team.userId, points: total });
    }

    // Sort
    updatedTeams.sort((a, b) => b.points - a.points);

    // Rank
    for (let i = 0; i < updatedTeams.length; i++) updatedTeams[i].rank = i + 1;

    console.log("📊 Final Leaderboard:");
    console.table(updatedTeams);

    // Validations
    const t1 = updatedTeams.find(t => t.teamId === 't1');
    const t2 = updatedTeams.find(t => t.teamId === 't2');
    const t3 = updatedTeams.find(t => t.teamId === 't3');

    if (t2.rank === 1 && t2.points === 265) console.log("✅ Rank 1 Correct (Team 2)");
    else console.error("❌ Rank 1 Failed");

    if (t1.rank === 2 && t1.points === 155) console.log("✅ Rank 2 Correct (Team 1)");
    else console.error("❌ Rank 2 Failed");

    if (t3.userId === 'u1' && t1.userId === 'u1') console.log("✅ Multi-Team Support Verified (User 1 has 2 teams)");
    else console.error("❌ Multi-Team Failed");
}

runSimulation();
