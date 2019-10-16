<?php 
// added by dwsimple	{
	if (isset($DOKU_TPL)==FALSE) $DOKU_TPL = DOKU_TPL; if (isset($DOKU_TPLINC)==FALSE) $DOKU_TPLINC = DOKU_TPLINC;
// }
?>
<?php
/**
 * dwsimple is a Dietrich Wittenberg SIMPLE Layout Engine 
 * based on DokuWiki Default Template
 *
 * This is the template you need to change for the overall look
 * of DokuWiki.
 *
 * @link   http://wiki.splitbrain.org/wiki:tpl:templates
 * @author Dietrich Wittenberg <info@wwwittenberg.de>
 * The addings of dwsimple Template to Default Template 
 * are marked as remark with:
 * 	added by dwsimple {
 *		some adding 
 *	}
 */

// must be run from within DokuWiki
if (!defined('DOKU_INC')) die();

// added by dwsimple {
// include functions that provides css-layout functionality
@require_once(dirname(__FILE__).'/dwsimple/simple.php');
// }

?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="<?php echo $conf['lang']?>"
 lang="<?php echo $conf['lang']?>" dir="<?php echo $lang['direction']?>">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />

  <title>
    <?php tpl_pagetitle()?>
    [<?php echo strip_tags($conf['title'])?>]
  </title>

  <?php tpl_metaheaders()?>

  <link rel="shortcut icon" href="<?php echo DOKU_TPL?>images/favicon.ico" />

  <?php /*old includehook*/ @include(dirname(__FILE__).'/meta.html')?>

	<!-- added by dwsimple { -->
	<link href="<?php echo $DOKU_TPL;?>dwsimple/cssc.php" rel="stylesheet" media="screen" type="text/css">
	<link href="<?php echo $DOKU_TPL;?>dwsimple/cssc.css" rel="stylesheet" media="screen" type="text/css">
	<!--[if lte IE 7]>
		<link href="<?php echo $DOKU_TPL;?>dwsimple/ie5.css" rel="stylesheet" media="screen" type="text/css">	
	<![endif]-->
	<!-- } -->

</head>

<body>
<?php /*old includehook*/ @include(dirname(__FILE__).'/topheader.html')?>
<div class="dokuwiki">
  <?php html_msgarea()?>

	<!-- added by dwsimple { -->
	<div id="head">
	<!-- } -->
  <div class="stylehead">

    <div class="header">
      <div class="pagename">
        [[<?php tpl_link(wl($ID,'do=backlink'),tpl_pagetitle($ID,true))?>]]
      </div>
      <div class="logo">
        <?php tpl_link(wl(),$conf['title'],'name="dokuwiki__top" id="dokuwiki__top" accesskey="h" title="[ALT+H]"')?>
      </div>

      <div class="clearer"></div>
    </div>

    <?php /*old includehook*/ @include(dirname(__FILE__).'/header.html')?>

    <div class="bar" id="bar__top">
      <div class="bar-left" id="bar__topleft">
        <?php tpl_button('edit')?>
        <?php tpl_button('history')?>
      </div>

      <div class="bar-right" id="bar__topright">
        <?php tpl_button('recent')?>
        <?php tpl_searchform()?>&nbsp;
      </div>

      <div class="clearer"></div>
    </div>

    <?php if($conf['breadcrumbs']){?>
    <div class="breadcrumbs">
      <?php tpl_breadcrumbs()?>
      <?php //tpl_youarehere() //(some people prefer this)?>
    </div>
    <?php }?>

    <?php if($conf['youarehere']){?>
    <div class="breadcrumbs">
      <?php tpl_youarehere() ?>
    </div>
    <?php }?>

  </div>
  <?php flush()?>
 	<!-- added by dwsimple { -->
  </div>
  <!-- } -->

  <?php /*old includehook*/ @include(dirname(__FILE__).'/pageheader.html')?>

	<!-- added by dwsimple { -->
	<div id="page">
	<div id="inhalt">
	<!-- } -->
  <div class="page">
    <!-- wikipage start -->
    <?php tpl_content()?>
    <!-- wikipage stop -->
  </div>
	<!-- added by dwsimple { -->
  </div>
  </div>
  <!-- } -->

  <div class="clearer">&nbsp;</div>

  <?php flush()?>

	<!-- added by dwsimple { -->
	<div id="foot">
	<!-- } -->
  <div class="stylefoot">

    <div class="meta">
      <div class="user">
        <?php tpl_userinfo()?>
      </div>
      <div class="doc">
        <?php tpl_pageinfo()?>
      </div>
    </div>

   <?php /*old includehook*/ @include(dirname(__FILE__).'/pagefooter.html')?>

    <div class="bar" id="bar__bottom">
      <div class="bar-left" id="bar__bottomleft">
        <?php tpl_button('edit')?>
        <?php tpl_button('history')?>
        <?php tpl_button('revert')?>
      </div>
      <div class="bar-right" id="bar__bottomright">
        <?php tpl_button('subscription')?>
        <?php tpl_button('admin')?>
        <?php tpl_button('profile')?>
        <?php tpl_button('login')?>
        <?php tpl_button('index')?>
        <?php tpl_button('top')?>&nbsp;
      </div>
      <div class="clearer"></div>
    </div>

  </div>
	<!-- added by dwsimple { -->
  </div>
  <!-- } -->

</div>

<!-- added by dwsimple { -->
<div id="footer">
<!-- } -->
<?php /*old includehook*/ @include(dirname(__FILE__).'/footer.html')?>
<!-- added by dwsimple { -->
</div>
<!-- } -->

<div class="no"><?php /* provide DokuWiki housekeeping, required in all templates */ tpl_indexerWebBug()?></div>
</body>
</html>
