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

class syntax_plugin_tipoftheday_totns extends DokuWiki_Syntax_Plugin {

    function getType() { return 'substition'; }
    function getPType() { return 'block'; }
    function getSort() { return 40; }

    function connectTo($mode) {
        $this->Lexer->addSpecialPattern('{{totns>.+?}}', $mode, 'plugin_totd_totns');
    }

    function handle($match, $state, $pos, Doku_Handler $handler) {

        $match = substr($match, 2, -2); // strip markup
        list($match, $flags) = explode('&', $match, 2);

        // break the pattern up into its parts
        list($mode, $page, $sect) = preg_split('/>|#/u', $match, 3);

        $header = $this->_getNSFiles(getNS($page));
        
        $page = $header[intval(date('W')) %  count($header)];
        if ( empty($page) ) {
            $page = $header[0]; 
        }
        
        return array($page, explode('&', $flags));
    }

    function render($mode, Doku_Renderer $renderer, $data) {
        global $ID;

        if ( $mode == 'xhtml' ) {
            list($page, $flags) = $data;
            if ( !is_Array($flags) ) {
                $flags = array($flags);
            }
            
            $ins = p_cached_instructions(wikiFN($page));
            $renderer->doc .= p_render($mode, $ins, $myINFO);
        }
    }

    /**
     * Get a section including its subsections
     */
    function _getNSFiles($ns) {
        global $conf;
        
        $page = array();
        $dir = utf8_encodeFN(str_replace(':', '/', $ns));
        $data = array();
        require_once (DOKU_INC.'inc/search.php');
        $opts['skipacl'] = 0; // no ACL skipping for XMLRPC
        
        $data = array();
        search($data, $conf['datadir'], 'search_allpages', $opts, $dir);
        foreach ( $data as $dat ) {
            $page[] = $dat['id'];
        }
        
        return $page;
    }
}
// vim:ts=4:sw=4:et:enc=utf-8:
