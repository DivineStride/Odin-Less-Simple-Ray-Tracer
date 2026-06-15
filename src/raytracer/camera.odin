package raytracer

import "core:fmt"
import "core:math"
import "core:math/linalg"

Camera :: struct {
	// Set these first before calling camera_render
	aspect_ratio:        f64,
	image_width:         int,
	samples_per_pixel:   int,
	max_depth:           int,
	position:            Point3,
	forward:             Point3,
	up:                  Vec3,
	right:               Vec3,
	focus_dist:          f64,

	// Physical camera details
	focal_length_mm:     int, // eg. 50, 85, 24
	fstop:               f64, // 1.2, 1.4, 2.8, 8.0
	iso:                 int, // eg. 100, 400, 1600
	exposure:            f64, // Shutter speed in seconds, e.g, 0.016 for 1/60s
	aperture:            Aperture_Shape, // Aperture Shape and Type
	lens:                Lens,

	// There are set by camera_init
	image_height:        int,
	pixel_samples_scale: f64,
	vfov:                f64,
	defocus_angle:       f64,
	ev_scale:            f64,
	camera_center:       Point3,
	pixel00_loc:         Point3,
	pixel_delta_u:       Vec3,
	pixel_delta_v:       Vec3,
	defocus_disk_u:      Vec3,
	defocus_disk_v:      Vec3,
	background:          Color,
}

camera_default :: proc() -> Camera {
	position := Point3{0, 0, 1}
	forward := linalg.normalize(position - Point3{0, 0, -1})
	right := linalg.normalize(linalg.cross(forward, Vec3{0, 1, 0}))
	up := linalg.cross(right, forward)

	return Camera {
		// Sensor
		focal_length_mm = 50,
		fstop = 8.0,
		iso = 100,
		exposure = 1.0 / 60,

		//Framing
		position = position,
		forward = forward,
		right = right,
		up = up,
		focus_dist = 10.0,
		aperture = Aperture_Circle{},
		lens = Lens {
			front = generate_lens_face(600, 0.018, 1.52, 12345),
			back = generate_lens_face(600, 0.018, 1.52, 67890),
		},

		// Image
		image_width = 400,
		aspect_ratio = 16.0 / 9.0,
		samples_per_pixel = 10,
		max_depth = 50,
		background = Color{0.70, 0.80, 1.00},
	}
}

camera_debug :: proc(cam: ^Camera, tag: string) {
	fmt.eprintfln(
		"[%s] pos=%.2v fwd=%.3v right=%.3v up=%.3v |fwd|=%.4f",
		tag,
		cam.position,
		cam.forward,
		cam.right,
		cam.up,
		linalg.length(cam.forward),
	)
}

camera_init :: proc(cam: ^Camera) {
	cam.image_height = max(1, int(math.floor(f64(cam.image_width) / cam.aspect_ratio)))
	cam.pixel_samples_scale = 1.0 / f64(cam.samples_per_pixel)
	cam.camera_center = cam.position
	cam.vfov = vfov_from_focal_length(cam.focal_length_mm)
	cam.defocus_angle = aperture_from_fstop(cam.focal_length_mm, cam.fstop, cam.focus_dist)
	cam.ev_scale = (f64(cam.iso) * cam.exposure) / (100.0 * 0.016)

	// Determine Viewport Dimensinos
	theta := degrees_to_radians(cam.vfov)
	h := math.tan(theta / 2)
	viewport_height := 2 * h * cam.focus_dist
	viewport_width := viewport_height * (f64(cam.image_width) / f64(cam.image_height))

	// Calculate the vectors across the horizontal and down the vertical viewport edges
	viewport_u := viewport_width * cam.right // Vector across viewport horizontal
	viewport_v := viewport_height * -cam.up // Vector down viewport vertical

	// Calculate the horizontal and vertical delta vectors from pixel to pixel
	cam.pixel_delta_u = viewport_u / f64(cam.image_width)
	cam.pixel_delta_v = viewport_v / f64(cam.image_height)

	// Calculate the location of the upper left pixel
	viewport_upper_left :=
		cam.camera_center + (cam.focus_dist * cam.forward) - viewport_u / 2 - viewport_v / 2
	cam.pixel00_loc = viewport_upper_left + 0.5 * (cam.pixel_delta_u + cam.pixel_delta_v)

	defocus_radius := cam.focus_dist * linalg.tan(degrees_to_radians(cam.defocus_angle))
	cam.defocus_disk_u = cam.right * defocus_radius
	cam.defocus_disk_v = cam.up * defocus_radius
}

sense_color :: proc(r: Ray, depth: int, bg: Color, world: []Hittable) -> Color {
	accumulated_color := Color{0, 0, 0}
	throughput := Color{1, 1, 1}
	current_ray := r

	if depth == 0 {
		return Color{0, 0, 0}
	}

	for i := 0; i < depth; i += 1 {
		if rec, ok := hit_world(world, current_ray, Interval{0.001, math.INF_F64}); ok {
			// Check if ray hit light
			if emmision, is_emmisive := color_emitted(rec.mat, rec.u, rec.v, rec.p); is_emmisive {
				accumulated_color += throughput * emmision
				break
			}

			// If the ray is absorbed, we exit the loop, otherwise we finish processing
			if attenuation, scattered, hit := scatter(rec.mat, current_ray, rec); !hit {
				break
			} else {
				throughput *= attenuation
				current_ray = scattered
			}
		} else {
			// Ray Escaped
			accumulated_color += throughput * bg

			break
		}
	}

	return accumulated_color
}
