<?php
/**
 * Emphasis Plugin: Enables text highlighting with
 *                  ::text::, :::text:::, ::::text::::
 *
 * @license    GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author     Gerrit Uitslag <klapinklapin@gmail.com>
 */

// must be run within Dokuwiki
if(!defined('DOKU_INC')) die();
require_once(dirname(__FILE__).'/font.php');

/**
 * All DokuWiki plugins to extend the parser/rendering mechanism
 * need to inherit from this class
 */
class syntax_plugin_emphasis_background extends syntax_plugin_emphasis_font {

     /**
     * Connect lookup pattern to lexer.
     *
     * @param string $mode Parser mode
     */
    function connectTo($mode) {
        $this->Lexer->addEntryPattern(';{2,}(?=.*?;{2,})', $mode, 'plugin_emphasis_background');
    }

    function postConnect() {
        $this->Lexer->addExitPattern(';{2,}', 'plugin_emphasis_background');
    }


}
