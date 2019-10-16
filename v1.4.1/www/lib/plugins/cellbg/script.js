/* JavaScript function to create cellbg toolbar in DokuwKki */
/* see http:// for more info */
 
var plugin_cellbg_colors = {
 
  "Yellow":      "yellow",
  "Red":         "red",
  "Orange":      "orange",
  "Salmon":      "salmon",
  "Pink":        "pink",
  "Plum":        "plum",
  "Purple":      "purple",
  "Fuchsia":     "fuchsia",
  "Silver":      "silver",
  "Aqua":        "aqua",
  "Teal":        "teal",
  "Cornflower":  "#6495ed",
  "Sky Blue":    "skyblue",
  "Aquamarine":  "aquamarine",
  "Pale Green":  "palegreen",
  "Lime":        "lime",
  "Green":       "green",
  "Olive":       "olive"
  //"Yellow":      "#ffff00",
  //"Red":         "#ff0000",
  //"Orange":      "#ffa500",
  //"Salmon":      "#fa8072",
  //"Pink":        "#ffc0cb",
  //"Plum":        "#dda0dd",
  //"Purple":      "#800080",
  //"Fuchsia":     "#ff00ff",
  //"Silver":      "#c0c0c0",
  //"Aqua":        "#00ffff",
  //"Teal":        "#008080",
  //"Cornflower":  "#6495ed",
  //"Sky Blue":    "#87ceeb",
  //"Aquamarine":  "#7fffd4",
  //"Pale Green":  "#98fb98",
  //"Lime":        "#00ff00",
  //"Green":       "#008000",
  //"Olive":       "#808000"
 
};
 
function plugin_cellbg_make_color_button(name, value) {
 
  var btn = document.createElement('button');
 
  btn.className = 'pickerbutton';
  btn.value = '';
  btn.title = name;
  btn.style.height = '2em';
  btn.style.padding = '1em';
  btn.style.backgroundColor = value;
 
  var open = "@" + value + ":";
  eval("btn.onclick = function(){ insertAtCarret( '"
    + jsEscape('wiki__text') + "','"
    + jsEscape(open) + "','"
    + "'); return false; } "
  );
 
  return(btn);
 
}
 
function plugin_cellbg_toolbar_picker() {
 
  if (!document.getElementById('spell__action')) return; 

  var toolbar = document.getElementById('tool__bar');
  if (!toolbar) return;
 
  // Create the picker button
  var p_id = 'picker_plugin_cellbg'; // picker id that we're creating
  var p_ico = document.createElement('img');
  p_ico.src = DOKU_BASE + 'lib/plugins/cellbg/images/cellbg.png';
  var p_btn = document.createElement('button');
  p_btn.className = 'toolbutton';
  p_btn.title = 'Cell background';
  p_btn.appendChild(p_ico);
  eval("p_btn.onclick = function() { showPicker('"
    + p_id + "',this); return false; }");
 
  // Create the picker <div>
  var picker = document.createElement('div');
  picker.className = 'picker';
  picker.id = p_id;
  picker.style.position = 'absolute';
  picker.style.display = 'none';
 
  // Add a button to the picker <div> for each of the colors
  for( var color in plugin_cellbg_colors ) {
    var btn = plugin_cellbg_make_color_button(color,
        plugin_cellbg_colors[color]);
    picker.appendChild(btn);
  }
  if (typeof user_cellbg_colors != 'undefined') {
    for( var color in user_cellbg_colors ) {
      var btn = plugin_cellbg_make_color_button(color,
          user_cellbg_colors[color]);
      picker.appendChild(btn);
    }
  }
 
  var body = document.getElementsByTagName('body')[0];
  body.appendChild(picker);     // attach the picker <div> to the page body
  toolbar.appendChild(p_btn);   // attach the picker button to the toolbar
}
jQuery(plugin_cellbg_toolbar_picker);
 
//Setup VIM: ex: et ts=2 sw=2 enc=utf-8 :
