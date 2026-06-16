package raytracer

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:os"
import "core:strings"

// This is a really good generator for a kind of bumpy, nearly flat normal map
// It's not a point of failure to trust an LLM with an idea that is physically experienced.
// It's not just a lens generator; it's a successful obscure glass producer.
// Warning, not for use as an actual lens, the maker of this ray tracer is not responsible for irresponsible use of this lens and or side effects associated with it's use such as...


Lens_Face :: struct {
	normals:    []Vec3,
	resolution: int,
	strength:   f64,
	ior:        f64,
}


Lens :: struct {
	front: Lens_Face,
	back:  Lens_Face,
}

generate_lens_face :: proc(resolution: int, strength: f64, ior: f64, seed: u64) -> Lens_Face {
	normals := make([]Vec3, resolution * resolution)

	for y in 0 ..< resolution {
		for x in 0 ..< resolution {
			// Normalized UV coords from center
			u := (f64(x) / f64(resolution - 1)) * 2 - 1
			v := (f64(y) / f64(resolution - 1)) * 2 - 1

			// Radial Distortion increases towards edges
			r := math.sqrt_f64(u * u + v * v)
			radial := r * r * 0.3

			// Create large lens shape
			low_freq_x := math.sin_f64(u * math.PI * 1.5 + f64(seed)) * 0.4
			low_freq_y := math.cos_f64(v * math.PI * 1.5 + f64(seed)) * 0.4

			// Surface minor imperfections
			high_freq_x := math.sin_f64(u * 23.6 + v * 17.3) * 0.15
			high_freq_y := math.cos_f64(v * 19.1 + u * 31.4) * 0.15

			nx := (low_freq_x + high_freq_x + u * radial) * strength
			ny := (low_freq_y + high_freq_y + v * radial) * strength

			normals[y * resolution + x] = linalg.normalize(Vec3{nx, ny, 1})
		}
	}

	face := Lens_Face{normals, resolution, strength, ior}

	save_lens_normal_map(face, fmt.tprintf("./images/lens_%d_strength%.3f.ppm", seed, strength))
	return face
}

save_lens_normal_map :: proc(face: Lens_Face, filename: string) {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)

	strings.write_string(&sb, "P3\n")
	strings.write_string(&sb, fmt.tprintf("%d %d\n", face.resolution, face.resolution))
	strings.write_string(&sb, "255\n")

	for i in 0 ..< (face.resolution * face.resolution) {
		n := face.normals[i]

		r := int((n.x + 1.0) * 0.5 * 255)
		g := int((n.y + 1.0) * 0.5 * 255)
		b := int((n.z + 1.0) * 0.5 * 255)

		strings.write_string(
			&sb,
			fmt.tprintf(
				"%d %d %d\n",
				math.clamp(r, 0, 255),
				math.clamp(g, 0, 255),
				math.clamp(b, 0, 255),
			),
		)
	}

	if err := os.write_entire_file(filename, transmute([]byte)strings.to_string(sb));
	   err != os.ERROR_NONE {
		fmt.eprintf("Failed to write file: %s", filename)
	}

}

sample_lens_normal :: proc(face: Lens_Face, disk_pos: Vec2) -> Vec3 {
	// Map disk position (-1 to 1) to grid coords
	u := (disk_pos.x + 1) * 0.5
	v := (disk_pos.y + 1) * 0.5

	x := u * f64(face.resolution - 1)
	y := v * f64(face.resolution - 1)
	x0, y0 := int(x), int(y)
	x1 := math.min(x0 + 1, face.resolution - 1)
	y1 := math.min(y0 + 1, face.resolution - 1)

	fx := x - f64(x0)
	fy := y - f64(y0)

	n00 := face.normals[y0 * face.resolution + x0]
	n10 := face.normals[y0 * face.resolution + x1]
	n01 := face.normals[y1 * face.resolution + x0]
	n11 := face.normals[y1 * face.resolution + x1]

	return linalg.normalize(
		n00 * (1 - fx) * (1 - fy) + n10 * fx * (1 - fy) + n01 * (1 - fx) * fy + n11 * fx * fy,
	)
}

apply_lens :: proc(cam: ^Camera, ray_dir: Vec3, disk_pos: Vec2) -> Vec3 {
	dir := linalg.normalize(ray_dir)

	front_normal := sample_lens_normal(cam.lens.front, disk_pos)
	dir = refract(dir, front_normal, 1.0 / cam.lens.front.ior)

	back_normal := sample_lens_normal(cam.lens.back, disk_pos)
	dir = refract(dir, -back_normal, cam.lens.back.ior)

	return linalg.normalize(dir)
}
