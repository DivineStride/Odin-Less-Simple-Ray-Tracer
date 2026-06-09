package raytracer

import "core:math"
import "core:math/linalg"

PERLIN_POINT_COUNT :: 256

Noise_Texture :: struct {
	noise: Perlin,
	scale: f64,
}

Perlin :: struct {
	randvec: [PERLIN_POINT_COUNT]Vec3,
	perm_x:  [PERLIN_POINT_COUNT]int,
	perm_y:  [PERLIN_POINT_COUNT]int,
	perm_z:  [PERLIN_POINT_COUNT]int,
}


noise_texture_value :: proc(tex: ^Noise_Texture, u, v: f64, p: Point3) -> Color {
	return Color{.5, .5, .5} * (1 + linalg.sin(tex.scale * p.z + 10 * turb(&tex.noise, p, 7)))
}

destroy_noise_texture :: proc(tex: ^Noise_Texture) {
	free(tex)
}

perlin :: proc() -> Perlin {
	p: Perlin
	for i in 0 ..< PERLIN_POINT_COUNT {
		p.randvec[i] = random_vec3_range(-1, 1)
	}

	generate_perlin_perm(&p.perm_x)
	generate_perlin_perm(&p.perm_y)
	generate_perlin_perm(&p.perm_z)

	return p
}

perlin_noise :: proc(p: ^Perlin, point: Point3) -> f64 {
	u := point.x - math.floor(point.x)
	v := point.y - math.floor(point.y)
	w := point.z - math.floor(point.z)

	i := int(math.floor(point.x))
	j := int(math.floor(point.y))
	k := int(math.floor(point.z))

	c: [2][2][2]Vec3
	for di := 0; di < 2; di += 1 {
		for dj := 0; dj < 2; dj += 1 {
			for dk := 0; dk < 2; dk += 1 {
				c[di][dj][dk] =
					p.randvec[p.perm_x[(i + di) & 255] ~ p.perm_y[(j + dj) & 255] ~ p.perm_z[(k + dk) & 255]]
			}
		}
	}

	return perlin_interp(p, c, u, v, w)
}

@(private)
perlin_interp :: proc(p: ^Perlin, c: [2][2][2]Vec3, u, v, w: f64) -> f64 {
	uu := u * u * (3 - 2 * u)
	vv := v * v * (3 - 2 * v)
	ww := w * w * (3 - 2 * w)

	accum := 0.0
	for i := 0; i < 2; i += 1 {
		for j := 0; j < 2; j += 1 {
			for k := 0; k < 2; k += 1 {
				weight_v := Vec3{u - f64(i), v - f64(j), w - f64(k)}
				accum +=
					(f64(i) * uu + (1 - f64(i)) * (1 - uu)) *
					(f64(j) * vv + (1 - f64(j)) * (1 - vv)) *
					(f64(k) * ww + (1 - f64(k)) * (1 - ww)) *
					linalg.dot(c[i][j][k], weight_v)
			}
		}
	}

	return accum
}

@(private)
turb :: proc(p: ^Perlin, point: Point3, depth: int) -> f64 {
	accum := 0.0
	temp_p := point
	weight := 1.0
	for i := 0; i < depth; i += 1 {
		accum += weight * perlin_noise(p, temp_p)
		weight *= 0.5
		temp_p *= 2
	}

	return math.abs(accum)
}

@(private)
generate_perlin_perm :: proc(perm: ^[PERLIN_POINT_COUNT]int) {
	for i in 0 ..< PERLIN_POINT_COUNT {
		perm[i] = i
	}

	// Shuffle
	for i := PERLIN_POINT_COUNT - 1; i > 0; i -= 1 {
		target := random_int(0, i)
		perm[i], perm[target] = perm[target], perm[i]
	}
}
