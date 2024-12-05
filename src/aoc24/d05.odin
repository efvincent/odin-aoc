package aoc24

import "../util"
import "core:fmt"
import "core:log"
import "core:math"
import "core:slice"
import conv "core:strconv"
import "core:strconv"
import "core:strings"
import "core:testing"

solve_d05 :: proc(part: util.Part, data: string) -> string {
	switch part {
	case .p1:
		return solve1(data)
	case .p2:
		return solve2(data)
	}
	return ""
}

Puz :: struct {
	rules: map[int]map[int]bool,
	jobs:  [dynamic][dynamic]int,
}

@(private = "file")
parse :: proc(data: string) -> Puz {
	orig_allocator := context.allocator
	context.allocator = context.temp_allocator
	defer context.allocator = orig_allocator

	parts := strings.split(data, "\n\n")
	raw_rules := strings.split_lines(parts[0])
	raw_jobs := strings.split_lines(parts[1])

	rules := make(map[int]map[int]bool)
	for raw_rule in raw_rules {
		rule_parts := strings.split(raw_rule, "|")
		key := strconv.atoi(rule_parts[0])
		value := strconv.atoi(rule_parts[1])
		if key in rules {
			m := (rules[key])
			fmt.printfln("inserting rule for page %v - value %v", key, value)
			m[value] = true
		} else {
			values := make(map[int]bool)
			values[value] = true
			rules[key] = values
		}
	}

	jobs := make([dynamic][dynamic]int)
	for raw_job in raw_jobs {
		raw_pages := strings.split(raw_job, ",")
		page_list := make([dynamic]int)
		for raw_page in raw_pages {
			page := strconv.atoi(raw_page)
			append(&page_list, page)
		}
		append(&jobs, page_list)
	}

	puz := Puz{rules, jobs}
	fmt.println(puz)
	return puz
}

@(private = "file")
solve2 :: proc(data: string) -> string {
	return ""
}

@(private = "file")
solve1 :: proc(data: string) -> string {
	puz := parse(data)
	tot := 0
	for job, job_idx in puz.jobs {
		valid := true
		for page, idx in job {
			page_rule := puz.rules[page]
			for prev_idx := 0; prev_idx < idx; prev_idx += 1 {
				// are any previous pages in the list of pages that must come after current?
				prev_page := job[prev_idx]
				if prev_page in page_rule {
					// found a previous page in the rules, this job is a nope
					valid = false
					continue
				}
			}
		}
		if valid {
			mid := job[len(job) / 2]
			tot += mid
			fmt.printfln("job %v valid mid:%v  : %v", job_idx, mid, job)
		} else {
			fmt.printfln("job %v INVALID : %v", job_idx, job)
		}
	}
	return util.to_str(tot)
}
