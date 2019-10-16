<?php
  if(!defined('DOKU_INC')) die();
  if(!defined('DOKU_PLUGIN')) define('DOKU_PLUGIN',DOKU_INC.'lib/plugins/');
  require_once(DOKU_PLUGIN.'action.php');

  class action_plugin_legalnotice extends DokuWiki_Action_Plugin {

  function register(Doku_Event_Handler $controller) {
      $controller->register_hook('TPL_ACT_RENDER', 'AFTER',  $this, 'legalnotice');
    }

    function legalnotice(&$event, $param) {
	global $conf,$ACT;

	if(($ACT!='login') && ($ACT!='denied')) return;
	echo p_render('xhtml', p_get_instructions($this->getConf('text')), $info);
    }

  }
