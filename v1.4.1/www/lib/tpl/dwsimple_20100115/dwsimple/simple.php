<?php
# SIMPLE: SIMPLE Layout Engine V. 1.0
# (c) by Dietrich Wittenberg 03/2008
# E-Mail: info@wwwittenberg.de
# classes to define a css-layout with boxes
# layout is defined only by an xml-file
# creates an css-structure
#
# you may use this file for free but you need to
# let this copyright - info unchanged !!!

class mybox {

	function mybox ($id, $top, $right, $bottom, $left, $type="px") {
		$this->id			=$id;
		$this->top		=$top;
		$this->right	=$right;
		$this->bottom	=$bottom;
		$this->left		=$left;
		$this->type		=$type;
	}
	function make() {
		$out[]="#".$this->id;
		$out[]="{";
		if (($align=$this->top->align) == $this->bottom->align) 
		{ // fixed height
			if     ($align == "top")	// up side
				{
				$out[]="top     : " . $this->top->val . $this->type .";";
				$out[]="height  : " . ($this->bottom->val - $this->top->val) . $this->type .";";
				}
			else
				{ 													// bottom side
				$out[]="bottom  : " . $this->bottom->val . $this->type .";";
				$out[]="height  : " . ($this->top->val - $this->bottom->val) . $this->type .";";
				}
		}
		else 
		{	// calculated height
			$out[]  ="top     : " . $this->top->val . $this->type .";";
			$out[]  ="height  : expression(document.body.clientHeight +(" . (-$this->bottom->val - $this->top->val) . ") +\"" . $this->type . "\")" .";";
			$out[]  ="bottom  : " . $this->bottom->val . $this->type . "; /* Firefox / IE7 */";
		}
		if (($align=$this->left->align) == $this->right->align) 
		{ // fixed height
			if     ($align == "left")	// left side
				{
				$out[]="left    : " . $this->left->val . $this->type .";";
				$out[]="width   : " . ($this->right->val - $this->left->val) . $this->type .";";
				}
			else
				{														// right side
				$out[]="right   : " . $this->right->val . $this->type .";";
				$out[]="width   : " . ($this->left->val - $this->right->val) . $this->type .";";
				}
		}
		else 
		{	// calculated width
			$out[]  ="left    : " . $this->left->val  . $this->type .";";
			$out[]  ="width   : expression(document.body.clientWidth +(" . (-$this->right->val - $this->left->val) . ")+ \"" . $this->type . "\")" .";";
			$out[]  ="right   : " . $this->right->val . $this->type . "; /* Firefox / IE7 */"; 
		}
		if (is_string($this->style) && ($this->style != ""))
			$out[]=$this->style. ";";
		else
			if (is_array($this->style))
				foreach ($this->style as $c)
					$out[]=$c.";";

		$out[]="}";
		return $out;
	}
}
class myline {
	function myline($val, $align) {
		$this->val=$val;
		$this->align=$align;
	}
}

class layout {

	function layout($file) {
		$this->lines=0;
		$this->boxes=0;
		$this->loadxml($file);
	}
	function addline($id, $val=0, $align) {
		$this->line[$id]=new myline($val, $align);
	}
	function addlineval($id, $val=0) {
		$this->line[$id]->val=$val;
	}
	function addlines($vals, $align) {
		foreach ($vals as $id => $val) 
			$this->addline($id, $val, $align);
	}
	function addbox($id, $top, $right, $bottom, $left) {
		$this->box[$id]=new mybox($id, $this->line[$top], $this->line[$right], $this->line[$bottom], $this->line[$left], $this->type);
	}
	function addboxstyle($id, $style) {
		$this->box[$id]->style[]=$style;
	}
	function outExp($pre, $style) {
		foreach($this->box as $box) 
			$tmp[]=$pre."#".$box->id;
		$out=implode(",\n", $tmp)."\n{\n".$style."\n}\n";
		return $out;
	}
	function outall() {
		$out =$this->outExp("", "position: fixed; \noverflow: auto;  /* Firefox */ ");
		$out.=$this->outExp("* html ", "position: absolute; \nz-index : 1;  /* IE6 */ ");
		foreach($this->box as $box) 
			$out.=implode("\n", $box->make())."\n";
		echo $out;
	}
	function loadxml($file) {
		$this->parser = xml_parser_create();
		xml_set_object($this->parser, $this);
		xml_set_element_handler($this->parser, "startElement", "endElement");
		xml_set_character_data_handler($this->parser, "cdata");
		
		if (!($this->fp = fopen($file, "r")))   die("could not open XML input");
	}
	
	function parsexml() {
		while ($data = fread($this->fp, 4096)) {
		    if (!xml_parse($this->parser, $data, feof($this->fp))) {
		        die(sprintf("XML error: %s at line %d",
		                    xml_error_string(xml_get_error_code($this->parser)),
		                    xml_get_current_line_number($this->parser)));
		    }
		}
		xml_parser_free($this->parser);
	}
	function startElement($parser, $name, $attrs) {
		
		$this->tag=$name;
		switch ($name) {
			case "BOX":
				$this->boxid    =(isset($attrs["ID"]))     ? $attrs["ID"]     : $this->boxindex++;
				$this->boxtop   =(isset($attrs["TOP"]))    ? $attrs["TOP"]    : 0;
				$this->boxright =(isset($attrs["RIGHT"]))  ? $attrs["RIGHT"]  : 0;
				$this->boxbottom=(isset($attrs["BOTTOM"])) ? $attrs["BOTTOM"] : 0;
				$this->boxleft  =(isset($attrs["LEFT"]))   ? $attrs["LEFT"]   : 0;
				$this->addbox($this->boxid , $this->boxtop, $this->boxright, $this->boxbottom, $this->boxleft);
			break;
			case "LINE":
				$this->lineid   =(isset($attrs["ID"]))    ? $attrs["ID"]    : $this->lineindex++;
				$this->linealign=(isset($attrs["ALIGN"])) ? $attrs["ALIGN"] : "top";
			break;
			case "LINES":
				$this->linealign=(isset($attrs["ALIGN"])) ? $attrs["ALIGN"] : "top";
			break;
			}
	}
	function endElement($parser, $name) {
		switch ($name) {
			case "DIMENSION":
				$this->type=$this->inhalt;
			break;
			case "LINE":
				$this->addline($this->lineid, $this->inhalt, $this->linealign);
			break;
			case "LINES":
				$this->addlines(explode(",", $this->inhalt), $this->linealign);
			break;
			case "STYLE":
				$this->addboxstyle($this->boxid, $this->inhalt);
			break;
		}
	}
	
	function cdata($parser, $element_inhalt) {
		//$inhalt=preg_replace("/^[ ]*([^\s]*)[ \s]*$/","$1",$element_inhalt);
		$inhalt=trim($element_inhalt);
		
		if ($inhalt!="") {
				$this->inhalt=$inhalt;
		}
	}
}

function createcss($file) {
	$csslayout=new layout($file);
	$csslayout->parsexml();
	$csslayout->outall($explorer);
}

?>
