import QtQuick

QtObject {
    property int limit: 12
    property var items: []
    function touch(item) {
        const next = [item].concat(items.filter(function(entry) {
            return entry.target !== item.target || entry.environment !== item.environment || entry.keys.join("+") !== item.keys.join("+")
        }))
        items = next.slice(0, limit)
    }
    function clear() { items = [] }
}
