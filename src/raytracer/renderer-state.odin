package raytracer

import "core:sync"
import "core:thread"

Render_State :: enum u32 {
	Idle,
	Requested,
	Running,
	Done,
}

Render_Context :: struct {
	state:                u32,
	cam:                  Camera,
	camera_mode:          Camera_Mode,
	scene:                Scene,
	pixel_buf:            []u32,
	accum:                []Color,
	scratch:              []Color,
	sample_count:         int,
	scratch_sample_scale: f64,
	mutex:                sync.Mutex,
}

render_get_state :: proc(ctx: ^Render_Context) -> Render_State {
	return Render_State(sync.atomic_load(&ctx.state))
}

render_set_state :: proc(ctx: ^Render_Context, s: Render_State) {
	sync.atomic_store(&ctx.state, u32(s))
}

accumulate_and_display :: proc(ctx: ^Render_Context) {
	ctx.sample_count += 1
	inv := 1.0 / f64(ctx.sample_count)
	// fmt.eprintln(
	// 	"accum: sample",
	// 	ctx.sample_count,
	// 	"scratch[0]:",
	// 	ctx.scratch[0],
	// 	"ev_scale:",
	// 	ctx.cam.ev_scale,
	// )
	for i in 0 ..< len(ctx.accum) {
		ctx.accum[i] += ctx.scratch[i] * ctx.scratch_sample_scale
		avg := ctx.accum[i] * inv
		ctx.pixel_buf[i] = color_to_xrgb(avg, ctx.cam.ev_scale)
	}
}

display_scratch :: proc(ctx: ^Render_Context) {
	for i in 0 ..< len(ctx.scratch) {
		ctx.pixel_buf[i] = color_to_xrgb(
			ctx.scratch[i] * ctx.scratch_sample_scale,
			ctx.cam.ev_scale,
		)
	}
}

accumulate_reset :: proc(ctx: ^Render_Context) {
	for i in 0 ..< len(ctx.accum) do ctx.accum[i] = Color{0, 0, 0}
	ctx.sample_count = 0
}

render_worker :: proc(t: ^thread.Thread) {
	ctx := (^Render_Context)(t.data)

	sync.mutex_lock(&ctx.mutex)
	cam_snapshot := ctx.cam
	frame_idx := ctx.sample_count
	ctx.scratch_sample_scale = cam_snapshot.pixel_samples_scale
	sync.mutex_unlock(&ctx.mutex)

	render_set_state(ctx, .Running)
	// This is where we actually draw the scene that we got from the camera
	// Everything that was captured earlier, has been frozen until this point
	// If we want more samples, we'll need a way to increase the amount of samples over a period of time
	// While maintaining the samples that we've already taken.
	render_frame_raw(
		&cam_snapshot,
		ctx.scene.bvh_world[:],
		ctx.scene.lights[:],
		ctx.scratch,
		frame_idx,
	)

	render_set_state(ctx, .Done)
}
