extends ScrollContainer

# makes scroll bar bigger
func _ready():
   get_v_scroll_bar().custom_minimum_size.x = 35;
