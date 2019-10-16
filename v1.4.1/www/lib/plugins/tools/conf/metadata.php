<?php
/**
 * Metadata for the BookmarkMe plugin
 *
 * @author    Ilya Lebedev <ilya@lebedev.net>
 */

$meta['show_tools'] = array("multichoice",
                                "_choices" => array(0,1,2,3));

$meta['show_link'] = array("multichoice",
                                "_choices" => array(0,1,2));

$meta['show_header'] = array("onoff");

$meta['tools'] = array('multicheckbox',
                           '_choices' => array( 'email'
                                               ,'pdf'
                                               ,'bookcreator'
                                               ,'odt'
                                               ,'print'
                                               ,'csv'
                                               ,'timeline'
                                              )
                           ,'_combine' => array());
$meta['skip_ids'] = array('multicheckbox',
                          '_choices' => array( 'sidebar'
                                              ,'user'
                                              ,'group'
                                              ,'playground'
                                              ,'wiki:syntax'
                                              )
                           ,'_combine' => array());

//Setup VIM: ex: et ts=2 enc=utf-8 :















































