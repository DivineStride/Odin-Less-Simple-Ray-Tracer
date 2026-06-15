package editor

import rt "../raytracer/"
import sdl "vendor:sdl3"

Key_Pressed :: struct {
	key: string,
}

handle_keyboard_press :: proc(key_scancode: sdl.Scancode, ctx: ^rt.Render_Context) -> bool {
	#partial switch key_scancode {
	case .ESCAPE:
		return false
	}

	return true
}

camera_movement :: proc(dt: f64) -> rt.Camera_Motion {
	keys := sdl.GetKeyboardState(nil)
	move := rt.Camera_Motion {
		dt = dt,
	}

	speed :: 10.0
	turn_speed :: 5.0

	if keys[sdl.Scancode.W] do move.move.z -= speed * dt
	if keys[sdl.Scancode.S] do move.move.z += speed * dt
	if keys[sdl.Scancode.A] do move.move.x -= speed * dt
	if keys[sdl.Scancode.D] do move.move.x += speed * dt
	if keys[sdl.Scancode.E] do move.move.y -= speed * dt
	if keys[sdl.Scancode.Q] do move.move.y += speed * dt

	if keys[sdl.Scancode.LEFT] do move.rotate.y -= turn_speed * dt
	if keys[sdl.Scancode.RIGHT] do move.rotate.y += turn_speed * dt
	if keys[sdl.Scancode.UP] do move.rotate.x -= turn_speed * dt
	if keys[sdl.Scancode.DOWN] do move.rotate.x += turn_speed * dt

	return move
}

camera_has_movement :: proc(movement: rt.Camera_Motion) -> bool {
	zero := rt.Camera_Motion{}
	return movement.move != zero.move || movement.rotate != zero.rotate
}

set_key_pressed :: proc(key_logger: ^Key_Pressed, key: string) {
	key_logger.key = key
}
