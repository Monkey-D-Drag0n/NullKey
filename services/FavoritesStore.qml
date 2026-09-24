import QtQuick

QtObject {
    property var items: []
    function contains(item) {
        return items.some(function(entry) {
            return entry.target === item.target && entry.environment === item.environment && entry.keys.join("+") === item.keys.join("+")
        })
    }
    function toggle(item) {
        let next = items.slice()
        const index = next.findIndex(function(entry) {
            return entry.target === item.target && entry.environment === item.environment && entry.keys.join("+") === item.keys.join("+")
        })
        if (index >= 0) next.splice(index, 1)
        else next.unshift(item)
        items = next
    }
}
