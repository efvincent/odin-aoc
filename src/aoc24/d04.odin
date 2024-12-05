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

look_for_xmas :: proc(puz: Puz, lookfor: []u8, x, y: int) -> int {
	xmas_dirs :: [?][]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}, {1, 1}, {1, -1}, {-1, 1}, {-1, -1}}
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
				//fmt.printfln("A:(%v,%v)", x, y)
				if look_for_x(puz, x, y) {
					total += 1
				}
			}
		}
	}

	return util.to_str(total)
}

check_each :: proc(puz: Puz, orients: [][]int, x, y: int) -> bool {

	p1, p2, p3, p4: []int

	for orientation in 1 ..= 1 {
		for mod in 0 ..= 3 {
			p1 = orients[(mod + 0) % 4]
			p2 = orients[(mod + 1) % 4]
			p3 = orients[(mod + 2) % 4]
			p4 = orients[(mod + 3) % 4]

			if get(puz, p1[0] + x, p1[1] + y) == 'M' &&
			   get(puz, p2[0] + x, p2[1] + y) == 'M' &&
			   get(puz, p3[0] + x, p3[1] + y) == 'S' &&
			   get(puz, p4[0] + x, p4[1] + y) == 'S' {
				return true
			}
		}
	}
	return false
}

look_for_x :: proc(puz: Puz, x, y: int) -> bool {
	TOP_RIGHT :: []int{1, -1}
	BOT_RIGHT :: []int{1, 1}
	BOT_LEFT :: []int{-1, 1}
	TOP_LEFT :: []int{-1, -1}

	diagonals := [][]int{TOP_RIGHT, BOT_RIGHT, BOT_LEFT, TOP_LEFT}

	return check_each(puz, diagonals, x, y)
}
