import QtQuick
import "../data/shortcuts.js" as ShortcutData

QtObject {
    readonly property var items: ShortcutData.items

    function search(query, source) {
        const needle = (query || "").trim().toLowerCase()
        const normalizedKeys = needle.replace(/\s*\+\s*/g, " ")
        const list = source || items
        if (!needle) return list
        return list.filter(function(item) {
            const haystack = [item.name, item.description, item.action, item.application,
                              item.target, item.category, item.environment,
                              item.keys.join(" ")].join(" ").toLowerCase()
            return haystack.indexOf(needle) >= 0 || haystack.indexOf(normalizedKeys) >= 0
        })
    }

    function conflicts(source) {
        const seen = ({})
        const duplicates = []
        ;(source || items).forEach(function(item) {
            const signature = item.environment + "/" + item.target + "/" + item.keys.slice().sort().join("+")
            if (seen[signature]) duplicates.push({keys:item.keys, first:seen[signature], second:item})
            else seen[signature] = item
        })
        return duplicates
    }
}
