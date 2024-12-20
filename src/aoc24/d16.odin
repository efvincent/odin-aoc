package aoc24

import "../util"
import pq "core:container/priority_queue"
import "core:fmt"
import "core:math"
import "core:strings"

@(private = "file")
Point :: [2]int

@(private = "file")
Direction :: enum {
	N = 0,
	E = 1,
	S = 2,
	W = 3,
}

@(private = "file")
Content :: enum {
	Wall  = '█',
	Space = ' ',
	Start = 'S',
	End   = 'E',
}

@(private = "file")
Node :: struct {
	content: Content,
	loc:     Point,
	id:      int,
	cost:    int,
}

@(private = "file")
Node2 :: struct {
	pos:  Point,
	dir:  Direction,
	cost: int,
}

@(private = "file")
Grid :: []Content

@(private = "file")
Puz :: struct {
	maxx:      int,
	grid:      []Node,
	maxy:      int,
	start:     Point,
	end:       Point,
	distances: map[int]int,
	visited:   map[int]bool,
}

@(private = "file")
Command :: struct {
	loc:   Point,
	value: Content,
}

solve_d16 :: proc(part: util.Part, data: string) -> string {
	switch part {
	case .p1:
		return solve1(data)
	case .p2:
		return solve2(data)
	}
	return ""
}

@(private = "file")
solve2 :: proc(data: string) -> string {
	return ""
}

@(private = "file")
solve1 :: proc(data: string) -> string {
	puz := parse(data)
	defer destroy_puz(&puz)
	c := find_smallest_cost(&puz)
	return util.to_str(c)
}

@(private = "file")
find_smallest_cost :: proc(puz: ^Puz) -> int {
	hash2 :: proc(loc: Point, dir: Direction) -> int {
		return int(dir) * 1000000 + loc.y * 1000 + loc.x
	}
	less :: proc(a, b: Node2) -> bool {
		return a.cost < b.cost
	}
	swap :: proc(q: []Node2, i, j: int) {
		q[i], q[j] = q[j], q[i]
	}

	smallest_cost := max(int)
	visited := make(map[int]struct {})
	distance := make(map[int]int)
	queue: pq.Priority_Queue(Node2)
	defer {
		delete(visited)
		delete(distance)
		pq.destroy(&queue)
	}

	// initialize the queue with the starting position
	pq.init(&queue, less, swap)
	pq.push(&queue, Node2{puz.start, .E, 0})

	for pq.len(queue) > 0 {
		cur_node := pq.pop(&queue)
		cur_node_id := hash2(cur_node.pos, cur_node.dir)
		visited[cur_node_id] = {}
		if get(puz^, cur_node.pos).content == .End {
			smallest_cost = smallest_cost < cur_node.cost ? smallest_cost : cur_node.cost
			continue
		}
		for n in 0 ..< 4 {
			// check each dir from the current pos
			next_pos: Point
			ok: bool
			dir := Direction(n)

			// if the move in the current dir is not allowed, continue to next dir
			if next_pos, ok = can_move(puz^, nil, cur_node.pos, dir, false); !ok {
				continue
			}

			// if we've visited this node from this direction, continue to next dir
			if hash2(next_pos, dir) in visited {
				continue
			}

			next_cost := cur_node.cost + 1 + cost_change(cur_node.dir, dir)
			next_node_id := hash2(next_pos, dir)
			prev_cost: int

			// have we visited this node at a cheaper cost?
			if prev_cost, ok = distance[next_node_id]; ok && prev_cost < next_cost {
				continue
			}

			if next_cost >= smallest_cost {
				continue
			}
			distance[next_node_id] = next_cost
			pq.push(&queue, Node2{next_pos, dir, next_cost})
		}
	}
	return smallest_cost
}

@(private = "file")
cost_change :: proc(a: Direction, b: Direction) -> int {
	d1 := int(a)
	d2 := int(b)
	if d1 == d2 do return 0
	diff := int(math.abs(d1 - d2))
	dist := math.min(diff, 4 - diff)
	if dist == 1 do return 1000
	return 2000
}

// -------------------------------------------------------------------------

@(private = "file")
parse :: proc(data: string) -> Puz {
	puz: Puz
	raw_lines := strings.split_lines(data, allocator = context.temp_allocator)
	puz.maxy = len(raw_lines)
	first := true
	cost: int
	for raw_line, y in raw_lines {
		if first {
			first = false
			puz.maxx = len(raw_line)
			puz.grid = make([]Node, puz.maxy * puz.maxx)
			puz.distances = make(map[int]int)
			puz.visited = make(map[int]bool)
		}
		for char, x in raw_line {
			loc := Point{x, y}
			cost = max(int)
			if char == 'S' {
				puz.start = loc
				cost = 0
			} else if char == 'E' {
				puz.end = loc
			}
			char_mod: rune
			if char == '.' do char_mod = ' '
			else if char == '#' do char_mod = '█'
			else do char_mod = char
			puz.distances[hash(loc)] = cost
			put(
				&puz,
				loc,
				Node{content = Content(char_mod), cost = cost, loc = loc, id = hash(loc)},
			)
		}
	}

	return puz
}

// -------------------------------------------------------------------------

@(private = "file")
can_move :: proc(
	puz: Puz,
	visited: map[int]struct {},
	loc: Point,
	dir: Direction,
	check_visited: bool = true,
) -> (
	moved: Point,
	ok: bool,
) {
	moved = shift(loc, dir)
	if get(puz, moved).content == Content.Wall do return loc, false
	if inbounds(puz, loc) && (!check_visited || !(hash(moved) in visited)) do return moved, true
	return loc, false
}

@(private = "file")
ppuz :: proc(puz: Puz, visited: map[int]struct {} = nil) {
	for y in 0 ..< puz.maxy {
		for x in 0 ..< puz.maxx {
			p := Point{x, y}
			c := rune(get(puz, p).content)
			if c == rune(Content.Wall) {
				fmt.printf("%v%v", c, c)
			} else if visited != nil && c == rune(Content.Space) && hash(p) in visited {
				fmt.print(". ")
			} else {
				fmt.printf("%v ", c)
			}
		}
		fmt.println()
	}
	fmt.printfln("Start: (%v,%v)\nEnd:   (%v,%v)", puz.start.x, puz.start.y, puz.end.x, puz.end.y)
}

@(private = "file")
destroy_puz :: proc(puz: ^Puz) {
	delete(puz.grid)
	delete(puz.distances)
	delete(puz.visited)
}

@(private = "file")
inbounds :: #force_inline proc(puz: Puz, loc: Point) -> bool {
	return !(loc.x < 0 || loc.x >= puz.maxx || loc.y < 0 || loc.y >= puz.maxy)
}

@(private = "file")
get :: #force_inline proc(puz: Puz, loc: Point) -> Node {
	if !inbounds(puz, loc) do return Node{}
	return puz.grid[loc.y * puz.maxy + loc.x]
}

@(private = "file")
put :: #force_inline proc(puz: ^Puz, loc: Point, node: Node) -> bool {
	if !inbounds(puz^, loc) do return false
	puz.grid[loc.y * puz.maxy + loc.x] = node
	return true
}

@(private = "file")
record :: #force_inline proc(visited: ^map[int]struct {}, loc: Point) {
	key := hash(loc)
	visited[key] = {}
}

@(private = "file")
erase :: #force_inline proc(visited: ^map[int]struct {}, loc: Point) {
	key := hash(loc)
	delete_key(visited, key)
}

@(private = "file")
hash :: #force_inline proc(loc: Point) -> int {
	return loc.y * 1000 + loc.x
}

@(private = "file")
shift :: #force_inline proc(loc: Point, dir: Direction) -> Point {
	new_loc: Point
	switch dir {
	case .N:
		new_loc = loc + {0, -1}
	case .S:
		new_loc = loc + {0, 1}
	case .E:
		new_loc = loc + {1, 0}
	case .W:
		new_loc = loc + {-1, 0}
	}
	return new_loc
}

@(private = "file")
solve1x :: proc(data: string) -> string {
	puz := parse(data)
	defer destroy_puz(&puz)
	ppuz(puz)
	visited := make_map(map[int]struct {}, allocator = context.temp_allocator)
	cost, _ := walk(&puz, puz.start, Direction.E, 0, &visited)
	ppuz(puz, visited)
	return util.to_str(cost)
}

walk :: proc(
	puz: ^Puz,
	current_loc: Point,
	facing: Direction,
	sub_cost: int,
	visited: ^map[int]struct {}, // a set of points
) -> (
	cost: int,
	ok: bool,
) {
	fmt.printfln("(%v,%v) %v", current_loc.x, current_loc.y, facing)

	// are we at the end?
	if get(puz^, current_loc).content == Content.End {
		// don't need to record that we were here, since we won't be 
		// taking any more steps
		fmt.println("  END!")
		return sub_cost, true
	}

	moved: Point

	// can I move in the direction I'm already facing?
	if moved, ok = can_move(puz^, visited^, current_loc, facing); ok {
		// We can move in the facing direction without turning
		// record that we were here, so that if we're ever here again we'll know
		fmt.println("  moving forward")
		record(visited, current_loc)
		cost, ok = walk(puz, moved, facing, sub_cost + 1, visited)
		if ok do return
		erase(visited, current_loc)
	}
	// try turning right
	right := Direction((int(facing) + 1) % 4)
	if moved, ok = can_move(puz^, visited^, current_loc, right); ok {
		fmt.println("  turning right")
		record(visited, current_loc)
		cost, ok = walk(puz, moved, right, sub_cost + 1000 + 1, visited)
		if ok do return
		erase(visited, current_loc)
	}
	// try turning left
	left := facing == Direction.N ? Direction.W : Direction(int(facing) - 1)
	if moved, ok = can_move(puz^, visited^, current_loc, left); ok {
		fmt.println("  turning left")
		record(visited, current_loc)
		cost, ok = walk(puz, moved, left, sub_cost + 1000 + 1, visited)
		if ok do return
		erase(visited, current_loc)
	}
	fmt.println("  can't move, backtracking")
	return 0, false
}
