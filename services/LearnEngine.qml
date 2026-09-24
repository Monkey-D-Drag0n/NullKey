import QtQuick

QtObject {
    property int index: 0
    property int score: 0
    property int answered: 0
    property var questions: [
        {prompt:"How do you close the active Hyprland window?", keys:["SUPER","Q"]},
        {prompt:"How do you switch to workspace 1?", keys:["SUPER","1"]},
        {prompt:"How do you open the terminal?", keys:["SUPER","ENTER"]}
    ]
    readonly property var current: questions[index % questions.length]
    function answer(keys) {
        ++answered
        const correct = keys.length === current.keys.length && current.keys.every(function(key) { return keys.indexOf(key) >= 0 })
        if (correct) ++score
        index = (index + 1) % questions.length
        return correct
    }
    function reset() { index = 0; score = 0; answered = 0 }
}
