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
/*
	-cn-1   -cn	 	-cn+1
	-1		0 		1
	cn-1	cn 		cn+1
*/
package main

import (
	"fmt"
	"math/rand"
)

const (
	percentMines = 0.18
)

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

// getGrid returns the grid to display.
// Can't return a nested array threw WASM (couldn't figure this one out)
// so returns a 1-D array
func getGrid(rowsNum, colsNum int, mines, flagged, opened []int) any {
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

	for _, openI := range opened {
		if contains(mines, openI) {
			fmt.Println("Yup you just lost...")
			continue
		}

		numOfMines := countMines(mines, rowsNum, colsNum, openI)
		grid[openI] = numOfMines
	}

	return grid
}

// countMines returns the number of mine around a cell `i`
func countMines(mines []int, rowsNum, colsNum, i int) (amount int) {
	indexChanges := getIndexChanges(i, rowsNum, colsNum)

	for _, change := range indexChanges {
		checkI := i + change

		if checkI >= 0 && checkI < rowsNum*colsNum {
			// Its a valid index, check if mine
			if contains(mines, checkI) {
				amount++
			}
		}
	}

	return
}

// newMines(rowsNum, colsNum, opened) expects to be ints.
// Returns an array of 1-D array indexes that should be mines, and the opened is used to not allow to lose on first turn (that i cant be mine).
func newMines(rowsNum, colsNum, opened int) []any {
	totalMines := int(float64(rowsNum*colsNum) * percentMines)

	locationPool := newRange(0, rowsNum*colsNum)
	locationPool = remove(locationPool, opened)
	mines := make([]any, 0, totalMines)

	for a := 0; a < totalMines; a++ {
		locI := rand.Intn(len(locationPool))
		mine := locationPool[locI]

		locationPool = remove(locationPool, locI)
		mines = append(mines, mine)
	}

	return mines
}