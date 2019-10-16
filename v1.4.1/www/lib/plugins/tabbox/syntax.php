<?php
/**
 * DokuWiki Plugin tabbox (Syntax Component)
 *
 * @license GPL 2 http://www.gnu.org/licenses/gpl-2.0.html
 * @author  Andreas Gohr <dokuwiki@cosmocode.de>
 */

// must be run within Dokuwiki
if(!defined('DOKU_INC')) die();

class syntax_plugin_tabbox extends DokuWiki_Syntax_Plugin {

    protected $tabs         = array();
    protected $tabids       = array();
    protected $intab        = false;
    protected $original_doc = '';

    function accepts($mode) {
        if($mode == 'plugin_tabbox') return true;
        return parent::accepts($mode);
    }

    /**
     * @return string Syntax mode type
     */
    public function getType() {
        return 'formatting';
    }

    /**
     * @return string Paragraph type
     */
    public function getPType() {
        return 'stack';
    }

    /**
     * @return int Sort order - Low numbers go before high numbers
     */
    public function getSort() {
        return 190;
    }

    /**
     * @return array Things that may be inside the syntax
     */
    function getAllowedTypes() {
        return array('container', 'formatting', 'substition', 'protected', 'disabled', 'paragraphs');
    }

    /**
     * Connect lookup pattern to lexer.
     *
     * @param string $mode Parser mode
     */
    public function connectTo($mode) {
        $this->Lexer->addEntryPattern('<tabbox.*?>(?=.*?</tabbox>)', $mode, 'plugin_tabbox');
        $this->Lexer->addSpecialPattern('<tabbox.*?>(?=.*?</tabbox>)', 'plugin_tabbox', 'plugin_tabbox');
    }

    public function postConnect() {

        $this->Lexer->addExitPattern('</tabbox>', 'plugin_tabbox');
    }

    /**
     * Handle matches of the tabbox syntax
     *
     * @param string $match The match of the syntax
     * @param int $state The state of the handler
     * @param int $pos The position in the document
     * @param Doku_Handler $handler The handler
     * @return array Data for the renderer
     */
    public function handle($match, $state, $pos, Doku_Handler $handler) {
        // we treat intermediate matches like entries in rendering
        if($state == DOKU_LEXER_SPECIAL) $state = DOKU_LEXER_ENTER;

        return array($state, $match, $pos);
    }

    /**
     * Render xhtml output or metadata
     *
     * @param string $mode Renderer mode (supported modes: xhtml)
     * @param Doku_Renderer $renderer The renderer
     * @param array $data The data from the handler() function
     * @return bool If rendering was successful.
     */
    public function render($mode, Doku_Renderer $renderer, $data) {
        if($mode != 'xhtml') return false;

        list($state, $match, $pos) = $data;

        switch($state) {
            case DOKU_LEXER_ENTER:
                if(!$this->intab) {
                    // this is the first tab
                    $this->_openBox($renderer);
                } else {
                    // close last tab
                    $this->_closeTab($renderer, $pos - 1);
                }
                // open new tab
                $this->_openTab($renderer, substr($match, 7, -1), $pos + strlen($match) + 1 );
                break;
            case DOKU_LEXER_EXIT:
                if($this->intab) {
                    // close last tab
                    $this->_closeTab($renderer, $pos - 1);
                }
                $this->_closeBox($renderer);
                break;
            default:
                // just render as is
                $renderer->cdata($match);
        }

        return true;
    }



    /**
     * Open a new tab with the given name
     *
     * @param Doku_Renderer_xhtml $R
     * @param string $name
     * @param int $pos Byte position of start of tab content
     */
    protected function _openTab(Doku_Renderer_xhtml $R, $name, $pos) {
        $name  = trim($name);
        $tabid = 'tab__' . sectionID($name, $this->tabids);
        // use one smaller headline than current section for the tabs
        $level = $this->_getProtected($R, 'lastlevel') + 1;
        if($level > 5) $level = 5;

        // write the header
        $R->doc .= '<div class="tabboxtab" id="tab_'.$tabid.'">'.DOKU_LF;
        if (defined('SEC_EDIT_PATTERN')) { 
            // for DokuWiki Greebo and more recent versions
            $R->doc .= DOKU_LF . '<h' . $level . ' class="hl '.  $R->startSectionEdit($pos, array('target' => 'section', 'name' => $name)) . '" id="' . $tabid . '">';
        } else {
            $R->doc .= DOKU_LF . '<h' . $level . ' class="hl '.  $R->startSectionEdit($pos, 'section', $name)  . '" id="' . $tabid . '">';
        }
        $R->doc .= $R->_xmlEntities($name);
        $R->doc .= "</h$level>" . DOKU_LF;

        $this->intab = true;
    }

    /**
     * Close the current tab
     *
     * @param Doku_Renderer_xhtml $R
     * @param int $pos Byte position of end of tab content
     */
    protected function _closeTab(Doku_Renderer_xhtml $R, $pos) {
        $R->finishSectionEdit($pos);
        $R->doc .= DOKU_LF.'</div>'.DOKU_LF;
        $this->intab = false;
    }

    /**
     * Open a new tab box
     *
     * @param Doku_Renderer_xhtml $R
     */
    protected function _openBox(Doku_Renderer_xhtml $R) {
        $R->doc .= '<div class="plugin_tabbox">' . DOKU_LF;

    }

    /**
     * Close the tab box
     *
     * @param Doku_Renderer_xhtml $R
     */
    protected function _closeBox(Doku_Renderer_xhtml $R) {
        $R->doc .= '</div>' . DOKU_LF;
    }

    /**
     * Get the value of a protected member
     *
     * @author Jan Turoň
     * @link http://stackoverflow.com/a/27754169/172068
     * @param $obj
     * @param $name
     * @return mixed
     */
    protected function _getProtected($obj, $name) {
        $array  = (array) $obj;
        $prefix = chr(0) . '*' . chr(0);
        return $array[$prefix . $name];
    }

}

// vim:ts=4:sw=4:et:
