package raytracer

import "core:fmt"
import "core:math"
import "core:os"
import "core:sync"
import "core:thread"
import "core:time"

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

write_stats :: proc(cam: ^Camera, duration: time.Duration) {
	num_threads := os.get_processor_core_count()
	total_rays := cam.image_width * cam.image_height * cam.samples_per_pixel
	mrays_per_sec := f64(total_rays) / time.duration_seconds(duration) / 1_000_000

	line := fmt.aprintf(
		"%d,%d,%d,%d,%dmm,f/%.1f,%.0f units,%s,1/%.03f,%d,%d,%.2f,%.4f\n",
		// Path Tracer
		cam.image_width,
		cam.image_height,
		cam.samples_per_pixel,
		cam.max_depth,
		// Physical Camera
		cam.focal_length_mm,
		cam.fstop,
		cam.focus_dist,
		aperture_stats(cam),
		cam.exposure,
		cam.iso,
		// Work completed
		CORE_COUNT,
		time.duration_seconds(duration),
		mrays_per_sec,
	)

	defer delete(line)

	flags := os.O_WRONLY | os.O_APPEND | os.O_CREATE
	if f, err := os.open("render_stats.csv", flags); err == os.ERROR_NONE {
		os.write_string(f, line)
		os.close(f)
	}
}

console_stats :: proc(cam: ^Camera, duration: time.Duration) {
	total_rays := cam.image_width * cam.image_height * cam.samples_per_pixel
	mrays_per_sec := f64(total_rays) / time.duration_seconds(duration) / 1_000_000
	minutes := int(time.duration_seconds(duration)) / 60
	seconds := time.duration_seconds(duration) - f64(minutes * 60)

	fmt.eprintf(
		"-----\n" +
		"Render completed\n" +
		"  Resolution:  %dx%d\n" +
		"  Samples:     %d    Depth: %d    Threads: %d\n" +
		"  Focal:       %dmm   f/%.1f\n" +
		"  Aperture:    %s\n" +
		"  ISO:         %d     Exposure: 1/%.0fs\n" +
		"  Time:        %dm %.2fs\n" +
		"  Mrays/sec:   %.4f\n\n",
		cam.image_width,
		cam.image_height,
		cam.samples_per_pixel,
		cam.max_depth,
		CORE_COUNT,
		cam.focal_length_mm,
		cam.fstop,
		aperture_stats(cam),
		cam.iso,
		1.0 / cam.exposure,
		minutes,
		seconds,
		mrays_per_sec,
	)
}

aperture_stats :: proc(cam: ^Camera) -> string {
	diameter_mm := f64(cam.focal_length_mm) / cam.fstop

	switch a in cam.aperture {
	case Aperture_Circle:
		return fmt.aprintf("Circle (∅%.1fmm)", diameter_mm)
	case Aperture_Polygon:
		return fmt.aprintf("%d-blade", a.blades)
	case Aperture_Star:
		return fmt.aprintf("%d-point star", a.points)
	case Aperture_Custom:
		return fmt.aprintf("%s (∅%.2fmm)", a.name, widest_diameter(a.vertices))
	}
	return "Aperture Successfully avoided"
}

widest_diameter :: proc(verts: []Vec2) -> f64 {
	max_dist := 0.0
	for i in 0 ..< len(verts) {
		for j in i + 1 ..< len(verts) {
			dx := verts[i].x - verts[j].x
			dy := verts[i].y - verts[j].y
			d := math.sqrt(dx * dx + dy * dy)
			if d > max_dist {max_dist = d}
		}
	}

	return max_dist
}
