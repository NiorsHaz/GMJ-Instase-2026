class_name HitFlash
extends RefCounted
# Usage: HitFlash.flash($animation, Color.WHITE)

const SHADER_CODE := """
shader_type canvas_item;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 c = COLOR;
	COLOR = vec4(mix(c.rgb, flash_color.rgb, flash_amount), c.a);
}
"""

static var _shader: Shader

static func flash(sprite: CanvasItem, color: Color, hold: float = 0.05, fade: float = 0.15) -> void:
	if not is_instance_valid(sprite):
		return
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	var mat := sprite.material as ShaderMaterial
	if mat == null or mat.shader != _shader:
		mat = ShaderMaterial.new()
		mat.shader = _shader
		sprite.material = mat
	# Stop a previous flash still running on this sprite
	if sprite.has_meta("flash_tween"):
		var old = sprite.get_meta("flash_tween")
		if old is Tween and old.is_valid():
			old.kill()
	mat.set_shader_parameter("flash_color", color)
	mat.set_shader_parameter("flash_amount", 1.0)
	var tween = sprite.create_tween()
	sprite.set_meta("flash_tween", tween)
	tween.tween_interval(hold)
	tween.tween_property(mat, "shader_parameter/flash_amount", 0.0, fade)
