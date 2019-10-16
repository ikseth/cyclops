<?php
/**
 * Emphasis Plugin: Enables text highlighting with
 *                  ::text::, :::text:::, ::::text::::
 *
 * @license    GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author     Stefan Hechenberger <foss@stefanix.net>
 * @author     Gerrit Uitslag <klapinklapin@gmail.com>
 */

// must be run within Dokuwiki
if(!defined('DOKU_INC')) die();

/**
 * All DokuWiki plugins to extend the parser/rendering mechanism
 * need to inherit from this class
 */
class syntax_plugin_emphasis_font extends DokuWiki_Syntax_Plugin {
    /** @var $odt_style_name */
    protected $odt_style_name;

    /** @var array $colorlist */
    var $colorlist = array(
        'color'             => array(),
        'background-color'  => array()
    );

    /**
     * @return string Syntax Mode type
     */
    function getType() {
        return 'formatting';
    }

    /**
     * @return int Sort order - Low numbers go before high numbers
     */
    function getSort() {
        return 136;
    }

    /**
     * @return array allowed Mode Types
     */
    function getAllowedTypes() {
        return array('formatting', 'substition', 'disabled');
    }

    /**
     * @return string normal|block|stack - how this plugin is handled regarding paragraphs
     */
    function getPType() {
        return 'normal';
    }

    /**
     * Connect lookup pattern to lexer.
     *
     * @param string $mode Parser mode
     */
    function connectTo($mode) {
        $this->Lexer->addEntryPattern(':{2,}(?=.*?:{2,})', $mode, 'plugin_emphasis_font');
    }

    function postConnect() {
        $this->Lexer->addExitPattern(':{2,}', 'plugin_emphasis_font');
    }

    /**
     * Handle matches of the Emphasis syntax
     *
     * @param string          $match The match of the syntax
     * @param int             $state The state of the handler
     * @param int             $pos The position in the document
     * @param Doku_Handler    $handler The handler
     * @return array Data for the renderer
     */
    function handle($match, $state, $pos, Doku_Handler $handler) {
        $data['match'] = $match;

        switch($state) {
            case DOKU_LEXER_ENTER:
                $colortype = ($match{0} == ':' ? 'color':'background-color');

                //fill colorlist from config
                if(empty($this->colorlist[$colortype])) {
                    $colors = explode(',', $this->getConf($colortype.'s'));
                    foreach($colors as $color) {
                        //clean up colorcodes
                        $color = trim($color);
                        if($color{0} == '#') $color = substr($color, 1);
                        if(preg_match('/[^A-Fa-f0-9]/', $color)) continue;
                        //length 3 or 6 chars
                        $clen = strlen($color);
                        if(!($clen == 3 || $clen == 6)) continue;
                        $this->colorlist[$colortype][] = '#'.$color;
                    }
                }

                //degree of emphasis
                $maxdegree = count($this->colorlist[$colortype]);
                $data['degree'] = strlen($match) - 1;
                if($data['degree'] > $maxdegree) {
                    $data['degree'] = $maxdegree;
                }

                //color lookup
                $data['color'] = $this->colorlist[$colortype][$data['degree'] - 1];
                $data['colortype'] = $colortype;

                return array($state, $data);

            case DOKU_LEXER_UNMATCHED:
                // normal text
                $handler->_addCall('cdata', array($match), $pos);
                return false;

            case DOKU_LEXER_EXIT:
                return array($state, $data);
        }

        return array();
    }

    /**
     * Render xhtml output, latex output or metadata
     *
     * @param string         $mode      Renderer mode (supported modes: xhtml, latex and metadata)
     * @param Doku_Renderer  $renderer  The renderer
     * @param array          $hdata    The data from the handler function
     * @return bool If rendering was successful.
     */
    function render($mode, Doku_Renderer $renderer, $hdata) {
        list($state, $data) = $hdata;

        if($mode == 'xhtml') {
            /** @var Doku_Renderer_xhtml $renderer */
            switch($state) {
                case DOKU_LEXER_ENTER:
                    $renderer->doc .= '<span class="plugin_emphasis" style="'.$data['colortype'].': '.$data['color'].';">';
                    return true;

                case DOKU_LEXER_EXIT:
                    $renderer->doc .= '</span>';
                    return true;
            }
        }
        if($mode == 'odt'){
            /** @var renderer_plugin_odt $renderer */
            switch ($state) {
                case DOKU_LEXER_ENTER:
                    if (!class_exists('ODTDocument')) {
                        $renderer->_odtSpanOpenUseCSSStyle ($data['colortype'].': '.$data['color'].';font-weight:bold;');
                    } else {
                        $renderer->_odtSpanOpenUseCSS (NULL, 'class="plugin_emphasis" style="'.$data['colortype'].': '.$data['color'].';"');
                    }
                    return true;

                case DOKU_LEXER_EXIT:
                    // Close the span.
                    $renderer->_odtSpanClose();
                    return true;
            }
        }
        return false;
    }

}
