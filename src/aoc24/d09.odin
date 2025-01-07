#+private file
package aoc24

import "../util"
import "core:fmt"

Blocks :: #type [dynamic]Block

Block :: struct {
	file_id:  int,
	block_id: int,
}

FileSpec :: struct {
	file_id:        int,
	size_in_blocks: int,
	location:       int,
}

@(private = "package")
solve_d09 :: proc(part: util.Part, data: string) -> string {
	switch part {
	case .p1:
		return solve1(data)
	case .p2:
		return solve2(data)
	}
	return ""
}

parse :: proc(data: string) -> Blocks {

	file_id := 0
	block_id := 0
	blocks := make([dynamic]Block, 0, (len(data) * 5), allocator = context.temp_allocator)
	for idx := 0; idx < (len(data)); idx += 2 {

		// record each of its blocks
		for file_idx := u8(0); file_idx < (data[idx] - '0'); file_idx += 1 {
			block := Block {
				file_id  = file_id,
				block_id = block_id,
			}
			append(&blocks, block)
			block_id += 1
		}
		file_id += 1

		if idx + 1 < len(data) {
			// record each of the space's blocks
			for space_idx := u8(0); space_idx < (data[idx + 1] - '0'); space_idx += 1 {
				block := Block {
					file_id  = -1,
					block_id = block_id,
				}
				append(&blocks, block)
				block_id += 1
			}
		}
	}
	return blocks
}

fits :: #force_inline proc(file: FileSpec, space: FileSpec) -> bool {
	return file.size_in_blocks <= space.size_in_blocks
}

solve1 :: proc(data: string) -> string {
	blocks := parse(data)

	cur := 0
	last := len(blocks) - 1
	for {
		// if current block is a space
		if blocks[cur].file_id == -1 {
			// if last is a file block
			if blocks[last].file_id != -1 {
				blocks[cur].file_id = blocks[last].file_id
				blocks[last].file_id = -1
				last -= 1
			} else {
				// last block is a space
				last -= 1
			}
		} else {
			// current block is already a file
			cur += 1
		}
		if cur >= last do break
	}

	return util.to_str(checksum(blocks))
}

solve2 :: proc(data: string) -> string {
	blocks := parse(data)
	// this is the point at which we start searching for files. File search happens backwards,
	// starting at the end and scanning towards the beginning. So file search start is initialized
	// as the last block
	file_search_start := len(blocks) - 1

	// this is the point at which we start searching for spans of free space, which happens
	// forwards, so the initial space search start is the first block space_search_start = first block 
	space_search_start := 0
	for {
		// find the next movable file
		cur_file, file_file_ok := find_next_file(blocks, file_search_start)
		if !file_file_ok {
			// could not find a file. If there are no more files, we must be done
			// being done means stopping the loop to find files
			break
		}

		// * * * at this point we have a file we're trying to move: cur_file

		// starting at the space search start, we're going to look at each space to see if the
		for { 	// finding space for file

			// when searching for a space, we don't need to search past the current file's
			// starting location, because we'd never move a file "up" towards the end
			cur_space, file_space_ok := find_next_space(
				blocks,
				space_search_start,
				cur_file.location - 1,
			)
			if !file_space_ok {
				// cannot find space for this file. This file will remain forever where it is
				// we do this by moving file_search_start to BEFORE this file, so next find_next_file 
				// will never find this one. We then can break out of the loop trying to find space
				// for the current file
				file_search_start = cur_file.location - 1
				space_search_start = 0
				break // finding space for file
			}

			if fits(cur_file, cur_space) {
				// the current space fits the current file. Next file search can start at the next
				// file to be moved - which is the file before the current file. We move the file
				// search start position to before this file 
				file_search_start = cur_file.location - 1

				// We will also be moving the point at which we start looking for open space to
				// after the newly moved file
				space_search_start = 0

				// we can now move the current file into the space we've found.
				// Note that the block IDs are moved as well as the file ID 
				move_file(&blocks, cur_file, cur_space)

				// the file is moved, we can break out of the finding space loop for this file
				break // finding space for file
			} else {
				// file didn't fit so we're going to continue to search beyond the current space
				// by moving the start of the space search to just after the current space
				space_search_start = cur_space.location + cur_space.size_in_blocks
			}

		} // finding space for file
	} // end[finding files that may be moved]

	return util.to_str(checksum(blocks))
}

move_file :: proc(blocks: ^Blocks, file: FileSpec, space: FileSpec) {
	id := file.file_id
	for idx in 0 ..< file.size_in_blocks {
		file_idx := file.location + idx
		space_idx := space.location + idx

		// move the file block into the space
		blocks[space_idx].file_id = id

		// move the space into the block that was the file block
		blocks[file_idx].file_id = -1
	}
}

find_next_space :: proc(
	blocks: Blocks,
	start_search_idx: int,
	max_search_idx: int,
) -> (
	spec: FileSpec,
	ok: bool,
) {
	// starting at the start_search_idx
	for candidate_block_idx := start_search_idx;
	    candidate_block_idx < max_search_idx;
	    candidate_block_idx += 1 {
		// is the candidate block part of a space?
		if blocks[candidate_block_idx].file_id == -1 {
			// found the starting block of a space
			spec.location = candidate_block_idx

			// scan blocks in the space we've found
			for {
				// move to the next candidate block
				candidate_block_idx += 1
				if blocks[candidate_block_idx].file_id != -1 {
					// we've found the first block after the space ends
					spec.size_in_blocks = candidate_block_idx - spec.location
					return spec, true
				}
			} // proceed to next candidate block
		} // candidate block is not a space 
	} // continue to the next block

	// if we get this far, we didn't find a space
	return spec, false
}

find_next_file :: proc(blocks: Blocks, start_search_idx: int) -> (spec: FileSpec, ok: bool) {

	// starting at the start_search_idx, proceed toward the first block until we get to the beginning
	for candidate_block_idx := start_search_idx;
	    candidate_block_idx >= 0;
	    candidate_block_idx -= 1 {

		// is the candidate block the last block of a file?
		if blocks[candidate_block_idx].file_id != -1 {
			// found the ending block of a file
			spec.file_id = blocks[candidate_block_idx].file_id
			file_end_block_idx := candidate_block_idx

			// scan blocks in the file we've found
			for {
				// assume the current block is the starting location of the file
				spec.location = candidate_block_idx

				// we'll now check the block before the candidate one
				candidate_block_idx -= 1

				// is the candidate block in the same file?
				if candidate_block_idx < 0 || blocks[candidate_block_idx].file_id != spec.file_id {
					// the candidate block (the one before the block we've determined to be in the file we're examining)
					// is not part of the current file, meaning we're done scanning the current file. We can return
					// the spec of the current file
					spec.size_in_blocks = file_end_block_idx - spec.location + 1
					return spec, true
				}
			} // proceed to the next candidate block 
		}
	}

	// if we get this far, we didn't find a file
	return spec, false
}

checksum :: proc(blocks: Blocks) -> u64 {
	tot := u64(0)
	for block in blocks {
		if block.file_id >= 0 {
			sub := u64(block.block_id * block.file_id)
			tot += sub
		}
	}
	return tot
}

print_blocks :: proc(blocks: Blocks) {
	for block in blocks {
		if block.file_id == -1 {
			fmt.print('.')
		} else {
			fmt.print(rune(block.file_id % 48 + 49))
		}
	}
	fmt.println()
}
