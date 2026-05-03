shader_type canvas_item;
uniform float shimmer_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float time_speed : hint_range(0.5, 5.0) = 2.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float shimmer = sin((UV.x + UV.y) * 20.0 + TIME * time_speed) * 0.5 + 0.5;
    vec3 glow = tex.rgb + vec3(shimmer * shimmer_intensity * 0.4);
    COLOR = vec4(glow, tex.a);
}
