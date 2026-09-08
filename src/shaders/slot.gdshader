shader_type canvas_item;

// Inspector üzerinden değiştirebileceğiniz renkler
uniform vec4 color1 : source_color = vec4(1.0, 0.0, 0.0, 1.0); // Sol-Üst border rengi
uniform vec4 color2 : source_color = vec4(0.0, 0.0, 1.0, 1.0); // Sağ-Alt border rengi
uniform vec4 color3 : source_color = vec4(0.0, 1.0, 0.0, 1.0); // Orta kısım rengi

// Kesim çizgisinin yumuşaklığı (0.0 = keskin, 0.02 = hafif yumuşak)
uniform float smoothness : hint_range(0.0, 0.1) = 0.0;

// Kesim yönünü tersine çevirmek isterseniz bunu açabilirsiniz
uniform bool invert_diagonal = false;

// Border modu - açıkken sol-üst color1, sağ-alt color2, orta color3
uniform bool border_mode = false;

// Border kalınlığı (piksel cinsinden)
uniform float border_width : hint_range(0.0, 20.0) = 2.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    vec4 final_color;
    
    if (border_mode) {
        // Border modu: sol-üst color1, sağ-alt color2, orta color3
        
        // Pixel boyutunu hesapla
        vec2 pixel_size = 1.0 / vec2(textureSize(TEXTURE, 0));
        float border_x = border_width * pixel_size.x;
        float border_y = border_width * pixel_size.y;
        
        // Kenar kontrolleri
        bool is_left = UV.x < border_x;
        bool is_top = UV.y < border_y;
        bool is_right = UV.x > (1.0 - border_x);
        bool is_bottom = UV.y > (1.0 - border_y);
        
        // Varsayılan olarak orta kısım (color3)
        final_color = color3;
        
        // Sol veya üst kenar ise color1
        if (is_left || is_top) {
            final_color = color1;
        }
        // Sağ veya alt kenar ise color2
        else if (is_right || is_bottom) {
            final_color = color2;
        }
        
        // Yumuşak geçişler
        float left_edge = smoothstep(border_x - smoothness * pixel_size.x, border_x + smoothness * pixel_size.x, UV.x);
        float top_edge = smoothstep(border_y - smoothness * pixel_size.y, border_y + smoothness * pixel_size.y, UV.y);
        float right_edge = smoothstep((1.0 - border_x) - smoothness * pixel_size.x, (1.0 - border_x) + smoothness * pixel_size.x, UV.x);
        float bottom_edge = smoothstep((1.0 - border_y) - smoothness * pixel_size.y, (1.0 - border_y) + smoothness * pixel_size.y, UV.y);
        
        // Sol-üst border maskesi (1 = sol-üst border)
        float left_border = 1.0 - left_edge;
        float top_border = 1.0 - top_edge;
        float left_top_mask = max(left_border, top_border);
        
        // Sağ-alt border maskesi (1 = sağ-alt border)
        float right_border = 1.0 - right_edge;
        float bottom_border = 1.0 - bottom_edge;
        float right_bottom_mask = max(right_edge, bottom_edge);
        
        // Renkleri katmanla
        final_color = color3; // Önce orta kısım
        final_color = mix(final_color, color2, right_bottom_mask); // Sonra sağ-alt border
        final_color = mix(final_color, color1, left_top_mask); // En üstte sol-üst border
		
		final_color.a = tex_color.a;
		
    } else {
        // Normal çapraz mod
        float diagonal = UV.x + UV.y;
        
        if (invert_diagonal) {
            diagonal = UV.x + (1.0 - UV.y);
        }
        
        float split = smoothstep(1.0 - smoothness, 1.0 + smoothness, diagonal);
        final_color = mix(color1, color2, split);
    }
    
    COLOR = vec4(final_color.rgb, final_color.a * tex_color.a);
}