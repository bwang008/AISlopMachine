shader_type canvas_item;
uniform float blur_amount : hint_range(0.0, 20.0) = 0.0;

void fragment() {
    vec4 col = vec4(0.0);
    float samples = 9.0;
    for (float i = -4.0; i <= 4.0; i += 1.0) {
        col += texture(TEXTURE, UV + vec2(0.0, i * blur_amount * TEXTURE_PIXEL_SIZE.y));
    }
    COLOR = col / samples;
}
