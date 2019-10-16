<?php
/**
 * DokuWiki Plugin tabbox (Action Component)
 *
 * @license GPL 2 http://www.gnu.org/licenses/gpl-2.0.html
 * @author  Andreas Gohr <dokuwiki@cosmocode.de>
 */

// must be run within Dokuwiki
if(!defined('DOKU_INC')) die();

class action_plugin_tabbox extends DokuWiki_Action_Plugin {

    public function register(Doku_Event_Handler $controller) {
        $controller->register_hook('TOOLBAR_DEFINE', 'AFTER', $this, 'insert_button');
    }


    /**
     * Inserts a toolbar button
     */
    function insert_button(& $event, $param) {

        $tabs = explode(',', $this->getConf('tabs'));
        $tabs = array_map('trim', $tabs);

        $tab = array_shift($tabs);
        $open = '<tabbox '.$tab.'>\n\n';
        $close = '\n\n';
        foreach($tabs as $tab) {
            $close .= '<tabbox '.$tab.'>\n\n';
        }
        $close .= '</tabbox>';

        $event->data[] = array (
            'type' => 'format',
            'title' => $this->getLang('tabbox_btn'),
            'icon' => '../../plugins/tabbox/button.png',
            'open' => $open,
            'close' => $close,
            'block' => true,
        );
    }

}