#+private file
package aoc24

import "../util"
import "core:log"
import "core:strings"

Puz :: struct {
	data:         []u8,
	maxx:         int,
	maxy:         int,
	cur_pos:      Point,
	starting_pos: Point,
	cur_dir:      Direction,
}

Point :: struct {
	x: int,
	y: int,
}

Direction :: enum {
	N = 0,
	E = 1,
	S = 2,
	W = 3,
}

dir_of :: proc(symbol: u8) -> Direction {
	switch symbol {
	case '^':
		return .N
	case '>':
		return .E
	case '<':
		return .W
	case 'v':
		return .S
	case:
		panic("Invalid direction")
	}
}

moves := []Point{Point{0, -1}, Point{1, 0}, Point{0, 1}, Point{-1, 0}}

move :: proc(puz: Puz, point: Point, dir: Direction) -> (new_point: Point, value: u8) {
	new_point = Point {
		x = point.x + moves[dir].x,
		y = point.y + moves[dir].y,
	}
	value = get(puz, new_point)
	return new_point, value
}

get :: proc(puz: Puz, p: Point) -> u8 {
	if p.x < 0 || p.x >= puz.maxx do return 0
	if p.y < 0 || p.y >= puz.maxx do return 0
	return puz.data[p.x + p.y * puz.maxx + p.y]
}

put :: proc(puz: ^Puz, p: Point, value: u8) {
	if p.x < 0 || p.x >= puz.maxx do return
	if p.y < 0 || p.y >= puz.maxx do return
	idx := p.x + p.y * puz.maxx + p.y
	puz.data[idx] = value
}

@(private = "package")
solve_d06 :: proc(part: util.Part, data: string) -> string {
	switch part {
	case .p1:
		return solve1(data)
	case .p2:
		return solve2(data)
	}
	return ""
}

parse :: proc(data: ^string) -> Puz {
	orig_allocator := context.allocator
	context.allocator = context.temp_allocator
	defer context.allocator = orig_allocator

	span := strings.index(data^, "\n")
	puz := Puz {
		data = transmute([]u8)data^,
		maxx = span,
		maxy = (len(data) / span),
	}
	for y in 0 ..< puz.maxy {
		for x in 0 ..< puz.maxx {
			p := Point{x, y}
			val := get(puz, p)
			if val == '^' {
				puz.cur_pos = p
				puz.starting_pos = p
				puz.cur_dir = .N
				return puz
			}
		}
	}
	log.error("couldn't find starting point")
	return Puz{}
}

solve2 :: proc(data: string) -> string {
	modifyable_data := strings.clone(data, allocator = context.temp_allocator)
	puz := parse(&modifyable_data)

	walk_route(&puz) // walk it once to get the path

	// get all the points on the walked path not including the starting point
	path_points := make([dynamic]Point, allocator = context.temp_allocator)
	defer (delete(path_points))

	for y := 0; y < puz.maxy; y += 1 {
		for x := 0; x < puz.maxx; x += 1 {
			cur_point := Point{x, y}
			cur_value := get(puz, cur_point)
			if cur_value == 'X' || cur_value == '^' || cur_value == 'O' {
				append(&path_points, cur_point)
				put(&puz, cur_point, '.')
			}
		}
	}

	count := find_loops(puz, path_points[:])
	return util.to_str(count)
}

find_loops :: proc(puz: Puz, path_points: []Point) -> int {
	count := 0
	// for each path point, replace it with an obstacle and see if it loops
	for p, i in path_points {
		tmp_puz := Puz {
			data         = transmute([]u8)strings.clone(string(puz.data), context.temp_allocator),
			cur_dir      = puz.cur_dir,
			cur_pos      = puz.starting_pos,
			starting_pos = puz.starting_pos,
			maxx         = puz.maxx,
			maxy         = puz.maxy,
		}
		put(&tmp_puz, p, 'O')
		if walk_route(&tmp_puz, i, true) == 0 do count += 1
	}
	return count
}

turn_right :: proc(d: Direction) -> Direction {
	return Direction((int(d) + 1) % 4)
}

solve1 :: proc(data: string) -> string {
	modifyable_data := strings.clone(data, allocator = context.temp_allocator)
	puz := parse(&modifyable_data)
	steps := walk_route(&puz)
	return util.to_str(steps)
}

hash :: proc(p: Point) -> int {
	return p.x * 1000 + p.y
}

walk_route :: proc(puz: ^Puz, i: int = -1, shortcut_loops: bool = true) -> int {

	steps := 1
	// make sure we're at the correct starting position
	puz.cur_pos = puz.starting_pos
	puz.cur_dir = .N

	// as we hit each 'X', record the direction from which it struck.
	loop_checks := make_map(
		map[int](bit_set[Direction]),
		(puz.maxx * puz.maxy) / 4,
		context.temp_allocator,
	)
	defer delete(loop_checks)

	for {
		new_pos, value := move(puz^, puz.cur_pos, puz.cur_dir)
		if value == 0 do break // exited the map
		if value == '#' || value == 'O' {
			// hit obstacle, turn right, but we didn't take a step
			puz.cur_dir = turn_right(puz.cur_dir)
			continue
		}
		if value == 'X' || value == '#' || value == 'O' {
			// we've been here before, we can step but don't count it
			key := hash(new_pos)
			visited := key in loop_checks
			if !visited {
				fresh_bits := bit_set[Direction]{}
				loop_checks[key] = fresh_bits
			}
			bits := loop_checks[key]

			// see if we've visited from this direction
			if shortcut_loops {
				if puz.cur_dir in bits {
					// we're looping
					return 0
				} else {
					bits = bits + bit_set[Direction]{puz.cur_dir}
					loop_checks[key] = bits
				}
			}
			puz.cur_pos = new_pos
			continue
		}
		if value == '.' {
			// the way is clear, take a step
			puz.cur_pos = new_pos
			steps += 1
			put(puz, new_pos, 'X')
			continue
		}
	}
	return steps
}
