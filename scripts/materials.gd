## Galaxy Frontier — Procedural PBR materials.
## No downloaded textures: every material is generated in code
## (FastNoiseLite heightfields -> albedo + normal map) and cached.
## Surfaces: concrete, asphalt, dirt, painted metal, bare metal,
## fabric, glass (opaque reflective — no transparency cost) and wood.
## Honest limit: Godot's GL Compatibility renderer (used for iOS)
## supports normal maps and PBR lighting but NOT real bloom/glow
## post-processing — glow is faked with emissive materials and
## lights instead. This is the ceiling on mobile Godot; it is not
## Unreal-level realism, and the report says so plainly.
class_name GFMaterials

static var _cache: Dictionary = {}


## Grayscale noise heightfield, 0..1.
static func _noise_image(size: int, frequency: float, seed: int) -> Image:
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_octaves = 3
	var img := Image.create(size, size, false, Image.FORMAT_RF)
	for y in size:
		for x in size:
			img.set_pixel(x, y, Color(noise.get_noise_2d(float(x), float(y)) * 0.5 + 0.5, 0, 0, 1))
	return img


## Normal map (RGB) from a heightfield via Sobel, strength scales
## the slope. Tangent-space, Y-up (Godot convention).
static func _normal_map(height: Image, strength: float) -> ImageTexture:
	var size := height.get_width()
	var out := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var h_l := height.get_pixel((x - 1 + size) % size, y).r
			var h_r := height.get_pixel((x + 1) % size, y).r
			var h_u := height.get_pixel(x, (y - 1 + size) % size).r
			var h_d := height.get_pixel(x, (y + 1) % size).r
			var dx := (h_r - h_l) * strength
			var dz := (h_d - h_u) * strength
			var n := Vector3(-dx, 1.0, -dz).normalized()
			out.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5))
	return ImageTexture.create_from_image(out)


## Albedo texture: base color modulated by noise (grain).
static func _albedo_texture(base: Color, variation: float, seed: int) -> ImageTexture:
	var size := 128
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.08
	noise.fractal_octaves = 3
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var v := 1.0 + (noise.get_noise_2d(float(x), float(y)) * variation)
			img.set_pixel(x, y, Color(clampf(base.r * v, 0.0, 1.0), clampf(base.g * v, 0.0, 1.0), clampf(base.b * v, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


static func _build(key: String, base: Color, metallic: float, roughness: float, normal_strength: float, freq: float, seed: int, variation: float) -> StandardMaterial3D:
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = _albedo_texture(base, variation, seed)
	m.normal_texture = _normal_map(_noise_image(128, freq, seed), normal_strength)
	m.metallic = metallic
	m.roughness = roughness
	_cache[key] = m
	return m


static func concrete(color: Color = Color(0.5, 0.51, 0.55)) -> StandardMaterial3D:
	return _build("concrete", color, 0.0, 0.92, 1.6, 0.05, 11, 0.10)


static func asphalt(color: Color = Color(0.16, 0.16, 0.18)) -> StandardMaterial3D:
	return _build("asphalt", color, 0.0, 0.95, 1.2, 0.09, 22, 0.08)


static func dirt(color: Color = Color(0.42, 0.3, 0.26)) -> StandardMaterial3D:
	return _build("dirt", color, 0.0, 1.0, 2.2, 0.04, 33, 0.16)


static func painted_metal(color: Color) -> StandardMaterial3D:
	return _build("painted_%s" % color.to_html(), color, 0.65, 0.38, 0.5, 0.12, 44, 0.04)


static func bare_metal(color: Color = Color(0.45, 0.47, 0.5)) -> StandardMaterial3D:
	return _build("bare_metal", color, 0.9, 0.32, 0.8, 0.10, 55, 0.06)


static func fabric(color: Color) -> StandardMaterial3D:
	return _build("fabric_%s" % color.to_html(), color, 0.0, 0.96, 0.9, 0.16, 66, 0.07)


static func wood(color: Color = Color(0.55, 0.42, 0.2)) -> StandardMaterial3D:
	return _build("wood", color, 0.0, 0.82, 1.0, 0.06, 77, 0.12)


## Reflective dark glass — opaque (no transparency pass) so it
## stays cheap on mobile; the high metallic + low roughness reads
## as glass under the sun and sky.
static func glass() -> StandardMaterial3D:
	if _cache.has("glass"):
		return _cache["glass"]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.08, 0.13, 0.18)
	m.metallic = 1.0
	m.roughness = 0.06
	_cache["glass"] = m
	return m


static func emissive(color: Color, energy: float = 1.5) -> StandardMaterial3D:
	var key := "emissive_%s_%s" % [color.to_html(), str(energy)]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	_cache[key] = m
	return m
