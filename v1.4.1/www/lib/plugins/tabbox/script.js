jQuery(function(){

    /**
     * Open a tab
     *
     * Adds and removes classes, handles cookie setting, closes other tabs
     *
     * @param {jQuery} $box  The box we're handling
     * @param {string} tabid The ID of the tab to open
     */
    function tabboxopen($box, tabid) {
        // hide all tabs
        $box.find('.tabboxtab').hide();
        $box.find('.tabs li').removeClass('active');

        // try the given ID
        var $open = $box.find('#tab_'+tabid);
        if(!$open.length) {
            // fall back to first tab
            $open = $box.find('.tabboxtab').first();
        }

        var id = $open.attr('id').substr(4);
        $box.find('#lnk_'+id).addClass('active');
        $open.show();
        DokuCookie.setValue('tabbox', id);
    }

    /**
     * Build the Tab Boxes
     */
    jQuery('.plugin_tabbox').each(function(){
        var $box = jQuery(this);
        $box.addClass('js');

        // create the tabs
        var $ul = jQuery(document.createElement('ul'));
        $ul.addClass('tabs');
        $box.find('.tabboxtab .hl').each(function(){
            var $hl = jQuery(this);
            $hl.hide();

            var $a = jQuery(document.createElement('a'));
            $a.attr('href', '#'+$hl.attr('id'));
            $a.text($hl.text());
            $a.click(function(){
                tabboxopen($box, $hl.attr('id'));
            });

            var $li = jQuery(document.createElement('li'));
            $li.attr('id', 'lnk_'+$hl.attr('id'));
            $li.append($a);
            $ul.append($li);
        });
        $box.prepend($ul);

        // open a tab (falls back to first tab)
        if(DokuCookie.getValue('tabbox')) {
            tabboxopen($box, DokuCookie.getValue('tabbox'));
        }

        tabboxopen($box, window.location.hash.substring(1));

    });

});
