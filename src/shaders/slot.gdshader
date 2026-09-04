shader_type canvas_item;

// Inspector üzerinden değiştirebileceğiniz renkler
uniform vec4 color1 : source_color = vec4(1.0, 0.0, 0.0, 1.0); // Kırmızı
uniform vec4 color2 : source_color = vec4(0.0, 0.0, 1.0, 1.0); // Mavi

// Kesim çizgisinin yumuşaklığı (0.0 = keskin, 0.02 = hafif yumuşak)
uniform float smoothness : hint_range(0.0, 0.1) = 0.0;

// Kesim yönünü tersine çevirmek isterseniz bunu açabilirsiniz
uniform bool invert_diagonal = false;

void fragment() {
    // Texture'ın kendi piksel rengini ve alpha değerini alıyoruz
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Çapraz eksen hesabı (UV.x + UV.y)
    float diagonal = UV.x + UV.y;
    
    if (invert_diagonal) {
        diagonal = UV.x + (1.0 - UV.y);
    }
    
    // Çaprazın tam ortası 1.0 noktasıdır (0.5 + 0.5)
    // smoothstep kullanarak iki renk arasında keskin/yumuşak geçiş yapıyoruz
    float split = smoothstep(1.0 - smoothness, 1.0 + smoothness, diagonal);
    
    // Renkleri çapraz çizgiye göre karıştırıyoruz
    vec4 final_color = mix(color1, color2, split);
    
    // Beyaz texture üzerindeki renk ile orijinal texture'ın alpha (şeffaflık) değerini birleştiriyoruz
    COLOR = vec4(final_color.rgb, final_color.a * tex_color.a);
}