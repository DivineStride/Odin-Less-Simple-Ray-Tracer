package raytracer

import "core:math/linalg"

Point3 :: Vec3

Ray :: struct {
	origin: Point3,
	dir:    Vec3,
	tm:     f64,
}

new_ray :: proc(origin, direction: Vec3, tm: f64 = 0) -> Ray {
	return Ray{origin, direction, tm}
}

ray_at :: proc(r: Ray, t: f64) -> Point3 {
	return r.origin + t * r.dir
}

get_ray :: proc(cam: ^Camera, i, j: int) -> Ray {
	// Construct a camera ray originating form the defocus disk and directed at a randomly sampled
	// point around the pixel location i, j

	offset := sample_square()
	pixel_sample :=
		cam.pixel00_loc +
		((f64(i) + offset.x) * cam.pixel_delta_u) +
		((f64(j) + offset.y) * cam.pixel_delta_v)

	ray_origin := cam.defocus_angle <= 0 ? cam.camera_center : defocus_disk_sample(cam)
	ray_direction := pixel_sample - ray_origin

	if false {
		disk_pos := Vec2{ray_origin.x - cam.camera_center.x, ray_origin.y - cam.camera_center.y}
		ray_direction = apply_lens(cam, ray_direction, disk_pos)
	}

	ray_time := random_f64()

	return new_ray(ray_origin, ray_direction, ray_time)
}
