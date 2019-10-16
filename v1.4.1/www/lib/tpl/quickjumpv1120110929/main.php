<?php if (!defined('DOKU_INC')) die('Must be run within dokuwiki!'); ?>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="<?php echo $conf['lang']?>" lang="<?php echo $conf['lang']?>" dir="<?php echo $lang['direction']?>">

<head>
  <meta http-equiv="Content-type" content="text/html; charset=utf-8" />

  <title><?php tpl_pagetitle()?> | <?php echo strip_tags($conf['title'])?></title>

  <link rel='icon' type='image/png' href='<?php echo DOKU_TPL?>images/favicon.png' />
  <link rel='stylesheet' type='text/css' href='<?php echo DOKU_TPL?>/blueprint/screen.css' />

	<script src='<?php echo DOKU_TPL?>jquery-1.4.2.min.js' type='text/javascript'></script>
  <script src='<?php echo DOKU_TPL?>scripts.js' type='text/javascript'></script>

  <?php tpl_metaheaders()?>
  <?php if (file_exists(DOKU_PLUGIN.'displaywikipage/code.php')) include_once(DOKU_PLUGIN.'displaywikipage/code.php'); ?>

</head>

<body>

  <!-- Top Header -->
  <div id='top_header' class='clearfix'>
		<h1><a href='<?php echo DOKU_URL; ?>' title='<?php echo $conf['title']; ?> Homepage'><?php echo strip_tags($conf['title'])?></a></h1>
		
		<p id='account_info'><?php tpl_userinfo(); ?><br /><?php tpl_actionlink('profile', '', '', 'My Account'); ?> <?php tpl_actionlink('login'); ?> <?php if(auth_isadmin()): ?>| <?php tpl_actionlink('admin'); ?><?php endif; ?></p>
		<br class='clear' />
  </div>
  
  <!-- TOC Area -->
  <div id='toc_area'>
	<div id='toc_inner'>
		<?php if (function_exists('dwp_display_wiki_page')): ?>
			<?php dwp_display_wiki_page("shared:sidebar"); ?>
		<?php else: ?>
			<?php include(dirname(__FILE__) . '/sidebar.php'); ?>
		<?php endif; ?>
		<br class='clear' />
	</div>	
</div>
	<div id='toc_toggle' style=''><a href='#'>Table of Contents</a></div>

	<!-- Main Area -->
  <div id='main_pane'>
    
		<div id='main_pane_header'>	        
			<?php tpl_button('edit')?>
			<?php tpl_button('history')?>
	      	
			<form id='search' method='get' accept-charset='utf-8' action='<?php echo DOKU_URL; ?>doku.php/'>
				<input type="hidden" value="search"  name="do" />
				<input type='text' id="navSearch" placeholder='Search' name="id" accesskey="f" />
				<input class='button' type='submit' value='&raquo;' />
			</form>
			<br class='clear' />
		</div>    

	  <p id='main_pane_breadcrumbs'>
			<?php if($conf['youarehere']): ?>
				<?php tpl_youarehere() ?>
			<?php else: ?>
				<?php tpl_breadcrumbs()?>
			<?php endif; ?>
		</p>

	          
			<div id="content">
				<div class='page dokuwiki'>
					<?php flush();?>
					<!-- wikipage start -->
					<?php tpl_content();?>
					<!-- wikipage stop -->
		       <?php flush();?>
		     </div>
		   </div>
	    
	</div>


  <!-- Footer -->
  <div id="footer">
  
  	<ul>
  		<li><a href="<?php echo DOKU_URL; ?>/feed.php">Wiki RSS Feed</a></li>
			<li><a href="<?php echo DOKU_URL; ?>doku.php/wiki:syntax">Wiki Syntax Guide</a></li>
			<li><a href="http://wiki.splitbrain.org/wiki%3Amanual">DokuWiki Documentation</a></li>
	  </ul>
  
    <p>
      <?php tpl_pageinfo(); ?> | <?php tpl_actionlink('edit')?>
      <br />Copyright (c) <?php echo(date('Y'));?> All Rights Reserved
    </p>
  </div>

  <div class="no"><?php /* provide DokuWiki housekeeping, required in all templates */ tpl_indexerWebBug()?></div>

</body>
</html>
