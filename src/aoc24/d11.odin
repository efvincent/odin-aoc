package aoc24

import "../util"
import conv "core:strconv"
import "core:strings"

@(private = "file")
Puz :: []u64

@(private = "file")
SplitResult :: union {
	SingleStone,
	TwoStones,
}

@(private = "file")
SingleStone :: u64

@(private = "file")
TwoStones :: [2]u64

@(private = "file")
ProcessedStoneCacheKey :: struct {
	stone_num:   u64,
	blink_count: u64,
}

@(private = "file")
stone_processor_cache: map[ProcessedStoneCacheKey]u64

solve_d11 :: proc(part: util.Part, data: string) -> string {
	switch part {
	case .p1:
		return solve(data, 25)
	case .p2:
		return solve(data, 75)
	}
	return ""
}

@(private = "file")
solve :: proc(data: string, blink_count: u64) -> string {
	stone_processor_cache = make_map(
		map[ProcessedStoneCacheKey]u64,
		allocator = context.temp_allocator,
	)
	defer delete_map(stone_processor_cache)
	puz := parse(data)
	defer delete(puz)

	results: u64 = 0
	for item in puz {
		results += process_stone(blink_count, item, 0)
	}
	return util.to_str(results)
}

@(private = "file")
process_stone :: proc(max_blinks: u64, stone_num: u64, cur_blink: u64) -> u64 {
	key := ProcessedStoneCacheKey{stone_num, cur_blink}
	if key in stone_processor_cache {
		return stone_processor_cache[key]
	}
	if cur_blink == max_blinks do return 1
	stones_to_process := splitter(stone_num)

	results := u64(0)
	switch t in stones_to_process {
	case SingleStone:
		results += process_stone(max_blinks, t, cur_blink + 1)
	case TwoStones:
		results += process_stone(max_blinks, t[0], cur_blink + 1)
		results += process_stone(max_blinks, t[1], cur_blink + 1)
	}
	stone_processor_cache[key] = results
	return results
}

@(private = "file")
splitter :: proc(stone_num: u64) -> SplitResult {
	result: SplitResult
	stone_num_len := count_digits(stone_num)
	if stone_num == 0 {
		result = SingleStone(1)
	} else {
		if stone_num_len % 2 == 0 {
			stone_num_digits := util.to_str(stone_num, allocator = context.temp_allocator)
			left, _ := conv.parse_u64(stone_num_digits[:(stone_num_len / 2)])
			right, _ := conv.parse_u64(stone_num_digits[(stone_num_len / 2):])
			result = TwoStones{left, right}
		} else {
			result = SingleStone(stone_num * 2024)
		}
	}
	return result
}

@(private = "file")
parse :: proc(data: string) -> Puz {
	puz := make_dynamic_array([dynamic]u64)
	raw_data := strings.split(data, " ")
	defer delete(raw_data)

	for raw_n in raw_data {
		append(&puz, u64(conv.atoi(raw_n)))
	}
	return puz[:]
}

@(private = "file")
count_digits :: proc(n: u64) -> u64 {
	return u64(len(util.to_str(n, allocator = context.temp_allocator)))
}
