#include <avr/io.h>

#include "integer_math.h"

// templates [   I'm missing them :(   ]

int8_t sbmin(int8_t a, int8_t b) {
	return (a > b) ? b : a;
}
uint8_t ubmin(uint8_t a, uint8_t b) {
	return (a > b) ? b : a;
}

int16_t simin(int16_t a, int16_t b) {
	return (a > b) ? b : a;
}
uint16_t uimin(uint16_t a, uint16_t b) {
	return (a > b) ? b : a;
}

int8_t sbmax(int8_t a, int8_t b) {
	return (a >= b) ? a : b;
}
uint8_t ubmax(uint8_t a, uint8_t b) {
	return (a >= b) ? a : b;
}

int16_t simax(int16_t a, int16_t b) {
	return (a >= b) ? a : b;
}
uint16_t uimax(uint16_t a, uint16_t b) {
	return (a >= b) ? a : b;
}