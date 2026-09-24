import QtQuick

QtObject {
    // Parses common single-line Hyprland bind, bindr and bindm entries.
    // Variables and submaps are kept literal so imported rows remain reviewable.
    function parseHyprland(text, environment) {
        const parsed = []
        const lines = (text || "").split(/\r?\n/)
        for (let i = 0; i < lines.length; ++i) {
            const line = lines[i].trim()
            if (!line || line.startsWith("#")) continue
            const match = line.match(/^bind(r|m)?\s*=\s*(.*)$/i)
            if (!match) continue
            const fields = match[2].split(",")
            if (fields.length < 3) continue
            const modifiers = fields[0].trim().split("+").filter(function(part) { return part.length > 0 }).map(function(part) {
                const name = part.trim().toUpperCase()
                return name === "$MAINMOD" ? "SUPER" : name
            })
            let key = fields[1].trim().toUpperCase()
            if (key === "RETURN" || key === "KP_ENTER") key = "ENTER"
            if (key === "ESCAPE") key = "ESC"
            if (key === "CONTROL") key = "CTRL"
            if (key === "SUPER_L" || key === "SUPER_R" || key === "WIN") key = "SUPER"
            const dispatcher = fields[2].trim()
            const argument = fields.slice(3).join(",").trim()
            const keys = modifiers.concat(key && key !== "" ? [key] : [])
            if (!keys.length) continue
            parsed.push({
                environment: environment || "Custom Hyprland",
                target: "Hyprland",
                category: dispatcher.toLowerCase().indexOf("workspace") >= 0 ? "Workspaces" : dispatcher.toLowerCase().indexOf("exec") >= 0 ? "Applications" : "Imported",
                keys: keys,
                description: dispatcher + (argument ? " " + argument : ""),
                action: dispatcher,
                bindingType: match[1] || "bind",
                sourceLine: i + 1
            })
        }
        return parsed
    }
}
