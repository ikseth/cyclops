/**
 * Javascript functionality for the DokuBook template
 *
 * @author Michael Klier <chi@chimeric.de>
 */

// attach the AJAX index to the sidebar index
var sb_dw_index = jQuery('#left__index__tree').dw_tree({deferInit: true,
    load_data: function  (show_sublist, $clicky) {
        jQuery.post(
            DOKU_BASE + 'lib/exe/ajax.php',
            $clicky[0].search.substr(1) + '&call=index',
            show_sublist, 'html'
        );
    }
});  
jQuery(document).ready(function($) {
    var $tree = jQuery('#sb__index__tree');
    sb_dw_index.$obj = $tree;
    sb_dw_index.init();

// add TOC events
//    jQuery(addSbLeftTocToggle);
});

