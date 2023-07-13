function expandContent(content, forceExpand = false) {
    var expansion = content.querySelector(".expansion");
    var moreless = content.querySelector(".moreless");
    if (expansion.style.maxHeight && !forceExpand){
        expansion.style.maxHeight = null;
        moreless.innerHTML = "[more]";
    } else {
        expansion.style.maxHeight = expansion.scrollHeight + "px";
        moreless.innerHTML = "[less]";
    }
}

function openAnchor() {
    var hash = window.location.hash.substring(1);
    var anchor = document.getElementById(hash);
    if (anchor) {
        var content = anchor.getElementsByTagName('div')[0];
        expandContent(content, true)
    }
}

window.addEventListener('hashchange', function() { openAnchor() });
window.onload = openAnchor();

var coll = document.getElementsByClassName("collapsible");
for (var i = 0; i < coll.length; i++) {
    coll[i].addEventListener("click", function(event)
    {
        var targetTag = event.target.tagName;
        if (targetTag == "DIV" || targetTag == "BUTTON") {
            expandContent(this);
        }
    });
}