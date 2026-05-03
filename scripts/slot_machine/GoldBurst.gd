extends Node2D
class_name GoldBurst

func _ready():
	var particles = GPUParticles2D.new()
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 15.0
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 100.0
	mat.initial_velocity_max = 250.0
	mat.gravity = Vector3(0, 400, 0)
	mat.scale_min = 4.0
	mat.scale_max = 8.0
	mat.color = Color(1.0, 0.8, 0.2)
	
	particles.process_material = mat
	particles.amount = 40
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.explosiveness = 0.95
	
	add_child(particles)
	
	await get_tree().create_timer(1.2).timeout
	queue_free()
