#+private file
package aoc24

import "../util"
import "core:fmt"
import "core:slice"
import conv "core:strconv"
import "core:strings"
import rx "core:text/regex"

Point :: [2]int
Vec2 :: [2]int

Robot :: struct {
	pos: Point,
	vel: Vec2,
}

Puz :: struct {
	robots: [dynamic]Robot,
	data:   []u8,
	maxx:   int,
	maxy:   int,
}

@(private = "package")
solve_d14 :: proc(part: util.Part, data: string) -> string {
	switch part {
	case .p1:
		return solve1(data)
	case .p2:
		return solve2(data)
	}
	return ""
}

mk_robot :: proc(input: string) -> Robot {
	re, _ := rx.create(
		`p=(-?\d+),(-?\d+) v=(-?\d+),(-?\d+)`,
		permanent_allocator = context.temp_allocator,
	)
	m, _ := rx.match(re, input, permanent_allocator = context.temp_allocator)

	p1, _ := conv.parse_int(m.groups[1])
	p2, _ := conv.parse_int(m.groups[2])
	v1, _ := conv.parse_int(m.groups[3])
	v2, _ := conv.parse_int(m.groups[4])

	return Robot{{p1, p2}, {v1, v2}}
}

tick :: proc(puz: ^Puz) {
	wrap_point :: proc(p: ^Point, puz: Puz) {
		if p.x < 0 {
			p.x += puz.maxx
		} else if p.x >= puz.maxx {
			p.x -= puz.maxx
		}
		if p.y < 0 {
			p.y += puz.maxy
		} else if p.y >= puz.maxy {
			p.y -= puz.maxy
		}
	}

	for &robot in puz.robots {
		robot.pos += robot.vel
		wrap_point(&robot.pos, puz^)
	}
}

count_quads :: proc(puz: Puz) -> (quad_counts: [4]int) {
	for y in 0 ..< puz.maxy {
		for x in 0 ..< puz.maxx {
			for robot in puz.robots {
				quad := quad_of(puz, robot.pos)
				if quad != -1 && robot.pos == (Point{x, y}) {
					quad_counts[quad] += 1
				}
			}
		}
	}
	return quad_counts
}

ppuz :: proc(puz: Puz, iter: int, quads: bool = true) {
	fmt.println("\nIteration", iter)
	for y in 0 ..< puz.maxy {
		for x in 0 ..< puz.maxx {
			count := 0
			for robot in puz.robots {
				if quad_of(puz, robot.pos) != -1 && robot.pos == (Point{x, y}) {
					count += 1
				}
			}
			if quads && quad_of(puz, Point{x, y}) == -1 {
				fmt.print("█")
			} else if count > 0 {
				fmt.print(count)
			} else {
				fmt.print(".")
			}
		}
		fmt.println()
	}
}

quad_of :: proc(puz: Puz, p: Point) -> int {
	mx := puz.maxx / 2
	my := puz.maxy / 2
	if p.x < mx {
		if p.y < my do return 0
		if p.y > my do return 2
	} else if p.x > mx {
		if p.y < my do return 1
		if p.y > my do return 3
	}
	return -1
}

parse :: proc(data: string, puz: ^Puz) {
	raw_lines := strings.split_lines(data, allocator = context.temp_allocator)
	if len(raw_lines) <= 12 {
		puz.maxx = 11
		puz.maxy = 7
	} else {
		puz.maxx = 101
		puz.maxy = 103
	}
	for line in raw_lines {
		robot := mk_robot(line)
		append(&puz.robots, robot)
	}
	return
}

solve2 :: proc(data: string) -> string {
	MAX_ITERS :: 10000
	result := 0
	robots := make_dynamic_array([dynamic]Robot, allocator = context.temp_allocator)
	puz := Puz {
		robots = robots,
	}
	parse(data, &puz)
	max_vert := 0
	for iter in 1 ..= MAX_ITERS {
		tick(&puz)
		biggest_vert := 0
		for x in 0 ..< puz.maxx {
			cur_vert := biggest_vertical(puz, x)
			if cur_vert > biggest_vert {
				biggest_vert = cur_vert
			}
		}
		if biggest_vert > max_vert && iter > 1000 {
			max_vert = biggest_vert
			result = iter
		}
	}

	return util.to_str(result)
}

biggest_vertical :: proc(puz: Puz, x: int) -> int {
	biggest := 0
	cur_line := 0
	last_bot: Robot
	in_a_line := false
	bots_here := make_dynamic_array([dynamic]Robot, allocator = context.temp_allocator)
	for robot in puz.robots {
		if robot.pos.x == x {
			append(&bots_here, robot)
		}
	}
	// sort the bots by their y position so we can scan them and detect
	// any gaps in the line and longest continuous line of bots
	slice.sort_by(bots_here[:], proc(a: Robot, b: Robot) -> bool {return a.pos.y < b.pos.y})
	for bot in bots_here {
		if !in_a_line {
			cur_line = 1
			last_bot = bot
			in_a_line = true
		} else {
			if bot.pos.y - last_bot.pos.y > 1 {
				// a break in the line
				if cur_line > biggest {
					biggest = cur_line
				}
				in_a_line = false
			} else if bot.pos.y - last_bot.pos.y == 1 {
				// line continues (don't count multiple bots in the same spot)
				biggest += 1
			}
		}
	}
	return biggest
}

solve1 :: proc(data: string) -> string {
	ITERS :: 100
	robots := make_dynamic_array([dynamic]Robot, allocator = context.temp_allocator)
	puz := Puz {
		robots = robots,
	}
	parse(data, &puz)
	for _ in 1 ..= ITERS {
		tick(&puz)
	}
	quad_counts := count_quads(puz)

	return util.to_str(quad_counts[0] * quad_counts[1] * quad_counts[2] * quad_counts[3])
}
