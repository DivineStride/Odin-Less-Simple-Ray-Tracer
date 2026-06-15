package raytracer

import "core:fmt"
import "core:math/rand"
import "core:sync"
import "core:thread"
import "core:time"

Thread_Data :: struct {
	cam:            ^Camera,
	world:          []Hittable,
	pixels:         []Color,
	next_row:       ^i64,
	scanlines_done: ^i64,
	id:             int,
	seed:           u64,
}

Progress_Data :: struct {
	scanlines_done:  ^i64,
	total_scanlines: int,
}

build_render_threads :: proc(
	cam: ^Camera,
	world: []Hittable,
	pixels: []Color,
	show_progress := true,
	seed_multiplier := 1,
) {
	// Then we divide tasks for each thread to process
	scanlines_done: i64 = 0
	next_row: i64 = 1

	threads := make([]^thread.Thread, CORE_COUNT)
	thread_data := make([]Thread_Data, CORE_COUNT)
	defer delete(threads)
	defer delete(thread_data)


	// We iterate through the tasks and save everything to a slice
	for i in 0 ..< CORE_COUNT {
		thread_data[i] = Thread_Data {
			cam            = cam,
			world          = world,
			pixels         = pixels,
			next_row       = &next_row,
			scanlines_done = &scanlines_done,
			id             = i,
			seed           = (u64(i) * rand.uint64() + rand.uint64()) * u64(seed_multiplier + 1),
		}
		threads[i] = thread.create(render_rows)
		threads[i].data = &thread_data[i]
		thread.start(threads[i])
	}

	if show_progress {
		progress_data := Progress_Data {
			scanlines_done  = &scanlines_done,
			total_scanlines = cam.image_height,
		}

		progress_thread := thread.create(track_scanlines)
		progress_thread.data = &progress_data
		thread.start(progress_thread)

		thread.join(progress_thread)
		thread.destroy(progress_thread)
	}

	// Remove the threads so we don't do unsafe things with memory
	for t in threads {
		thread.join(t)
		thread.destroy(t)
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
			for s := 0; s < data.cam.samples_per_pixel; s += 1 {
				r := get_ray(data.cam, i, j)
				pixel_color += sense_color(r, data.cam.max_depth, data.cam.background, data.world)
			}

			data.pixels[j * data.cam.image_width + i] = pixel_color
		}

		sync.atomic_add(data.scanlines_done, 1)
	}
}

track_scanlines :: proc(t: ^thread.Thread) {
	data := (^Progress_Data)(t.data)

	for {
		done := sync.atomic_load(data.scanlines_done)
		fmt.eprintf("\rScanlines remaining: %v    ", data.total_scanlines - int(done))

		if int(done) >= data.total_scanlines do break
		time.sleep(100 * time.Millisecond)
	}

	fmt.eprintf("\rDone.                   \n")
}
