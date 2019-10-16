<?php
/**
 *  Tools Action component
 *
 *  $Id: action.php 111 2008-12-25 19:33:15Z wingedfox $
 *  $HeadURL: https://svn.debugger.ru/repos/common/DokuWiki/BookmarkMe/tags/BookmarkMe.v0.8/action.php $
 *
 *  @lastmodified $Date: 2008-12-25 22:33:15 +0300 (???, 25 ??? 2008) $
 *  @license      LGPL 2 (http://www.gnu.org/licenses/lgpl.html)
 *  @author       Ilya Lebedev <ilya@lebedev.net>
 *  @version      $Rev: 111 $
 *  @copyright    (c) 2005-2007, Ilya Lebedev
 */

if(!defined('DOKU_INC')) die();

if(!defined('DOKU_PLUGIN')) define('DOKU_PLUGIN',DOKU_INC.'lib/plugins/');
require_once(DOKU_PLUGIN.'action.php');

class action_plugin_tools extends DokuWiki_Action_Plugin {

  /**
   *  Constants for controlling toolbar show
   */
  var $TOOLS_SHOW_OFF    = 0;
  var $TOOLS_SHOW_ON     = 1;  // equals to bottom, pre-0.7 compatible
  var $TOOLS_SHOW_BOTTOM = 1;
  var $TOOLS_SHOW_TOP    = 2;
  var $TOOLS_SHOW_BOTH   = 3;

  /**
   * return some info
   */
  function getInfo(){
    return array (
      'author' => 'Luigi Micco',
      'email' => 'l.micco@tiscali.it',
      'date' => '2012-07-27',
      'name' => 'Tools plugin (action component)',
      'desc' => 'Insert toolbar with tools on pages<br />Allows to override config options for a certain pages<br />Syntax: ~~TOOLS:(off|top|bottom|both)~~.',
      'url' => 'http://www.dokuwiki.org/plugin:tools',
    );
  }

  
  /*
   * plugin should use this method to register its handlers with the dokuwiki's event controller
   */
  function register(&$controller) {
      $controller->register_hook('TPL_ACT_RENDER','AFTER',$this,'tools',array("show" => $this->TOOLS_SHOW_BOTTOM));
      $controller->register_hook('TPL_ACT_RENDER','BEFORE',$this,'tools',array("show" => $this->TOOLS_SHOW_TOP));
  }
  /**
   *  Prints tools icons, if allowed
   *
   *  @author Ilya Lebedev <ilya@lebedev.net>
   */
  function tools(&$event, $param) {
    global $ID;
    global $conf;

    if ($event->data != 'show') return; // nothing to do for us

    $show = $this->getConf('show_tools');

    //Check if tools is allowed
    $bm = p_get_metadata($ID,'tools');

    if (null !== $bm) {
        $bm = 'TOOLS_SHOW_'.strtoupper($bm);
        $bm = (int)$this->$bm;
        if (is_numeric($bm))
            $show = $bm;
    }

    if ( !($show & $this->TOOLS_SHOW_BOTTOM & $param['show'])
      && !($show & $this->TOOLS_SHOW_TOP & $param['show']))
        return;

    /*
    *  assume that page does not exists
    */
    $exists = false;
    $id = $ID;
    resolve_pageid('',$id,$exists);

    /*
    *  find skip pages
    */
    $sp = join("|",explode(",",preg_quote($this->getConf('skip_ids'))));
    
    if (!$exists || preg_match("/$sp/i",$ID)) 
        return;

    $be = explode(",",$this->getConf('tools'));

    $ip = dirname(__FILE__)."/img/";
    $iu = DOKU_URL."lib/plugins/tools/img/";
    $title = p_get_first_heading($ID);
    if (!$title) $title = $ID;

    $pml = wl($ID,'',true);

    $html = array('<ul class="tools">');

    $book_lng = htmlspecialchars($this->getLang('tools_title'));

    $tools = array(
        'print' => wl($ID, array("rev" =>(int)$rev, "mddo" => "print"), false, "&")
       ,'email' => wl($ID, array('rev' =>(int)$rev, 'do' => 'tellafriend'), false, '&')
       ,'odt' => wl($ID, array("rev" =>(int)$rev, "do" => "export_odt"), false, "&")
       ,'pdf' => wl($ID, array("rev" =>(int)$rev, "do" => "export_pdf"), false, "&")
       ,'csv' => wl($ID, array("rev" =>(int)$rev, "do" => "export_csv"), false, "&")
       ,'timeline' => wl($ID, array("rev" =>(int)$rev, "do" => "export_timeline"), false, "&")
       ,'bookcreator' => wl($ID, array("rev" =>(int)$rev, "do" => "addtobook"), false, "&")
    );

    foreach ($tools as $k=>$v) {
        $i = strtolower( str_replace( array("."," "),array("" ,"_"),$k)).".png";
        if (in_array($k,$be)) {
          $label = '';
          $image = '';        
          if (($this->getConf('show_link') == 0) || ($this->getConf('show_link') == 2)) {
            if (file_exists($ip.$i)) {
              list($w,$h) = @getimagesize($ip.$i);
              $image = "<img src='$iu$i' width='$w' height='$h' alt='".$this->getLang('tools_'.$k)."' title='".$this->getLang('tools_'.$k)."' />";
            }
          }
          if (($this->getConf('show_link') == 1) || ($this->getConf('show_link') == 2)) {
            $label = $this->getLang('tools_'.$k);
          }
          $html[] = "<li><a href='$v' >".$image.$label."</a></li>";
        }  
        
    }

    /*
    *  show header only if allowed in config
    */
    if ($this->getConf('show_header')) $html[] = '<li class="head">'.$this->getLang('tools').'</li>';

    $html[] = '</ul>';
    if (sizeof($html)>2) echo join("\n",$html);
  }
}
