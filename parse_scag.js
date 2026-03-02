const fs = require('fs');
const data = fs.readFileSync('scag2.html', 'utf8');

function extractScagData(html) {
    const startStr = '\\"currentMatchesList\\":';
    const startIndex = html.indexOf(startStr);
    if (startIndex === -1) {
        console.log("Start string not found");
        return null;
    }

    // We start immediately after the colon
    let searchStr = html.substring(startIndex + startStr.length);

    // Since the string is safely inside a JS literal, \" is how quotes are represented.
    // The actual JSON is further embedded. Let's unescape it to normal JSON.
    // However, \\" inside a real string within the JSON becomes \". 
    // A simpler way: Find the containing string literal first!

    const literalStart = html.lastIndexOf('"', startIndex);
    // Let's just find the closing brace by counting on the RAW string.

    let openBraces = 0;
    let endIndex = -1;
    let inString = false;
    let escapeNext = false;

    for (let i = 0; i < searchStr.length; i++) {
        const char = searchStr[i];

        if (escapeNext) {
            escapeNext = false;
            continue;
        }

        if (char === '\\') {
            escapeNext = true;
            continue;
        }

        if (char === '"') {
            inString = !inString;
            continue;
        }

        if (!inString) {
            if (char === '{') openBraces++;
            if (char === '}') {
                openBraces--;
                if (openBraces === 0) {
                    endIndex = i;
                    break;
                }
            }
        }
    }

    if (endIndex !== -1) {
        let rawJson = searchStr.substring(0, endIndex + 1);

        // Unescape the rawJson
        // Because it's inside a string literal, \" means "
        // \\ means \
        let unescaped = rawJson.replace(/\\\\"/g, '\\"').replace(/\\"/g, '"').replace(/\\\\\\\\/g, '\\\\');

        try {
            const parsed = JSON.parse(unescaped);
            console.log("SUCCESS: Extracted matches!");
            console.log("Found", parsed.typeMatches.length, "types");
            if (parsed.typeMatches[0]) {
                console.log("Type 0:", parsed.typeMatches[0].matchType);
            }
            return parsed;
        } catch (e) {
            console.error("Parse error. First 100 chars:", unescaped.substring(0, 100));
            console.error("Last 100 chars:", unescaped.substring(unescaped.length - 100));
            console.error(e);
            return null;
        }
    } else {
        console.log("End index not found");
    }
    return null;
}

const result = extractScagData(data);
if (result) {
    fs.writeFileSync('extracted.json', JSON.stringify(result, null, 2));
    console.log("Wrote extracted.json");
}
