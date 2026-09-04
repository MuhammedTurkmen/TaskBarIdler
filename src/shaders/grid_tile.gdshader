shader_type canvas_item;

uniform vec2 cell_size_px = vec2(32.0, 32.0);
uniform vec2 line_width_px = vec2(2.0, 2.0);
uniform vec2 offset_px = vec2(0.0, 0.0);
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform int cut_right_px = 0;
uniform int cut_bottom_px = 0;

void fragment() {
	vec2 canvas_size = 1.0 / TEXTURE_PIXEL_SIZE;
	
	// Pixel pozisyonunu hesapla
	vec2 pixel_pos = UV * canvas_size + offset_px;
	
	// Grid çizgilerini mod operasyonu ile hesapla
	vec2 mod_result = mod(pixel_pos, cell_size_px);
	
	// Çizgi kalınlığını kontrol et
	float in_line_x = step(mod_result.x, line_width_px.x) + 
	                  step(cell_size_px.x - line_width_px.x, mod_result.x);
	float in_line_y = step(mod_result.y, line_width_px.y) + 
	                  step(cell_size_px.y - line_width_px.y, mod_result.y);
	
	float grid_line = clamp(in_line_x + in_line_y, 0.0, 1.0);
	
	// Kesimleri uygula
	if (cut_right_px > 0) {
		grid_line *= step(pixel_pos.x, canvas_size.x - float(cut_right_px));
	}
	if (cut_bottom_px > 0) {
		grid_line *= step(pixel_pos.y, canvas_size.y - float(cut_bottom_px));
	}
	
	COLOR.rgb = line_color.rgb;
	COLOR.a = grid_line * line_color.a;
}