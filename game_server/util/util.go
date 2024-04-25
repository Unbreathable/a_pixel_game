package util

import (
	"crypto/rand"
	"fmt"
	"math"
	"math/big"
)

var letters = []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")

func RandomString(tkLength int32) string {

	s := make([]rune, tkLength)

	length := big.NewInt(int64(len(letters)))

	for i := range s {

		number, _ := rand.Int(rand.Reader, length)
		s[i] = letters[number.Int64()]
	}

	return string(s)
}

func ParseUIntFromMap(data map[string]interface{}, key string) (uint, error) {
	value, ok := data[key]
	if !ok {
		return 0, fmt.Errorf("key '%s' not found in map", key)
	}

	var intValue int
	switch v := value.(type) {
	case int:
		intValue = v
	case float64:
		// Check if float value is within integer range and convert
		if math.Trunc(v) == v {
			intValue = int(v)
		} else {
			return 0, fmt.Errorf("value for key '%s' is a float and cannot be represented as an integer", key)
		}
	default:
		return 0, fmt.Errorf("value for key '%s' is not an integer or float", key)
	}

	return uint(intValue), nil
}
