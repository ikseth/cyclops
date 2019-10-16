<?php
/**
 * Tools Plugin
 *
 * Enables/disables tools toolbar.
 *
 * @license GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author  Luigi Micco <l.micco@tiscali.it>
 */

// must be run within Dokuwiki
if(!defined('DOKU_INC')) die();

if(!defined('DOKU_PLUGIN')) define('DOKU_PLUGIN',DOKU_INC.'lib/plugins/');
require_once(DOKU_PLUGIN.'syntax.php');

/**
 * All DokuWiki plugins to extend the parser/rendering mechanism
 * need to inherit from this class
 */
class syntax_plugin_tools_tools extends DokuWiki_Syntax_Plugin {

  /**
   * return some info
   */
  function getInfo(){
    return array (
      'author' => 'Luigi Micco',
      'email' => 'l.micco@tiscali.it',
      'date' => '2010-03-30',
      'name' => 'Tools plugin (syntax component)',
      'desc' => 'Insert toolbar with tools on pages<br />Allows to override config options for a certain pages<br />Syntax: ~~TOOLS:(off|top|bottom|both)~~.',
      'url' => 'http://www.dokuwiki.org/plugin:tools',
    );
  }
    
  function getType(){ return 'substition'; }
  function getPType(){ return 'block'; }
  function getSort(){ return 110; }

  /**
   * Connect pattern to lexer
   */
  function connectTo($mode){
    if ($mode == 'base'){
      $this->Lexer->addSpecialPattern('~~TOOLS:(?:o(?:ff|n)|top|bot(?:tom|h))~~', $mode, 'plugin_tools_tools');
    }
  }
  /**
   * Handle the match
   */
  function handle($match, $state, $pos, &$handler){
    return preg_replace("/[^:]+:(\\w+).+/","\\1",$match);
  }  
 
  /**
   *  Render output
   */
  function render($mode, &$renderer, $data) {
      switch ($mode) {
          case 'metadata' :
              /*
              *  mark metadata with found value
              */
              $renderer->meta['tools'] = $data;
              return true;
              break;
    }
    return false;
  }


}
