shader_type canvas_item;
// Apaga los colores del abade para que case con la plaza nocturna.

uniform float desaturar : hint_range(0.0, 1.0) = 0.45;
uniform vec3 tinte : source_color = vec3(0.78, 0.76, 0.80);

void fragment() {
	float gris = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = mix(COLOR.rgb, vec3(gris), desaturar) * tinte;
}
