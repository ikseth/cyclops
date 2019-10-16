<?php

/**
 * German language (formal, "Sie") for the Config Manager
 *
 * If your language is not/only partially translated or you found an error/typo,
 * have a look at the following files:
 * - /lib/tpl/mnml-blog/lang/<your lang>/lang.php
 * - /lib/tpl/mnml-blog/lang/<your lang>/settings.php
 * If they are not existing, copy and translate the English ones.
 *
 * Don't forget to mail your translation to ARSAVA <dokuwiki@dev.arsava.com>.
 * Thanks! :-D
 *
 *
 * LICENSE: This file is open source software (OSS) and may be copied under
 *          certain conditions. See COPYING file for details or try to contact
 *          the author(s) of this file in doubt.
 *
 * @license GPLv2 (http://www.gnu.org/licenses/gpl2.html)
 * @author ARSAVA <dokuwiki@dev.arsava.com>
 * @link https://www.dokuwiki.org/template:mnml-blog
 * @link https://www.dokuwiki.org/config:lang
 * @link https://www.dokuwiki.org/devel:configuration
 */


//check if we are running within the DokuWiki environment
if (!defined("DOKU_INC")){
    die();
}

//header navigation
$lang["mnmlblog_headernav"]          = "Header-Navigation anzeigen?";
$lang["mnmlblog_headernav_location"] = "Falls ja, folgende wiki-Seite als Header-Navigation verwenden:";

//sidebar navigation
$lang["mnmlblog_sidebarnav"]          = "Sidebar-Navigation anzeigen?";
$lang["mnmlblog_sidebarnav_location"] = "Falls ja, folgende wiki-Seite als Sidebar-Navigation verwenden:";

//custom copyright notice
$lang["mnmlblog_copyright"]          = "Copyright-Hinweis einblenden?";
$lang["mnmlblog_copyright_default"]  = "Falls ja, Standard-Copyright-Hinweis nutzen?";
$lang["mnmlblog_copyright_location"] = "Falls nicht den Standard-Copyright-Hinweis, folgende wiki-Seite als Copyright-Hinweis verwenden:";

//search form
$lang["mnmlblog_search"]     = "Suchformular anzeigen?";
$lang["mnmlblog_search_pos"] = "Falls ja, Suchformularposition";

//qr code box
$lang["mnmlblog_qrcodebox"] = "Box mit QR-Code der aktuellen Wiki-Seiten-URL anzeigen (für einfache Übertragung der URL auf Mobiltelefone)?";

//other stuff
$lang["mnmlblog_newpostform_location"]   = "Folgende wiki-Seite für '&lt;blog newform&gt;'-Formular verwenden:";
$lang["mnmlblog_hideadminlinksfromanon"] = "Alle Links zu Admin- und Benutzerfunktionen verstecken, falls der Client kein authentifizierter Benutzer ist? Bitte beachten: Das Login-Formular muss manuell aufgerufen werden, falls diese Option aktiviert ist (Tipp: '".DOKU_URL.DOKU_SCRIPT."?do=login').";
$lang["mnmlblog_loaduserjs"]             = "Datei 'mnml-blog/user/user.js' laden?";

