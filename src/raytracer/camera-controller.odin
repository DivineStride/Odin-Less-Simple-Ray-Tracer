package raytracer

import "core:math"
import "core:math/linalg"

ACCELERATION :: 20
DAMPING :: 8.0
ANG_ACCEL :: 5.0
ANG_DAMPING :: 10.0

Camera_Mode :: union {
	Locked_Mode,
	Flight_Mode,
}

Locked_Mode :: struct {
	yaw, pitch: f64,
	ang_vel:    Vec3,
	lin_vel:    Vec3,
}

Flight_Mode :: struct {
	ang_vel: Vec3,
	lin_vel: Vec3,
}

Camera_Motion :: struct {
	move:   Vec3,
	rotate: Vec3,
	dt:     f64,
}

apply_camera_move :: proc(cam: ^Camera, mode: ^Camera_Mode, motion: Camera_Motion) {
	switch &m in mode {
	case Locked_Mode:
		apply_camera_move_locked(cam, &m, motion)
	case Flight_Mode:
		apply_camera_move_flight(cam, &m, motion)
	}
}

camera_locked_mode_init :: proc(cam: ^Camera) -> Locked_Mode {
	fwd := cam.forward
	return Locked_Mode{yaw = math.atan2(fwd.x, -fwd.z), pitch = math.asin(fwd.y)}
}

apply_camera_move_locked :: proc(cam: ^Camera, m: ^Locked_Mode, motion: Camera_Motion) {
	dt := motion.dt

	m.ang_vel.x += motion.rotate.x * ANG_ACCEL * dt
	m.ang_vel.y -= motion.rotate.y * ANG_ACCEL * dt
	m.ang_vel *= math.exp(-ANG_DAMPING * dt)

	m.pitch = math.clamp(m.pitch + m.ang_vel.x * dt, -math.PI / 2 + 0.01, math.PI / 2 - 0.01)
	m.yaw += m.ang_vel.y * dt

	cam.forward = linalg.normalize(
		Vec3 {
			math.cos(m.pitch) * math.sin(m.yaw),
			math.sin(m.pitch),
			-math.cos(m.pitch) * math.cos(m.yaw),
		},
	)

	world_up := Vec3{0, 1, 0}
	cam.right = linalg.normalize(linalg.cross(cam.forward, world_up))
	cam.up = linalg.cross(cam.right, cam.forward)

	flat_forward := linalg.normalize(Vec3{cam.forward.x, 0, cam.forward.z})
	inertia := flat_forward * -motion.move.z + cam.right * motion.move.x + world_up * motion.move.y

	m.lin_vel += inertia * ACCELERATION * dt
	m.lin_vel *= math.exp(-DAMPING * dt)
	cam.position += m.lin_vel * dt

	camera_debug(cam, "after_move")
}


apply_camera_move_flight :: proc(cam: ^Camera, m: ^Flight_Mode, motion: Camera_Motion) {
	cam.position += cam.forward * -motion.move.z
	cam.position += cam.right * motion.move.x
	cam.position += cam.up * motion.move.y

	// Yaw
	if motion.rotate.y != 0 {
		c := math.cos(motion.rotate.y)
		s := math.sin(motion.rotate.y)
		cam.forward = linalg.normalize(cam.forward * c + cam.right * s)
		cam.right = linalg.normalize(linalg.cross(cam.forward, cam.up))
	}

	// Pitch
	if motion.rotate.x != 0 {
		c := math.cos(motion.rotate.x)
		s := math.sin(motion.rotate.x)
		cam.forward = linalg.normalize(cam.forward * c + cam.up * s)
		cam.up = linalg.normalize(linalg.cross(cam.right, cam.forward))
	}

	// Roll
	if motion.rotate.z != 0 {
		c := math.cos(motion.rotate.z)
		s := math.sin(motion.rotate.z)
		cam.right = linalg.normalize(cam.right * c + cam.up * s)
		cam.up = linalg.normalize(linalg.cross(cam.right, cam.forward))
	}

	camera_reorthonormalize(cam)
}

camera_reorthonormalize :: proc(cam: ^Camera) {
	cam.forward = linalg.normalize(cam.forward)
	cam.right = linalg.normalize(linalg.cross(cam.forward, cam.up))
	cam.up = linalg.cross(cam.right, cam.forward)
}

camera_look_at :: proc(cam: ^Camera, from, at: Point3) {
	cam.position = from
	cam.forward = linalg.normalize(at - from)
	cam.right = linalg.normalize(linalg.cross(cam.forward, Vec3{0, 1, 0}))
	cam.up = linalg.cross(cam.right, cam.forward)
}
