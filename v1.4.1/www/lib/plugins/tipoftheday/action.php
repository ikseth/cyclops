<?php
/**
 * TotD Plugin:  Display a random wiki page section within another wiki page
 *
 * Action plugin component, uses the include plugin
 *
 * @license    GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author     i-net software / Gerry Wei§bach <tools@inetsoftware.de>
 */
if(!defined('DOKU_INC')) die();  // no Dokuwiki, no go

if(!defined('DOKU_PLUGIN')) define('DOKU_PLUGIN',DOKU_INC.'lib/plugins/');
require_once(DOKU_PLUGIN.'action.php');

/**
 * All DokuWiki plugins to extend the parser/rendering mechanism
 * need to inherit from this class
 */
class action_plugin_totd extends DokuWiki_Action_Plugin {

    /**
     * plugin should use this method to register its handlers with the dokuwiki's event controller
     */
    function register(Doku_Event_Handler $controller) {
        $controller->register_hook('AJAX_CALL_UNKNOWN', 'BEFORE', $this, 'ajax_totd_loadnew');
    }

    function ajax_totd_loadnew( Doku_Event &$event ) {

        if ( $event->data != '_totd_loadnew' ) {
            return;
        }

        $event->preventDefault();
        $event->stopPropagation();

        $ID = urldecode($_REQUEST['id']);
        list($ID, $params) = explode('&', $ID, 2);
        if ( !empty($params) ) $params = '&' . $params;

        $ID = cleanID($ID);
        $section = cleanID($_REQUEST['totd']); // Not needed here, but in the plugin

        $ins = p_get_instructions("{{totd>$ID{$params}}}");
        $data = p_render('xhtml', $ins, $INFO);

        header('Content-Type: text/html; charset=utf-8');
        print $data;
        return;
    }

}
//vim:ts=4:sw=4:et:enc=utf-8:
