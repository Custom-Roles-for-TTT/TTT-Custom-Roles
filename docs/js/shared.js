// COLLAPSABLE SECTIONS
function expandContent(content, forceExpand = false) {
    var expansion = content.querySelector(".expansion");
    if (expansion) {
        var moreless = content.querySelector(".moreless");
        if (expansion.style.maxHeight && !forceExpand) {
            expansion.style.maxHeight = null;
            moreless.innerHTML = "[more]";
        } else {
            expansion.style.maxHeight = expansion.scrollHeight + "px";
            moreless.innerHTML = "[less]";
        }
    }
}

function openAnchor() {
    var hash = window.location.hash.substring(1);
    if (!hash) return;

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

// NAVIGATION PANEL
function resizeIframe(obj) {
    obj.style.height = obj.contentWindow.document.documentElement.scrollHeight + 'px';
}

var naviframe = document.getElementById("nav");
window.onresize = function() {
    var innerdoc = naviframe.contentDocument || naviframe.contentWindow.document;
    var navdiv = innerdoc.getElementById("navwrapper");
    naviframe.style.height = navdiv.clientHeight + 'px';
}

// TO TOP BUTTON
var topbutton = document.getElementById("totop");

window.onscroll = function() {
    if (document.body.scrollTop > 20 || document.documentElement.scrollTop > 20) {
        topbutton.style.display = "block";
    } else {
        topbutton.style.display = "none";
    }
};

function backToTop() {
    document.body.scrollTop = 0; // For Safari
    document.documentElement.scrollTop = 0; // For Chrome, Firefox, IE and Opera
}