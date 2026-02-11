#!/usr/bin/env python3
# Script to add InkWell wrapper to leaderboard rows

import sys

# Read the file
with open('lib/features/contest/presentation/contest_detail_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find the line with "final points = data['points'] ?? 0;"
# and add teamId extraction after it
# Then wrap the Container with InkWell

modified = False
new_lines = []
i = 0

while i < len(lines):
    line = lines[i]
    new_lines.append(line)
    
    # Look for the specific pattern around line 396
    if "final points = data['points'] ?? 0;" in line and not modified:
        # Add teamId extraction
        indent = ' ' * 28  # Match existing indentation
        new_lines.append(f"{indent}final teamIdFromData = data['teamId'] ?? '';\n")
        new_lines.append(f"{indent}\n")
        
        # Next line should be blank, then "return Container("
        i += 1
        if i < len(lines):
            new_lines.append(lines[i])  # blank line
        
        i += 1
        if i < len(lines) and 'return Container(' in lines[i]:
            # Replace "return Container(" with "return InkWell("
            indent2 = ' ' * 28
            new_lines.append(f"{indent2}return InkWell(\n")
            new_lines.append(f"{indent2}  onTap: teamIdFromData.isNotEmpty \n")
            new_lines.append(f"{indent2}    ? () => _showTeamPitchView(context, ref, data)\n")
            new_lines.append(f"{indent2}    : null,\n")
            new_lines.append(f"{indent2}  child: Container(\n")
            
            # Continue copying until we find the closing of Container
            i += 1
            depth = 1
            while i < len(lines) and depth > 0:
                current_line = lines[i]
                # Count parentheses to track depth
                depth += current_line.count('(') - current_line.count(')')
                
                # If this is the trailing line, modify it
                if 'trailing: isCurrentUser ?' in current_line:
                    # Replace trailing with Row containing star and chevron
                    indent3 = ' ' * 34
                    new_lines.append(f"{indent3}trailing: Row(\n")
                    new_lines.append(f"{indent3}  mainAxisSize: MainAxisSize.min,\n")
                    new_lines.append(f"{indent3}  children: [\n")
                    new_lines.append(f"{indent3}    if (isCurrentUser) const Icon(Icons.star, color: Colors.orange, size: 16),\n")
                    new_lines.append(f"{indent3}    if (teamIdFromData.isNotEmpty) ...[\n")
                    new_lines.append(f"{indent3}      const SizedBox(width: 8),\n")
                    new_lines.append(f"{indent3}      Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),\n")
                    new_lines.append(f"{indent3}    ],\n")
                    new_lines.append(f"{indent3}  ],\n")
                    new_lines.append(f"{indent3}),\n")
                    i += 1
                    continue
                
                if depth == 0:
                    # Add closing for InkWell
                    new_lines.append(current_line)  # The ");" from Container
                    new_lines.append(f"{indent2}),\n")  # Close InkWell child
                    new_lines.append(f"{indent2});\n")  # Close InkWell
                    modified = True
                    break
                else:
                    new_lines.append(current_line)
                i += 1
    
    i += 1

if modified:
    # Write back
    with open('lib/features/contest/presentation/contest_detail_screen.dart', 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    print("✅ Successfully updated leaderboard rows to be tappable!")
else:
    print("❌ Could not find the pattern to modify")
    sys.exit(1)
