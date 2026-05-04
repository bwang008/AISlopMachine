extends Node2D
class_name GoldBurst

func _ready():
	var particles = GPUParticles2D.new()
	
	# Load the HD texture
	particles.texture = load("res://assets/graphics/hd_sparkle.png")
	
	# Apply Additive Blending (Glow effect)
	var canvas_mat = CanvasItemMaterial.new()
	canvas_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	particles.material = canvas_mat
	
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 15.0
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 100.0
	mat.initial_velocity_max = 250.0
	mat.gravity = Vector3(0, 400, 0)
	
	# Scale down drastically since the AI-generated texture is very high-res
	mat.scale_min = 0.03
	mat.scale_max = 0.08
	
	# Add a smooth fade-out over their lifetime
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.8, 0.2, 1.0))
	gradient.add_point(0.7, Color(1.0, 0.8, 0.2, 1.0))
	gradient.add_point(1.0, Color(1.0, 0.8, 0.2, 0.0))
	var grad_tex = GradientTexture1D.new()
	grad_tex.gradient = gradient
	mat.color_ramp = grad_tex
	
	particles.process_material = mat
	particles.amount = 40
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.explosiveness = 0.95
	
	add_child(particles)
	
	await get_tree().create_timer(1.2).timeout
	queue_free()
