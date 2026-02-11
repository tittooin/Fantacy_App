import re

# Read the file
with open('lib/features/contest/presentation/contest_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Find and replace the leaderboard row section
old_pattern = r'''                            final points = data\['points'\] \?\? 0;

                            return Container\(
                              color: isCurrentUser \? Colors\.indigo\.withOpacity\(0\.05\) : Colors\.white,
                              child: ListTile\(
                                leading: CircleAvatar\(
                                  backgroundColor: isCurrentUser \? Colors\.indigo : Colors\.grey\[300\],
                                  child: Text\("\$rank", style: TextStyle\(color: isCurrentUser \? Colors\.white : Colors\.black\)\),
                                \),
                                title: Text\(display, style: TextStyle\(fontWeight: isCurrentUser \? FontWeight\.bold : FontWeight\.normal\)\),
                                subtitle: Text\("\$\{data\['teamName'\] \?\? 'Team'\} • \$\{points\.toStringAsFixed\(0\)\} pts"\), // Format points
                                trailing: isCurrentUser \? const Icon\(Icons\.star, color: Colors\.orange, size: 16\) : null,
                              \),
                            \);'''

new_code = '''                            final points = data['points'] ?? 0;
                            final teamIdFromData = data['teamId'] ?? '';

                            return InkWell(
                              onTap: teamIdFromData.isNotEmpty 
                                ? () => _showTeamPitchView(context, ref, data)
                                : null,
                              child: Container(
                                color: isCurrentUser ? Colors.indigo.withOpacity(0.05) : Colors.white,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isCurrentUser ? Colors.indigo : Colors.grey[300],
                                    child: Text("$rank", style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black)),
                                  ),
                                  title: Text(display, style: TextStyle(fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal)),
                                  subtitle: Text("${data['teamName'] ?? 'Team'} • ${points.toStringAsFixed(0)} pts"), // Format points
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isCurrentUser) const Icon(Icons.star, color: Colors.orange, size: 16),
                                      if (teamIdFromData.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );'''

# Replace
content = re.sub(old_pattern, new_code, content, flags=re.DOTALL)

# Write back
with open('lib/features/contest/presentation/contest_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Successfully updated contest_detail_screen.dart")
