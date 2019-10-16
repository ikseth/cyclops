/**
 * Javascript for DokuWiki Plugin Mp3play
 *
 * Slightly modified for DokuWiki
 *
 * Michael Klier <chi@chimeric.de>
 */

var ap_instances = new Array();

function ap_stopAll(playerID) {
    for(var i = 0; i<ap_instances.length; i++) {
        try {
            if(ap_instances[i].id != 'audioplayer' + playerID) { 
                ap_instances[i].SetVariable("closePlayer", 1);
            } else {
                ap_instances[i].SetVariable("closePlayer", 0);
            }
        } catch( errorObject ) {
            // stop any errors
        }
    }
}

jQuery(function() {
    var objectTags = document.getElementsByTagName("object");
    var players = new Array();

    var x = 0;
    for(var i=0; i<objectTags.length; i++) {
        if(objectTags[i].className == 'plugin_mp3play') {
            players[x] = objectTags[i];
            x++;
        }
    }

    for(var j=0; j<players.length; j++) {
        players[j].id = 'audioplayer' + j;
        ap_instances[j] = players[j];
        var flashvars = players[j].getElementsByTagName('param')[1];
        flashvars.value = flashvars.value + '&playerID=' + j;
    }
});

// vim:ts=4:sw=4:et:enc=utf-8:
