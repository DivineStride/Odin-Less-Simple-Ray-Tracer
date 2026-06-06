package raytracer

import "core:math"
import "core:math/linalg"
import "core:math/rand"

Vec2 :: linalg.Vector2f64

Aperture_Circle :: struct {}

Aperture_Polygon :: struct {
	blades:   int,
	rotation: f64,
}

Aperture_Star :: struct {
	points:       int,
	inner_radius: f64,
	rotation:     f64,
}

Aperture_Custom :: struct {
	vertices: []Vec2,
	name:     string,
}

Aperture_Shape :: union {
	Aperture_Circle,
	Aperture_Polygon,
	Aperture_Star,
	Aperture_Custom,
}

sample_aperture :: proc(shape: Aperture_Shape) -> Vec3 {
	switch s in shape {
	case Aperture_Circle:
		return random_in_unit_disk()
	case Aperture_Polygon:
		return random_in_polygon(s.blades, s.rotation)
	case Aperture_Star:
		random_in_star(s.points, s.inner_radius, s.rotation)
	case Aperture_Custom:
		return random_in_custom_polygon(s.vertices)
	}
	return random_in_unit_disk()
}

defocus_disk_sample :: proc(cam: ^Camera) -> Point3 {
	// Returns a random mpoint in the camera defocus disk.
	p := sample_aperture(cam.aperture)
	return cam.camera_center + (p[0] * cam.defocus_disk_u) + (p[1] * cam.defocus_disk_v)
}

random_in_unit_disk :: proc() -> Vec3 {
	for {
		p := Vec3{random_f64_range(-1, 1), random_f64_range(-1, 1), 0}
		if linalg.length2(p) < 1 {
			return p
		}
	}
}

random_in_polygon :: proc(blades: int, rotation: f64) -> Vec3 {
	angle_step := 2.0 * math.PI / f64(blades)
	sector := rand.int_max(blades)

	a0 := f64(sector) * angle_step + rotation
	a1 := f64(sector + 1) * angle_step + rotation

	v1 := Vec3{math.cos(a0), math.sin(a0), 0}
	v2 := Vec3{math.cos(a1), math.sin(a1), 0}

	return sample_triangle(v1, v2)
}

random_in_star :: proc(points: int, inner_radius: f64, rotation_deg: f64) -> Vec3 {
	n := 2 * points
	angle_step := 2.0 * math.PI / f64(n)
	rotation := degrees_to_radians(rotation_deg)
	sector := rand.int_max(n)

	a0 := f64(sector) * angle_step + rotation
	a1 := f64(sector + 1) * angle_step + rotation

	r0 := 1.0 if sector % 2 == 0 else inner_radius
	r1 := inner_radius if sector % 2 == 0 else 1.0

	v1 := Vec3{r0 * math.cos(a0), r0 * math.sin(a0), 0}
	v2 := Vec3{r1 * math.cos(a1), r1 * math.sin(a1), 0}

	return sample_triangle(v1, v2)
}

random_in_custom_polygon :: proc(verts: []Vec2) -> Vec3 {
	n := len(verts)
	assert(n >= 3, "Custom aperture needs at least 3 verteces")

	areas := make([]f64, n - 2)
	defer delete(areas)
	total_area: f64 = 0

	for i in 0 ..< n - 2 {
		ax := verts[i + 1].x - verts[0].x
		ay := verts[i + 1].y - verts[0].y
		bx := verts[i + 2].x - verts[0].x
		by := verts[i + 2].y - verts[0].y
		area := abs(ax * by - ay * bx) * 0.5
		areas[i] = area
		total_area += area
	}

	pick := random_f64() * total_area
	tri := n - 3
	cumulative: f64 = 0
	for i in 0 ..< n - 2 {
		cumulative += areas[i]
		if pick <= cumulative {tri = i; break}
	}

	v0 := verts[0]
	v1 := verts[tri + 1]
	v2 := verts[tri + 2]

	r1 := math.sqrt(random_f64())
	r2 := random_f64()

	px := (1 - r1) * v0.x + r1 * (1 - r2) * v1.x + r1 * r2 * v2.x
	py := (1 - r1) * v0.y + r1 * (1 - r2) * v1.y + r1 * r2 * v2.y
	return Vec3{px, py, 0}
}

sample_triangle :: proc(v1, v2: Vec3) -> Vec3 {
	r1 := math.sqrt(random_f64())
	r2 := random_f64()

	return r1 * (1.0 - r2) * v1 + r1 * r2 * v2
}
