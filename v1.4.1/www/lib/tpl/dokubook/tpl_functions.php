<?php
/**
 * Template functions for DokuBook template
 * 
 * @license:    GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author:     Michael Klier <chi@chimeric.de>
 */
// must be run within DokuWiki
if(!defined('DOKU_INC')) die();
if(!defined('DOKU_LF')) define('DOKU_LF', "\n");

// load language files
require_once(DOKU_TPLINC.'lang/en/lang.php');
if(@file_exists(DOKU_TPLINC.'lang/'.$conf['lang'].'/lang.php')) {
    require_once(DOKU_TPLINC.'lang/'.$conf['lang'].'/lang.php');
}

function html_list_index_navigation($item){
    global $ID;
    $ret = '';
    $base = ':'.$item['id'];
    $base = substr($base,strrpos($base,':')+1);
    if($item['type']=='d'){
        $ret .= '<a href="'.wl($item['id']).'/" class="idx_dir"><strong>';
        $ret .= $base;
        $ret .= '</strong></a>';
    }else{
        $ret .= html_wikilink(':'.$item['id']);
    }
    return $ret;
}


/**
 * checks if a file called logo.png or logo.jpg exists
 * and uses it as logo, uses the dokuwiki logo by default
 *
 * @author Michael Klier <chi@chimeric.de>
 */
function dokubook_tpl_logo() {
    global $conf;

    $out = '';

    switch(true) {
        case(tpl_getConf('logo')):
            $logo = tpl_getConf('logo');
            // check if configured logo is a media file
            if(file_exists(mediaFN($logo))) {
                $logo = ml($logo, array('w' => 128));
            }
            break;
        case(@file_exists(tpl_incdir().'images/logo.jpg')):
            $logo = tpl_basedir().'images/logo.jpg';
            break;
        case(@file_exists(tpl_incdir().'images/logo.jpeg')):
            $logo = tpl_basedir().'images/logo.jpeg';
            break;
        case(@file_exists(tpl_incdir().'images/logo.png')):
            $logo = tpl_basedir().'images/logo.png';
            break;
        default:
            $logo = tpl_basedir().'images/dokuwiki-128.png';
            break;
    }

    $out .= '<a href="' . DOKU_BASE . '">';
		if( $logo ) {
				$out .= '  <img class="logo" src="' . $logo . '" alt="' . $conf['title'] . '" />' . DOKU_LF;
		}
		$out .= '</a>' . DOKU_LF;

    print ($out);
}

/**
 * generates the sidebar contents
 *
 * @author Michael Klier <chi@chimeric.de>
 */
function dokubook_tpl_sidebar() {
    global $lang;
    global $ID;
    global $INFO;

    $svID  = cleanID($ID);
    $navpn = tpl_getConf('sb_pagename');
    $path  = explode(':',$svID);
    $found = false;
    $sb    = '';

    if(tpl_getConf('closedwiki') && empty($INFO['userinfo'])) {
        print '<span class="sb_label">' . $lang['toolbox'] . '</span>' . DOKU_LF;
        print '<aside id="toolbox" class="sidebar_box">' . DOKU_LF;
        tpl_actionlink('login');
        print '</aside>' . DOKU_LF;
        return;
    }

    // main navigation
    print '<span class="sb_label">' . $lang['navigation'] . '</span>' . DOKU_LF;
    print '<aside id="navigation" class="sidebar_box">' . DOKU_LF;

    while(!$found && count($path) > 0) {
        $sb = implode(':', $path) . ':' . $navpn;
        $found =  @file_exists(wikiFN($sb));
        array_pop($path);
    }

    if(!$found && @file_exists(wikiFN($navpn))) $sb = $navpn;

    if(@file_exists(wikiFN($sb)) && auth_quickaclcheck($sb) >= AUTH_READ) {
        print p_dokubook_xhtml($sb);
    } else {
        print p_index_xhtml(cleanID($svID));
    }

    print '</aside>' . DOKU_LF;

    // generate the searchbox
    print '<span class="sb_label">' . strtolower($lang['btn_search']) . '</span>' . DOKU_LF;
    print '<div id="search">' . DOKU_LF;
    tpl_searchform();
    print '</div>' . DOKU_LF;

    // generate the toolbox
    print '<span class="sb_label">' . $lang['toolbox'] . '</span>' . DOKU_LF;
    print '<aside id="toolbox" class="sidebar_box">' . DOKU_LF;
    tpl_actionlink('admin');
    tpl_actionlink('index');
    tpl_actionlink('media');
    tpl_actionlink('recent');
    tpl_actionlink('backlink');
    tpl_actionlink('profile');
    tpl_actionlink('login');
    print '</aside>' . DOKU_LF;

    // restore ID just in case
    $ID = $svID;
}

/**
 * prints a custom page footer
 *
 * @author Michael Klier <chi@chimeric.de>
 */
function dokubook_tpl_footer() {
    global $ID;

    $svID  = $ID;
    $ftpn  = tpl_getConf('ft_pagename');
    $path  = explode(':',$svID);
    $found = false;
    $ft    = '';

    while(!$found && count($path) > 0) {
        $ft = implode(':', $path) . ':' . $ftpn;
        $found =  @file_exists(wikiFN($ft));
        array_pop($path);
    }

    if(!$found && @file_exists(wikiFN($ftpn))) $ft = $ftpn;

    if(@file_exists(wikiFN($ft)) && auth_quickaclcheck($ft) >= AUTH_READ) {
        print '<div id="footer">' . DOKU_LF;
        print p_dokubook_xhtml($ft);
        print '</div>' . DOKU_LF;
    }

    // restore ID just in case
    $ID = $svID;
}

/**
 * removes the TOC of the sidebar-pages and shows 
 * a edit-button if user has enough rights
 * 
 * @author Michael Klier <chi@chimeric.de>
 */
function p_dokubook_xhtml($wp) {
    $data = p_wiki_xhtml($wp,'',false);
    if(auth_quickaclcheck($wp) >= AUTH_EDIT) {
        $data .= '<div class="secedit">' . html_btn('secedit',$wp,'',array('do'=>'edit','rev'=>'','post')) . '</div>';
    }
    // strip TOC
    $data = preg_replace('/<div class="toc">.*?(<\/div>\n<\/div>)/s', '', $data);
    // replace headline ids for XHTML compliance
    $data = preg_replace('/(<h.*?><a.*?name=")(.*?)(".*?id=")(.*?)(">.*?<\/a><\/h.*?>)/','\1sb_\2\3sb_\4\5', $data);
    return ($data);
}

/**
 * Renders the Index
 *
 * copy of html_index located in /inc/html.php
 *
 * @author Andreas Gohr <andi@splitbrain.org>
 * @author Michael Klier <chi@chimeric.de>
 */
function p_index_xhtml($ns) {
  require_once(DOKU_INC.'inc/search.php');
  global $conf;
  global $ID;
  $dir = $conf['datadir'];
  $ns  = cleanID($ns);
  #fixme use appropriate function
  if(empty($ns)){
    $ns = dirname(str_replace(':','/',$ID));
    if($ns == '.') $ns ='';
  }
  $ns  = utf8_encodeFN(str_replace(':','/',$ns));

  // only extract headline
  preg_match('/<h1>.*?<\/h1>/', p_locale_xhtml('index'), $match);
  print $match[0];

  $data = array();
  search($data,$conf['datadir'],'search_index',array('ns' => $ns));

  print '<div id="sb__index__tree">' . DOKU_LF;
  print html_buildlist($data,'idx','html_list_index','html_li_index');
  print '</div>' . DOKU_LF;
}

// vim:ts=2:sw=2:enc=utf-8:
