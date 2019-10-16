<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="<?php echo $conf['lang']; ?>" lang="<?php echo $conf['lang']; ?>" dir="<?php echo $lang['direction']; ?>">
<head>
<title><?php echo $ID?> [<?php echo hsc($conf['title']); ?>]</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<?php tpl_metaheaders(); ?>
<link rel="shortcut icon" href="<?php echo DOKU_BASE; ?>lib/images/favicon.ico" />
<link rel="stylesheet" media="screen" type="text/css" href="<?php echo DOKU_TPL?>wiki.css" />
<link rel="stylesheet" media="print" type="text/css" href="<?php echo DOKU_TPL?>print.css" />
<!--[if gte IE 5]>
<style type="text/css">
/* that IE 5+ conditional comment makes this only visible in IE 5+ */
/* IE bugfix for transparent PNGs */
//DISABLED   img { behavior: url("<?php echo DOKU_BASE; ?>lib/scripts/pngbehavior.htc"); }
</style>
<![endif]-->
</head>
<body>
<?php /*Nucleus Wiki header */ @include(dirname(__FILE__).'/header.inc'); ?>

<div class="rbroundbox"><div class="rbtop"><div><div></div></div></div>
<div class="rbcontentwrap"><div class="rbcontent">
<h1 class="page_title"><?php tpl_link(wl($ID,'do=backlink'),$ID); ?></h1>

<?php html_msgarea(); ?>

<div class="stylehead">
	<?php if($conf['breadcrumbs']){?>
	<div class="breadcrumbs">
	<?php // tpl_breadcrumbs(); ?>
	<?php tpl_youarehere(); ?>
	</div>
	<?php }?>

	<div class="bar-top" id="bar_top">
			<div class="bar-left" id="bar_topleft">
				<?php tpl_button('edit'); ?>
				<?php tpl_button('history'); ?>
			</div>

			<div class="bar-right" id="bar_topright">
				<?php tpl_searchform(); ?>
			</div>
	</div>
</div>

<?php flush(); ?>

<div class="page">
<!-- wikipage start -->
<?php tpl_content(); ?>
<!-- wikipage stop -->
</div>

<div class="clearer">&nbsp;</div>

<?php flush(); ?>

<div class="stylefoot">
	<div class="meta">
		<div class="user">
			<?php tpl_userinfo(); ?>
		</div>
		<div class="doc">
			<?php tpl_pageinfo(); ?>
		</div>
	</div>
</div>

</div></div><div class="rbbot"><div><div></div></div></div></div>
<?php /*Nucleus Wiki footer */ @include(dirname(__FILE__).'/footer.inc'); ?>
</body>
</html>
