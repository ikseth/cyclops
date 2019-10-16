<?php
/**
 * DokuWiki Syntax Plugin Mp3Play
 *
 * Shows an arrow image which links to the top of the page.
 * The image can be defined via the configuration manager.
 *
 * Syntax: {{mp3play>soundfile.mp3}}
 * 
 * @license GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author  Michael Klier <chi@chimeric.de>
 */

// must be run within DokuWiki
if(!defined('DOKU_INC')) die();

if(!defined('DOKU_PLUGIN')) define('DOKU_PLUGIN',DOKU_INC.'lib/plugins/');
require_once(DOKU_PLUGIN.'syntax.php');

if(!defined('DOKU_LF')) define('DOKU_LF',"\n");
 
/**
 * All DokuWiki plugins to extend the parser/rendering mechanism
 * need to inherit from this class
 */
class syntax_plugin_mp3play extends DokuWiki_Syntax_Plugin {
 
    /**
     * Syntax Type
     *
     * Needs to return one of the mode types defined in $PARSER_MODES in parser.php
     */
    function getType()  { return 'substition'; }
    function getPType() { return 'block'; }
    function getSort()  { return 309; }

    /**
     * Connect pattern to lexer
     */
    function connectTo($mode) { $this->Lexer->addSpecialPattern('\{\{mp3play>.*?\}\}',$mode,'plugin_mp3play'); }
 
    /**
     * Handle the match
     */
    function handle($match, $state, $pos, &$handler){
        $match = substr($match, 10, -2);
        $data = array();
        if(file_exists(mediaFN($mp3))) {
            $data = array();
            $data['loop'] = 0;
            $data['autostart'] = 0;

            list($mp3, $params) = explode('?', $match);
            $data['mp3'] = $mp3;

            $params = explode('&', $params);
            if($params) {
                foreach($params as $param) {
                    switch($param) {
                        case 'loop':
                            $data['loop'] = 1;
                            break;
                        case 'autostart':
                            $data['autostart'] = 1;
                            break;
                    }
                }
            }

            return $data;

        } else {
            return array();
        }
    }
 
    /**
     * Create output
     */
    function render($mode, &$renderer, $data) {
        global $ID;

        if(empty($data['mp3'])) return;

        if($mode == 'xhtml') {
            $renderer->info['cache'] = false;

            $params = '';
            $color_cfg = DOKU_PLUGIN . 'mp3play/colors.conf';

            if(@file_exists($color_cfg)) {

                $colors = array();
                $lines = @file($color_cfg);

                foreach($lines as $line) {
                    $line = preg_replace("/\ *#.*$/", '', $line);
                    $line = trim($line);
                    if(empty($line)) continue;
                    list($key, $color) = explode('=', $line);
                    $colors[trim($key)] = trim($color);
                }

                if(!empty($colors)) {
                    foreach($colors as $key => $color) {
                        $params .= $key . '=0x' . $color . '&amp;';
                    }
                }
            }

            $params .= ($data['loop']) ? 'loop=yes&amp;' : 'loop=no&amp;';
            $params .= ($data['autostart']) ? 'autostart=yes&amp;' : 'autostart=no&amp;';

            $renderer->doc .= '<div class="plugin_mp3play">' . DOKU_LF;
            $renderer->doc .= '  <object type="application/x-shockwave-flash" data="' . DOKU_URL . 'lib/plugins/mp3play/player.swf" class="plugin_mp3play" height="24" width="290">' . DOKU_LF;
            $renderer->doc .= '    <param name="movie" value="' . DOKU_URL . 'lib/plugins/mp3play/player.swf" />' . DOKU_LF;
            $renderer->doc .= '    <param name="FlashVars" value="' . $params . 'soundFile=' . DOKU_URL . '/lib/exe/fetch.php?media=' . $data['mp3'] . '" />' . DOKU_LF;
            $renderer->doc .= '    <param name="quality" value="high" />' . DOKU_LF;
            $renderer->doc .= '    <param name="menu" value="false" />' . DOKU_LF;
            $renderer->doc .= '    <param name="wmode" value="transparent" />' . DOKU_LF;
            $renderer->doc .= '  </object>' . DOKU_LF;
            $renderer->doc .= '</div>' . DOKU_LF;

        }
    }
}
// vim:ts=4:sw=4:et:enc=utf-8:
