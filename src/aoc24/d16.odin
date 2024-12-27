package aoc24

import "../util"
import pq "core:container/priority_queue"
import "core:fmt"
import "core:math"
import "core:slice"
import "core:strings"

@(private = "file")
Point :: [2]int

@(private = "file")
Dir :: enum {
	N = 0,
	E = 1,
	S = 2,
	W = 3,
}

@(private = "file")
Content :: enum {
	Wall    = '█',
	Space   = ' ',
	Start   = 'S',
	End     = 'E',
	Visited = 'O',
	V2      = '?',
}

@(private = "file")
Node :: struct {
	pos:       Point,
	dir:       Dir,
	cost:      int,
	preds:     [3]Point,
	num_preds: u8,
	visited:   bool,
}

@(private = "file")
Grid :: struct {
	max:     [2]int,
	content: []Content,
	start:   Point,
	end:     Point,
}

@(private = "file")
Puz :: struct {
	maxx:  int,
	grid:  []Content,
	maxy:  int,
	start: Point,
	end:   Point,
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
	grid := parse(data)
	pgrid(grid)
	defer delete(grid.content)
	p1, p2 := part1(&grid)
	pgrid(grid)
	fmt.println(p1, p2)
	return util.to_str(p1)
}

// -------------------------------------------------------------------------

@(private = "file")
part1 :: proc(grid: ^Grid) -> (int, int) {
	ok: bool
	queue: pq.Priority_Queue(Node)
	pq.init(&queue, node_less_cost, node_swap)

	// initialize all the nodes
	nodes := make(map[Point]Node)
	for y in 0 ..< grid.max.y {
		for x in 0 ..< grid.max.x {
			p := Point{x, y}
			if c := get(grid^, p); c != nil && c != .Wall {
				n := Node {
					pos     = p,
					dir     = .E,
					cost    = c == .Start ? 0 : max(int),
					visited = false,
				}
				nodes[p] = n
			}
		}
	}
	pq.push(&queue, nodes[grid.start])

	for {
		// set current node to the lowest cost node, should be the start node
		// the first time through. From then on, it's the lowest cost node
		if pq.len(queue) == 0 do break
		cur := pq.pop(&queue)

		// consider all unvisited neighbors
		for dir_to_nbr in Dir {
			// neighbor position
			nbr_pos := shift(cur.pos, dir_to_nbr)
			nbr: Node
			if nbr, ok = nodes[nbr_pos]; ok {
				// neighbor is an unvisited node
				// how much would it cost to get there?
				new_cost := cur.cost + 1 + cost_change(cur.dir, dir_to_nbr)
				if new_cost == nbr.cost {
					fmt.printfln(
						"new cost: %v == nbr cost: %v  num_preds: %v cur (%v,%v) nbr (%v,%v)",
						new_cost,
						nbr.cost,
						nbr.num_preds,
						cur.pos.x,
						cur.pos.y,
						nbr.pos.x,
						nbr.pos.y,
					)
					nbr.dir = dir_to_nbr
					nbr.preds[nbr.num_preds] = cur.pos
					nbr.num_preds += 1
					nodes[nbr.pos] = nbr
					fmt.printfln("changed %v", nodes[nbr.pos])
					pq.push(&queue, nbr)
				} else if new_cost < nbr.cost {
					fmt.printfln(
						"new cost: %v < nbr cost: %v  num_preds: %v cur (%v,%v) nbr (%v,%v)",
						new_cost,
						nbr.cost,
						nbr.num_preds,
						cur.pos.x,
						cur.pos.y,
						nbr.pos.x,
						nbr.pos.y,
					)
					nbr.cost = new_cost
					nbr.dir = dir_to_nbr
					nbr.preds[0] = cur.pos
					nbr.num_preds = 1
					nodes[nbr.pos] = nbr
					pq.push(&queue, nbr)
				}
			}
		}

		// mark current node as visited. it's already removed from the
		// queue from the pop at the start of the loop
		cur.visited = true
		nodes[cur.pos] = cur
	}

	// update grid with visited content by backtracking from the end through the preds
	cur := nodes[grid.end]
	path_count := make(map[Point]struct {}, allocator = context.temp_allocator)
	for {
		if cur.num_preds == 0 do break
		for idx in 0 ..< cur.num_preds {
			cur = nodes[cur.preds[idx]]
			put(grid, cur.pos, cur.num_preds == 1 ? .Visited : .V2)
			path_count[cur.pos] = {}
		}
		if cur.pos == grid.end do continue
		if cur.pos == grid.start do break
	}
	return nodes[grid.end].cost, len(path_count)
}

// -------------------------------------------------------------------------

@(private = "file")
parse :: proc(data: string) -> Grid {
	grid: Grid
	raw_lines := strings.split_lines(data, allocator = context.temp_allocator)
	grid.max.y = len(raw_lines)
	first := true
	cost: int
	for raw_line, y in raw_lines {
		if first {
			first = false
			grid.max.x = len(raw_line)
			grid.content = make([]Content, grid.max.y * grid.max.x)
		}
		for char, x in raw_line {
			loc := Point{x, y}
			if char == 'S' {
				grid.start = loc
			} else if char == 'E' {
				grid.end = loc
			}
			char_mod: rune
			if char == '.' do char_mod = ' '
			else if char == '#' do char_mod = '█'
			else do char_mod = char
			put(&grid, loc, Content(char_mod))
		}
	}
	return grid
}

@(private = "file")
cost_change :: proc(a: Dir, b: Dir) -> int {
	d1 := int(a)
	d2 := int(b)
	if d1 == d2 do return 0
	diff := int(math.abs(d1 - d2))
	dist := math.min(diff, 4 - diff)
	if dist == 1 do return 1000
	return 2000
}

@(private = "file")
can_move :: proc(
	grid: Grid,
	visited: map[int]struct {},
	loc: Point,
	dir: Dir,
	check_visited: bool = true,
) -> (
	moved: Point,
	ok: bool,
) {
	moved = shift(loc, dir)
	if get(grid, moved) == Content.Wall do return loc, false
	if inbounds(grid, loc) && (!check_visited || !(hash(moved) in visited)) do return moved, true
	return loc, false
}

@(private = "file")
pgrid :: proc(grid: Grid, visited: map[int]struct {} = nil) {
	for y in 0 ..< grid.max.y {
		for x in 0 ..< grid.max.x {
			p := Point{x, y}
			c := rune(get(grid, p))
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
	fmt.printfln(
		"Start: (%v,%v)\nEnd:   (%v,%v)",
		grid.start.x,
		grid.start.y,
		grid.end.x,
		grid.end.y,
	)
}

@(private = "file")
inbounds :: #force_inline proc(grid: Grid, loc: Point) -> bool {
	return !(loc.x < 0 || loc.x >= grid.max.x || loc.y < 0 || loc.y >= grid.max.y)
}

@(private = "file")
get :: #force_inline proc(grid: Grid, loc: Point) -> Content {
	if !inbounds(grid, loc) do return nil
	return grid.content[loc.y * grid.max.y + loc.x]
}

@(private = "file")
put :: #force_inline proc(grid: ^Grid, loc: Point, content: Content) -> bool {
	if !inbounds(grid^, loc) do return false
	grid.content[loc.y * grid.max.y + loc.x] = content
	return true
}

@(private = "file")
hash :: proc(loc: Point, dir: Dir = .N) -> int {
	return int(dir) * 1000000 + loc.y * 1000 + loc.x
}

@(private = "file")
destroy_puz :: proc(puz: ^Puz) {
	delete(puz.grid)
}

@(private = "file")
shift :: #force_inline proc(loc: Point, dir: Dir) -> Point {
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
node_less_cost :: proc(a, b: Node) -> bool {
	return a.cost < b.cost
}

@(private = "file")
node_swap :: proc(q: []Node, i, j: int) {q[i], q[j] = q[j], q[i]}
