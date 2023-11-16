package main

import (
	"fmt"
	"syscall/js"
)

func doNotPanicPlease() {
	r := recover()

	if r != nil {
		fmt.Println("Recovered from", r)
	}
}

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

// newRange(low, high) returns a slice of range from [low, high).
// Panics if high < low!
func newRange(low, high int) []int {
	r := make([]int, 0, (high - low))

	for num := low; num < high; num++ {
		r = append(r, num)
	}

	return r
}

// remove(s, i) removes the item at index `i` from slice `s`.
// ** NOTE: messes up the slice order!
func remove[T any](s []T, i int) []T {
	s[i] = s[len(s)-1]
	return s[:len(s)-1]
}

// contains(s, a) returns wether item `a` is in slice `s`
func contains[T comparable](s []T, a T) bool {
	for _, item := range s {
		if item == a {
			return true
		}
	}

	return false
}

// getIndexChanges returns a slice of numbers to change the `i` to check nearby cells.
func getIndexChanges(i, rowsNum, colsNum int) []int {
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
			indexChanges = append(indexChanges, 1, -colsNum+1, colsNum+1)
		case colsNum - 1:
			indexChanges = append(indexChanges, -1, -colsNum-1, colsNum-1)
		default:
			indexChanges = append(indexChanges, 1, -1, colsNum-1, colsNum+1, -colsNum-1, -colsNum+1)
		}
	}

	return indexChanges
}
