package raytracer

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:slice"

Camera :: struct {
	// Set these first before calling camera_render
	aspect_ratio:        f64,
	image_width:         int,
	samples_per_pixel:   int,
	sqrt_spp:            int,
	recip_sqrt_spp:      int,
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
	fmt.eprintf(
		"\r[%s] pos=%.2v fwd=%.3v right=%.3v up=%.3v |fwd|=%.4f",
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

	// Stratified Samples
	cam.sqrt_spp = int(math.sqrt_f64(f64(cam.samples_per_pixel)))
	cam.pixel_samples_scale = 1.0 / f64(cam.sqrt_spp * cam.sqrt_spp)
	cam.recip_sqrt_spp = int(1.0 / f64(cam.sqrt_spp))


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

sense_color :: proc(
	r: Ray,
	depth: int,
	bg: Color,
	world: []Hittable,
	lights: []^Hittable,
) -> Color {
	accumulated_color := Color{0, 0, 0}
	throughput := Color{1, 1, 1}
	current_ray := r

	if depth == 0 {
		return Color{0, 0, 0}
	}

	for i := 0; i < depth; i += 1 {
		if rec, ok := hit_world(world, current_ray, Interval{0.001, math.INF_F64}); ok {
			// Check if ray hit light
			emmision, is_emmisive := color_emitted(rec.mat, &rec, rec.u, rec.v, rec.p)
			if is_emmisive {
				accumulated_color += throughput * sanitize_color(emmision)
				break
			}

			// If the ray is absorbed, we exit the loop, otherwise we finish processing
			if srec, hit := scatter(rec.mat, current_ray, rec); !hit {
				accumulated_color += throughput * sanitize_color(emmision)
				break
			} else {
				// If we're ignoring PDF Functions
				if srec.skip_pdf {
					throughput *= srec.attenuation
					current_ray = srec.skip_pdf_ray
					continue
				}

				// Integrating PDF Function
				light_ptr := hittable_pdf(lights, rec.p)
				mixed_pdf := mixture_pdf(&light_ptr, &srec.pdf_ptr)

				scattered := new_ray(rec.p, pdf_generate(&mixed_pdf), r.tm)
				pdf_val := pdf_value(&mixed_pdf, scattered.dir)

				scattered_pdf := scatter_pdf(rec.mat, current_ray, &rec, scattered)

				throughput *= sanitize_color(srec.attenuation * scattered_pdf)
				throughput /= pdf_val

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

autofocus :: proc(cam: ^Camera, world: []Hittable) {
	AF_COLS :: 5
	AF_ROWS :: 5
	AF_MARGIN :: 0.2
	BAND_WIDTH :: 2.0

	distances := make([dynamic]f64, 0, AF_COLS * AF_ROWS)
	defer delete(distances)

	// Creat autofocus grid and shoot rays distances to first hit
	for row in 0 ..< AF_ROWS {
		for col in 0 ..< AF_COLS {
			u := 0.5 + AF_MARGIN * (f64(col) / f64(AF_COLS - 1) * 2 - 1)
			v := 0.5 + AF_MARGIN * (f64(row) / f64(AF_ROWS - 1) * 2 - 1)

			i := u * f64(cam.image_width - 1)
			j := v * f64(cam.image_height - 1)
			pixel_sample := cam.pixel00_loc + (i * cam.pixel_delta_u) + (j * cam.pixel_delta_v)

			ray_dir := pixel_sample - cam.camera_center
			r := new_ray(cam.camera_center, ray_dir)

			if rec, ok := hit_world(world, r, Interval{0.001, math.INF_F64}); ok {
				append(&distances, rec.t * linalg.length(ray_dir))
			}
		}
	}

	if len(distances) == 0 do return

	// Sort rays in order
	// then find the mode by using the distance band with most hits

	slice.sort(distances[:])

	best_start := 0
	best_count := 0
	band_start := 0

	for i in 1 ..< len(distances) {
		if distances[i] - distances[band_start] > BAND_WIDTH {
			count := i - band_start
			if count > best_count {
				best_count = count
				best_start = band_start
			}
			band_start = i
		}
	}

	count := len(distances) - band_start

	if count > best_count {
		best_count = count
		best_start = band_start
	}

	sum := 0.0
	for i in best_start ..< best_start + best_count {
		sum += distances[i]
	}
	cam.focus_dist = sum / f64(best_count)
}
