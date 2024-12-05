package aoc24

import "../util"
import "core:fmt"
import "core:log"
import "core:math"
import "core:slice"
import conv "core:strconv"
import "core:strings"
import "core:testing"

Puz :: struct {
	data: []u8,
	maxx: int,
	maxy: int,
}

@(test)
D04_test_parse :: proc(t: ^testing.T) {
}

@(test)
D04_part01_test :: proc(t: ^testing.T) {
}

@(test)
D04_part02_test :: proc(t: ^testing.T) {
}

solve_D04 :: proc(part: util.Part, data: string) -> string {
	switch part {
	case .p1:
		return solve1(data)
	case .p2:
		return solve2(data)
	}
	return ""
}

@(private = "file")
parse :: proc(data: string) -> Puz {
	orig_allocator := context.allocator
	context.allocator = context.temp_allocator
	defer context.allocator = orig_allocator
	span := strings.index(data, "\n")
	return Puz{data = transmute([]u8)data, maxx = span, maxy = (len(data) / span)}
}

get :: proc(puz: Puz, x: int, y: int) -> u8 {
	if x < 0 || x >= puz.maxx do return 0
	if y < 0 || y >= puz.maxx do return 0
	return puz.data[x + y * puz.maxx + y]
}

// be nice to use a generator to find the Xs
xmas_dirs :: [?][]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}, {1, 1}, {1, -1}, {-1, 1}, {-1, -1}}

look_for_xmas :: proc(puz: Puz, lookfor: []u8, x, y: int) -> int {
	count := 0
	for dir in xmas_dirs {
		if has_xmas(puz, lookfor, x, y, dir[0], dir[1]) {
			count += 1
		}
	}
	return count
}

@(private = "file")
solve1 :: proc(data: string) -> string {
	puz := parse(data)
	lookfor := transmute([]u8)string("XMAS")
	total := 0
	for y in 0 ..< puz.maxy {
		for x in 0 ..< puz.maxx {
			if get(puz, x, y) == 'X' {
				total += look_for_xmas(puz, lookfor, x, y)
			}
		}
	}
	return util.to_str(total)
}

has_xmas :: proc(puz: Puz, comp: []u8, x: int, y: int, xdir: int, ydir: int) -> bool {
	// start at x,y, going in xdir,ydir, comp each of comp
	curx := x
	cury := y
	for c in comp {
		if c != get(puz, curx, cury) do return false
		curx += xdir
		cury += ydir
	}
	return true
}

@(private = "file")
solve2 :: proc(data: string) -> string {
	puz := parse(data)
	total := 0
	for y in 0 ..< puz.maxy {
		for x in 0 ..< puz.maxx {
			if get(puz, x, y) == 'A' {
				total += look_for_x(puz, x, y)
			}
		}
	}

	return util.to_str(total)
}

x_diag :: [?][]int{{-1, -1}, {1, -1}, {1, 1}, {1, -1}}
x_straight :: [?][]int{{0, -1}, {1, 0}, {0, 1}, {-1, 0}}
look_for_x :: proc(puz: Puz, x, y: int) -> int {
	n := 0
	return n
}
