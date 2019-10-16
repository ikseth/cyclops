<?php
/**
 * Configuration-manager metadata for progrecss plugin
 *
 * @license:    GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author:     Luis Machuca <luis.machuca@gulix.cl>
 */

// percentage format takes %02d, %4x or similar (software appends a literal %)
$meta['percent_format']     = array('string', 'pattern' => '/\%[0-9]*[uoxX]/' );
// fraction divisor takes one character
$meta['fraction_divisor']      = array('string', 'pattern' => '/./' ); 

