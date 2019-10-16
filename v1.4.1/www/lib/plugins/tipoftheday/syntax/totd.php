<?php
/**
 * popoutviewer Plugin
 *
 * @license    GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author     i-net software <tools@inetsoftware.de>
 * @author     Gerry Weissbach <gweissbach@inetsoftware.de>
 */

// must be run within Dokuwiki
if(!defined('DOKU_INC')) die();
if (!defined('DOKU_PLUGIN')) define('DOKU_PLUGIN',DOKU_INC.'lib/plugins/');

require_once(DOKU_PLUGIN.'syntax.php');

class syntax_plugin_tipoftheday_totd extends DokuWiki_Syntax_Plugin {

    private $hasSections = array();

    function getType() { return 'substition'; }
    function getPType() { return 'block'; }
    function getSort() { return 302; }

    function connectTo($mode) {
        $this->Lexer->addSpecialPattern('{{totd>.+?}}', $mode, 'plugin_totd_totd');
    }

    function handle($match, $state, $pos, Doku_Handler $handler) {

        $match = substr($match, 2, -2); // strip markup
        list($match, $flags) = explode('&', $match, 2);

        // break the pattern up into its parts 
        list($mode, $page, $sect) = preg_split('/>|#/u', $match, 3);

        $return = array($page, explode('&', $flags));
        return $return; 
    }

    function render($mode, Doku_Renderer $renderer, $data) {
        global $ID;

        if ( $mode == 'xhtml' ) {
            $renderer->nocache();

            list($page, $flags) = $data;
            if ( !is_Array($flags) ) {
                $flags = array($flags);
            }

            $sections = $this->_getSections($page);

            // Check for given totd section
            if ( empty($_REQUEST['totd']) ) { 
                $section = $sections[array_rand($sections)];
            } else {
                $section = $_REQUEST['totd'];
            }

            if ( empty($section) ) $section = $sections[0];

            $this->hasSections[] = cleanID($section); // Prevent selecting the same section again

            $helper = plugin_load('helper', 'include');
            $ins = $helper->_get_instructions($page, cleanID($section), $mode, $renderer->lastlevel, $flags);

            $renderer->doc .= '<div id="totd_plugin">';
            $renderer->doc .= '<div class="totd-header">';
            $renderer->doc .= '<h1>Tip of the Day</h1>';
            $renderer->doc .= '</div>';
            $renderer->doc .= '<div class="totd-content">';

            $renderer->doc .= p_render($mode, $ins, $myINFO);

            $current = array_search($section, $sections);

            // Index for next and previous entry
            $prev = ($current == 0 ? count($sections) : $current) -1; 
            $next = ($current >= count($sections)-1 ? 0 : $current +1);

            $renderer->doc .= '</div>';
            $renderer->doc .= '<div class="totd-footer">';
            $renderer->doc .= tpl_link(wl($ID, array('totd' => $sections[$prev])), "&lt;", 'title="previous" onclick="totd_loadnew(\'' . $page . (count($flags)>0 ? '%26' . implode('%26', $flags) : '') . '\', \'' . $sections[$prev] . '\'); return false;"', true );
            $renderer->doc .= tpl_link(wl($ID, array('totd' => $sections[$next])), "&gt;", 'title="next" onclick="totd_loadnew(\'' . $page . (count($flags)>0 ? '%26' . implode('%26', $flags) : '') . '\', \'' . $sections[$next] . '\'); return false;"', true );
            $renderer->doc .= '</div>';
            $renderer->doc .= '</div>';

            return true;
        }

        return false;
    }

    /**
     * Get a section including its subsections
     */
    function _getSections($id) {

        $headers = array();
        $instructions = p_cached_instructions(wikiFN($id));
        if ( !is_array($instructions) ) return array();

        foreach ($instructions as $ins) {
            if ($ins[0] == 'header') {
                if ( in_array(cleanID($ins[1][0]), $this->hasSections) ) { continue; }
                $headers[] = $ins[1][0]; // section name
            }
        }

        return $headers;
    }
}
// vim:ts=4:sw=4:et:enc=utf-8:
