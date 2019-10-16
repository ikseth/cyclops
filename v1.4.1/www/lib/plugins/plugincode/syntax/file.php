<?php
/**
 * File Plugin: replaces Dokuwiki's own file syntax
 *
 * Syntax:     <file |title>
 *   title     (optional) all text after '|' will be rendered above the main code text with a
 *             different style.
 *
 * if no title is provided will render as native dokuwiki code syntax mode, e.g.
 *   <pre class='file'> ... </pre>
 *
 * if title is provide will render as follows
 *   <div class='file'>
 *     <p>{title}</p>
 *     <pre class='file'> ... </pre>
 *   </div>
 *
 * @license    GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author     Christopher Smith <chris@jalakai.co.uk>
 */

if(!defined('DOKU_INC')) define('DOKU_INC',realpath(dirname(__FILE__).'/../../').'/');
if(!defined('DOKU_PLUGIN')) define('DOKU_PLUGIN',DOKU_INC.'lib/plugins/');
require_once(DOKU_PLUGIN.'syntax.php');

/**
 * All DokuWiki plugins to extend the parser/rendering mechanism
 * need to inherit from this class
 */
class syntax_plugin_code_file extends DokuWiki_Syntax_Plugin {

    var $syntax = "";

    /**
     * return some info
     */
    function getInfo(){
      return array(
        'author' => 'Christopher Smith',
        'email'  => 'chris@jalakai.co.uk',
        'date'   => '2008-08-13',
        'name'   => '<file> replacement plugin',
        'desc'   => 'Replacement for Dokuwiki\'s own <file> handler, adds a title to the box.
                     Syntax: <file|title>, title is optional and does not support any dokuwiki markup.',
        'url'    => 'http://www.dokuwiki.org/plugin:code',
      );
    }

    function getType(){ return 'protected';}
    function getPType(){ return 'block'; }

    // must return a number lower than returned by native 'file' mode (210)
    function getSort(){ return 194; }

    /**
     * Connect pattern to lexer
     */
    function connectTo($mode) {
      $this->Lexer->addEntryPattern('<file(?=[^\r\n]*?>.*?</file>)',$mode,'plugin_code_file');
    }

    function postConnect() {
    $this->Lexer->addExitPattern('</file>', 'plugin_code_file');
    }

    /**
     * Handle the match
     */
    function handle($match, $state, $pos, &$handler){

        switch ($state) {
            case DOKU_LEXER_ENTER:
                $this->syntax = substr($match, 1);
                return false;

            case DOKU_LEXER_UNMATCHED:
                // will include everything from <code ... to ... </code >
                // e.g. ... [lang] [|title] > [content]
                list($attr, $content) = preg_split('/>/u',$match,2);
                list($lang, $title) = preg_split('/\|/u',$attr,2);

                if ($this->syntax == 'code') {
                    $lang = trim($lang);
                    if ($lang == 'html') $lang = 'html4strict';
                    if (!$lang) $lang = NULL;
                } else {
                    $lang = NULL;
                }

                return array($this->syntax, $lang, trim($title), $content);
        }
        return false;
    }

    /**
     * Create output
     */
    function render($mode, &$renderer, $data) {

      if (count($data) == 4) {
        list($syntax, $lang, $title, $content) = $data;

        if($mode == 'xhtml'){
            if ($title) $renderer->doc .= "<div class='$syntax'><p>".$renderer->_xmlEntities($title)."</p>";
            if ($syntax == 'code') $renderer->code($content, $lang); else $renderer->file($content);
            if ($title) $renderer->doc .= "</div>";
        } else {
            if ($syntax == 'code') $renderer->code($content, $lang); else $renderer->file($content);
        }

        return true;
      }
      return false;
    }
}

//Setup VIM: ex: et ts=4 enc=utf-8 :
