var totd_loadnew = function(id, totd) {

        jQuery.post(DOKU_BASE + 'lib/exe/ajax.php',
        {
            call: '_totd_loadnew',
            id: id,
            totd: totd
        }, function(data) {
            jQuery('#totd_plugin').html(data);
        });
};
