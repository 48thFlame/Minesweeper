package main

import (
	"fmt"
	"math/rand"
	"syscall/js"
)

func main() {
	done := make(chan struct{})

	js.Global().Set("getGrid", js.FuncOf(getGrid))
	js.Global().Set("newMines", js.FuncOf(newMines))

	<-done
}

func doNotPanicPlease() {
	r := recover()

	if r != nil {
		fmt.Println("Recovered from", r)
	}
}

// Cells:
// 0..8 = An open cell and its number represents how many mines are around.
// 9 = Mine Cell
// 10 = Closed cell.
// 11 = Flag cell.
type Cell = int

const (
	mineCell   Cell = 9
	closedCell Cell = 10
	flagCell   Cell = 11
)

// convertToSlice(arr) takes a js array and returns a []int, may panic if bad array.
func convertToSlice(arr js.Value) []int {
	arrLen := arr.Length()
	s := make([]int, 0, arrLen)

	for i := 0; i < arrLen; i++ {
		n := arr.Index(i).Int()
		s = append(s, n)
	}

	return s
}

// `getGrid(rowsNum uint, colsNum uint, mines []int, flagged []int, opened []int)`
// Can't return a nested array threw WASM (couldn't figure this one out)
// so returns a 1-D array
func getGrid(this js.Value, args []js.Value) any {
	defer doNotPanicPlease()

	rowsNum := args[0].Int()
	colsNum := args[1].Int()
	mines := convertToSlice(args[2])
	flagged := convertToSlice(args[3])
	// opened := convertToSlice(args[4])

	gridArea := rowsNum * colsNum

	grid := make([]any, 0, gridArea)

	for i := 0; i < gridArea; i++ {
		grid = append(grid, closedCell)
	}

	for _, mineI := range mines {
		grid[mineI] = mineCell
	}

	for _, flagI := range flagged {
		grid[flagI] = flagCell
	}

	for i, slot := range grid {
		if slot == 10 {
			numOfMines := countMines(grid, rowsNum, colsNum, i)

			grid[i] = numOfMines
		}
	}

	return grid
}

/*
   i = cols_num * (row ) + col

   -col = cols_num * row - i
   col = - (cols_num * row - i)
   col = -cols_num * row + i

   col = mod(i, cols_num)

   cols_num * row = i - col
   row = (i - col) / cols_num

   row = floor(i / cols_num)
*/

func countMines(grid []any, rowsNum, colsNum, i int) (amount int) {
	col := i % colsNum
	row := i / colsNum

	indexChanges := make([]int, 0, 8)

	switch row {
	case 0:
		indexChanges = append(indexChanges, colsNum)
		switch col {
		case 0:
			indexChanges = append(indexChanges, 1, colsNum+1)
		case colsNum - 1:
			indexChanges = append(indexChanges, -1, colsNum-1)
		default:
			indexChanges = append(indexChanges, 1, -1, colsNum-1, colsNum+1)
		}
	case rowsNum - 1:
		indexChanges = append(indexChanges, -colsNum)
		switch col {
		case 0:
			indexChanges = append(indexChanges, 1, -colsNum+1)
		case colsNum - 1:
			indexChanges = append(indexChanges, -1, -colsNum-1)
		default:
			indexChanges = append(indexChanges, 1, -1, -colsNum-1, -colsNum+1)
		}
	default:
		indexChanges = append(indexChanges, colsNum, -colsNum)
		switch col {
		case 0:
			indexChanges = append(indexChanges, 1, -colsNum+1)
		case colsNum - 1:
			indexChanges = append(indexChanges, -1, -colsNum-1)
		default:
			indexChanges = append(indexChanges, 1, -1, colsNum-1, colsNum+1, -colsNum-1, -colsNum+1)
		}
	}

	for _, change := range indexChanges {
		checkI := i + change

		if checkI >= 0 && checkI < len(grid) {
			// Its a valid index, check if mine
			if grid[checkI] == mineCell {
				amount++
			}
		}
	}

	return
}

// newRange(low, high) returns a slice of range from [low, high).
// Panics if high < low!
func newRange(low, high int) []any {
	r := make([]any, 0, (high - low))

	for num := low; num < high; num++ {
		r = append(r, num)
	}

	return r
}

// remove(s, i) removes the item at index `i` from slice `s`.
// ** NOTE: messes up the slice order!
func remove(s []any, i int) []any {
	s[i] = s[len(s)-1]
	return s[:len(s)-1]
}

// newMines(rows_num, cols_num) expects 2 args: rows_num and cols_num, both need to be ints.
// Returns an array of 1-D array indexes that should be mines.
func newMines(this js.Value, args []js.Value) any {
	defer doNotPanicPlease()

	rows_num := args[0].Int()
	cols_num := args[1].Int()

	totalMines := int(rows_num * cols_num / 5)

	locationPool := newRange(0, rows_num*cols_num)
	mines := make([]any, 0, totalMines)

	for a := 0; a < totalMines; a++ {
		locI := rand.Intn(len(locationPool))
		mine := locationPool[locI]

		locationPool = remove(locationPool, locI)
		mines = append(mines, mine)
	}

	return mines
}
