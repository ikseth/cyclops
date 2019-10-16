jQuery(document).ready(function() {
	//put all your jQuery goodness in here.
	jQuery('#toc_toggle > a').click(function() {
		jQuery('#toc_area').slideToggle();
	});
	
	jQuery('#toc_toggle').css('display', 'block');
	

});
