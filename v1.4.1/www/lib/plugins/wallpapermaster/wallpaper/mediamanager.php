<?php
/**
 * DokuWiki Wallpaper Template
 *
 * This is the template for the media manager popup
 *
 * @link   http://dokuwiki.org/templates
 * @author Andreas Gohr <andi@splitbrain.org>
 * @author Klaus Vormweg <klaus.vormweg@gmx.de>
 */

// must be run from within DokuWiki
if (!defined('DOKU_INC')) die();
echo '<!DOCTYPE html>
<html lang="', $conf['lang'], '" dir="ltr">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>',hsc($lang['mediaselect']), ' [', strip_tags($conf['title']), ']</title>
';
tpl_metaheaders();
echo '
  <link rel="shortcut icon" href="', DOKU_TPL, 'images/favicon.ico" />
</head>
<body>
<div id="media__manager" class="dokuwiki">
    <div id="media__left">
';
html_msgarea();
echo '        <h1>', hsc($lang['mediaselect']), '</h1>
';
/* keep the id! additional elements are inserted via JS here */
echo '        <div id="media__opts"></div>
';
tpl_mediaTree();
echo '    </div>
    <div id="media__right">
';
tpl_mediaContent();
echo '    </div>
</div>
</body>
</html>
';
?>
