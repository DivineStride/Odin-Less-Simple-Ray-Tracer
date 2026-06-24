package raytracer

import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:sync"
import "core:thread"
import "core:time"

CORE_COUNT := 1

Render_Details :: struct {
	image_width, samples, depth: int,
}

set_processor_core_count :: proc(override: int = 0) {
	if override > 0 {
		CORE_COUNT = override
	} else {
		CORE_COUNT = os.get_processor_core_count()
	}
}

render_rows :: proc(t: ^thread.Thread) {
	data := (^Thread_Data)(t.data)

	rng_state := rand.create(data.seed)

	context.random_generator = rand.default_random_generator(&rng_state)

	for {
		j := int(sync.atomic_add(data.next_row, 1)) - 1
		if j >= data.cam.image_height do break

		for i := 0; i < data.cam.image_width; i += 1 {
			pixel_color := Color{0, 0, 0}
			for s_j in 0 ..< data.cam.sqrt_spp {
				for s_i in 0 ..< data.cam.sqrt_spp {
					r := get_ray(data.cam, i, j, s_i, s_j)
					pixel_color += sense_color(
						r,
						data.cam.max_depth,
						data.cam.background,
						data.world,
						data.lights,
					)
				}
			}

			data.pixels[j * data.cam.image_width + i] = pixel_color
		}

		sync.atomic_add(data.scanlines_done, 1)
	}
}

render_frame_raw :: proc(
	cam: ^Camera,
	world: []Hittable,
	lights: []^Hittable,
	out: []Color,
	frame_index: int,
) {
	camera_init(cam)

	build_render_threads(cam, world, lights, out, false, frame_index)
}

render_to_buffer :: proc(cam: ^Camera, world: []Hittable, lights: []^Hittable, buf: []u32) {
	camera_init(cam)

	pixels := make([]Color, cam.image_height * cam.image_width)
	defer delete(pixels)

	build_render_threads(cam, world, lights, pixels, false)

	for c, i in pixels {
		buf[i] = color_to_xrgb(c * cam.pixel_samples_scale, cam.ev_scale)
	}
}

render_to_ppm :: proc(cam: ^Camera, world: []Hittable, lights: []^Hittable) {
	camera_init(cam)

	// Start Render Time Tracker
	render_start := time.now()

	pixels := make([]Color, cam.image_height * cam.image_width)
	defer delete(pixels)

	build_render_threads(cam, world, lights, pixels)


	// Build Image Output
	fmt.println("P3")
	fmt.printfln("%v %v", cam.image_width, cam.image_height)
	fmt.println("255")

	// Then we write to the PPM from the buffer
	for j := 0; j < cam.image_height; j += 1 {
		for i := 0; i < cam.image_width; i += 1 {
			write_color(pixels[j * cam.image_width + i] * cam.pixel_samples_scale, cam.ev_scale)
		}
	}

	// End Time Tracking
	render_end := time.now()
	duration := time.diff(render_start, render_end)

	minutes := time.duration_minutes(duration)
	seconds := time.duration_seconds(duration) - f64(int(minutes)) * 60

	console_stats(cam, duration)
	write_stats(cam, duration)
}
