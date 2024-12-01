#include <math.h>
#include <stdlib.h>
#include <time.h>

#include <avr/interrupt.h>
#include <avr/io.h>

#include "main.h"
#include "integer_math.h"

// This is one hell of a spaghetti coded nightmare
//  . Did have to write it in like, 3 days though (in C, and I know C++ better)

uint8_t timer_counter     = 0; // Amount of times the clock has fired, when it becomes 4 it needs to process a new frame
uint8_t frames_to_process = 1; // Amount of frames to process at this current time (initially 1)

uint8_t game_state  = Reset;
uint8_t dirty_flags = None;

uint16_t ball_color      = BALL_NORMAL_COLOR;
int16_t  ball_position_x = BALL_INITIAL_POSITION_X;
int16_t  ball_position_y = BALL_INITIAL_POSITION_Y;
int8_t   ball_velocity_x = BALL_SLOW_VELOCITY;
int8_t   ball_velocity_y = BALL_SLOW_VELOCITY;

int16_t player_1_position_x = 100;
int16_t player_1_position_y = INITIAL_PLAYER_Y;

int16_t player_2_position_x = SCREEN_WIDTH - 25 - 100 - 1;
int16_t player_2_position_y = INITIAL_PLAYER_Y;

uint16_t player_1_score = 0;
uint16_t player_2_score = 0;

uint8_t  ball_bounced_off_paddle = 0;

uint16_t timer_a = KICKOFF_BALL_HOLD;
uint16_t timer_b = FLASH_FREQUENCY;

uint8_t  flash_state       = 0;
int8_t   reset_counter     = 0;

// Utility
int16_t handlePlayerMovement(int16_t player_position, int16_t player_input, int8_t player_dirty_flag);

uint8_t collisionDetected(int16_t x1, int16_t y1, uint8_t size1x, uint8_t size1y, int16_t x2, int16_t y2, uint8_t size2x, uint8_t size2y);

uint8_t numberToSegments(uint8_t number); // Number between 0-9 (inclusive)

void transmitPlayerScore(uint8_t player);

int main(void) {
	IO_Initialize();
	TIMER_Initialize();
	
	PerformReset();
	
	while (1) {
		// Wait until there is a frame to process
		while (frames_to_process <= 0) { }
			
		if (game_state == Reset) {
			reset_counter--;
			
			if (reset_counter <= 0) {
				game_state      = BallKickoff;
				ball_velocity_y = (rand() % BALL_SLOW_VELOCITY);
			}
			
			continue;
		}
		
		
		uint8_t processing_frames = frames_to_process;
		frames_to_process = 0;
	
		// Cap the amount of frames that can be processed at once
		processing_frames = uimin(processing_frames, FRAME_DROP_THRESHOLD);
			
		// Process the pending frames
		for (uint8_t i = 0; i < processing_frames; i++) {
			ProcessFrame();
		}
		
		// Send commands
		SendCommands();	
	}
}

// ---------------------
// | INTERRUPT VECTORS |
// ---------------------

ISR(TIMER1_OVF_vect) {
	timer_counter++;
	timer_counter %= 4;
	frames_to_process += (timer_counter == 0) ? 1 : 0;
}

// ----------------------------
// | Initialization Functions |
// ----------------------------

void IO_Initialize() {
	// USART Initialization
	USART_Initialize(UBRR);
	
	// Enable output to the LED
	DDRB = 1 << DDRB5;
	
	// TODO: Figure out what pin the internal button connects to
	
	// Enable Controller Inputs
	//
	// Here is the controller mapping:
	// . PC0 -> P1 down
	// . PC1 -> P1 up
	// . PC2 -> Reset [needs debouncing]
	// . PC3 -> P2 down
	// . PC4 -> P2 up
	DDRB  = 0b01111111;
	DDRC  = 0b11100000;
	DDRD  = 0b11111111;
	PORTC = 0b00000100;
	PORTD = 0b11111111;
}

void TIMER_Initialize() {
	// Normal port operation (just let it overflow, no comparing needed)
	TCCR1A = 0b00000000;
	
	// No pre-scaling (I need / 4 for this, but it only has /(8x))
	// There is no input captures, so no need for noise canceling or edge select
	// Normal mode for Waveform Generation
	TCCR1B = 0b00000001;
	
	// Dont care about this one
	TCCR1C = 0;
	
	// Enable Timer Overflow interrupt
	TIMSK1 = 0b00000001;
}

// -------------------
// | Frame Functions |
// -------------------

void PerformReset() {
	cli(); // Disable global interrupts
	
	// Reset game state to initial state
	timer_counter     = 0;
	frames_to_process = 1;
	
	game_state  = Reset;
	dirty_flags = None;
	
	ball_color      = BALL_NORMAL_COLOR;
	ball_position_x = BALL_INITIAL_POSITION_X;
	ball_position_y = BALL_INITIAL_POSITION_Y;
	ball_velocity_x = BALL_SLOW_VELOCITY;
	ball_velocity_y = BALL_SLOW_VELOCITY;
	
	player_1_position_x = 100;
	player_1_position_y = INITIAL_PLAYER_Y;
	
	player_2_position_x = SCREEN_WIDTH - 25 - 100 - 1;
	player_2_position_y = INITIAL_PLAYER_Y;
	
	player_1_score = 0;
	player_2_score = 0;
	
	ball_bounced_off_paddle = 0;
	
	timer_a = KICKOFF_BALL_HOLD;
	timer_b = FLASH_FREQUENCY;
	
	flash_state   = 0;
	reset_counter = 0;
	
	// Transmit all command states
	Synchronize();
	
	sei(); // Enable global interrupts
	
	reset_counter = RESET_FRAME_WAIT; // 2 second start delay
	
	// Seed RNG
	srand(time(NULL));
}

void Synchronize() {
	USART_TransmitCommand(CreateBackgroundColorCommand(0b0000000000000000));            // Background Color
	USART_TransmitCommand(CreateBallPositionCommand(ball_position_x, ball_position_y)); // Ball Position
	USART_TransmitCommand(CreateBallColorCommand(ball_color));                          // Ball Color
	USART_TransmitCommand(CreatePlayerPositionCommand(player_1_position_y, 0));         // Player 1 Y Position
	USART_TransmitCommand(CreatePlayerPositionCommand(player_2_position_y, 1));         // Player 2 Y Position
	USART_TransmitCommand(CreatePlayerColorCommand(0b0000111100000000, 0));             // Player 1 Color
	USART_TransmitCommand(CreatePlayerColorCommand(0b0000000000001111, 1));             // Player 1 Color
	
	transmitPlayerScore(0); // Player 1 Score
	transmitPlayerScore(1); // Player 2 Score
}

void ProcessFrame() {
	volatile uint8_t input_byte = PINC & 0b00011111;
	
	// Extract general purpose button inputs
	uint8_t reset_input = (input_byte & 0b00000100) != 0;
	
	// Extract player 1 inputs from input byte
	uint8_t player_1_input_up   = (input_byte & 0b00000001) != 0;
	uint8_t player_1_input_down = (input_byte & 0b00000010) != 0;

	// Extract player 2 inputs from input byte
	uint8_t player_2_input_up   = (input_byte & 0b00001000) != 0;
	uint8_t player_2_input_down = (input_byte & 0b00010000) != 0;
	
	// Calculate player input vectors (do not move when both are held)
	int8_t player_1_input = player_1_input_up - player_1_input_down;
	int8_t player_2_input = player_2_input_up - player_2_input_down;
	
	//
	
	// Reset Input Handling
	if (reset_input == 0) {
		reset_counter++;
		
		if (reset_counter >= FRAMES_TO_RESET) {
			PerformReset();
			return;
		}
	} else {
		reset_counter--;
		if (reset_counter < 0)
			reset_counter = 0;
	}
	
	// Player 1 Input Handling
	if (player_1_input != 0)
		player_1_position_y = handlePlayerMovement(player_1_position_y, player_1_input, Player1Dirty);
	
	// Player 2 Input Handling
	if (player_2_input != 0)
		player_2_position_y = handlePlayerMovement(player_2_position_y, player_2_input, Player2Dirty);
	
	// The ball can only move in round
	switch (game_state) {
		case InRound: {
			for (uint8_t i = 0; i < PHYSICS_SUBSTEPS; i++) {
				// The ball is moving, collision needs to be handled
			
				dirty_flags |= BallDirty;
			
				// Update the ball position
				ball_position_x += ball_velocity_x / PHYSICS_SUBSTEPS;
				ball_position_y += ball_velocity_y / PHYSICS_SUBSTEPS;
			
				// Bounce the ball off the the Y screen borders
				if (ball_position_y <= 0) {
					ball_velocity_y *= -1;
					ball_position_y *= -1;
				} else if (ball_position_y >= (SCREEN_HEIGHT - BALL_SIZE - 1)) {
					ball_velocity_y *= -1;
					ball_position_y = (SCREEN_HEIGHT - BALL_SIZE - 1) - (ball_position_y - (SCREEN_HEIGHT - BALL_SIZE - 1));
				}
			
				// Bounce the balls off of player paddles
				if (collisionDetected(player_1_position_x, player_1_position_y, PADDLE_WIDTH, PADDLE_HEIGHT, ball_position_x, ball_position_y, BALL_SIZE, BALL_SIZE)) {
					// The ball is currently colliding with player 1's paddle
					if (ball_bounced_off_paddle == 0) {
						ball_bounced_off_paddle = 1;
						
						ball_velocity_x = BALL_VELOCITY;
					}
					
					ball_velocity_y = (rand() % BALL_VELOCITY) * (ball_velocity_y >= 0 ? 1 : -1);
					
					// Reverse the ball's velocity (if applicable)
					if (ball_velocity_x < 0)
						ball_velocity_x *= -1;
					
					ball_position_x = (player_1_position_x + PADDLE_WIDTH) + ((player_1_position_x + PADDLE_WIDTH) - ball_position_x);
				} else if (collisionDetected(player_2_position_x, player_2_position_y, PADDLE_WIDTH, PADDLE_HEIGHT, ball_position_x, ball_position_y, BALL_SIZE, BALL_SIZE)) {
					// The ball is currently colliding with player 2's paddle
					if (ball_bounced_off_paddle == 0) {
						ball_bounced_off_paddle = 1;
						
						ball_velocity_x = -BALL_VELOCITY;
					}
					
					ball_velocity_y = (rand() % BALL_VELOCITY) * (ball_velocity_y >= 0 ? 1 : -1);
					
					// Reverse the ball's velocity (if applicable)
					if (ball_velocity_x > 0)
						ball_velocity_x *= -1;

					ball_position_x = (player_2_position_x - BALL_SIZE) - (player_2_position_x - ball_position_x);
				}
			
			
				if (ball_position_x <= 0) {
					// Ball has hit the border of Player 1
					player_2_score++;
					dirty_flags |= Player2ScoreDirty;
					
					ball_velocity_x *= -1;
					ball_position_x *= -1;
					
					timer_a     = GOAL_SCORE_BALL_HOLD;
					timer_b     = FLASH_FREQUENCY;
					game_state  = BallScored;
					flash_state = 0;
					
					ball_velocity_x = BALL_SLOW_VELOCITY;
					ball_velocity_y = (rand() % BALL_SLOW_VELOCITY) * ((rand() % 2) ? 1 : -1);
					
					ball_bounced_off_paddle = 0;
				} else if (ball_position_x >= (SCREEN_WIDTH - BALL_SIZE - 1)) {
					// Ball has hit the border of Player 2
					player_1_score++;
					dirty_flags |= Player1ScoreDirty;
					
					ball_velocity_x *= -1;
					ball_position_x = (SCREEN_WIDTH - BALL_SIZE - 1) - (ball_position_x - (SCREEN_WIDTH - BALL_SIZE - 1));
					
					timer_a     = GOAL_SCORE_BALL_HOLD;
					timer_b     = FLASH_FREQUENCY;
					game_state  = BallScored;
					flash_state = 0;
					
					ball_velocity_x = -BALL_SLOW_VELOCITY;
					ball_velocity_y = (rand() % BALL_SLOW_VELOCITY) * ((rand() % 2) ? 1 : -1);
					
					ball_bounced_off_paddle = 0;
				}
			}
			break;
		}
		case BallScored: {
			timer_a--;
			timer_b--;
			
			if (timer_b == 0) {
				flash_state++;
				flash_state %= 2;
				
				if (flash_state) {
					ball_color = BALL_NORMAL_COLOR;
					timer_b    = FLASH_FREQUENCY;
				} else {
					ball_color = BALL_FLASH_DARK_COLOR;
					timer_b    = FLASH_FREQUENCY;
				}
				
				dirty_flags |= BallColorDirty;
			}
			
			if (timer_a == 0) {
				timer_a    = KICKOFF_BALL_HOLD;
				timer_b    = FLASH_FREQUENCY;
				game_state = BallKickoff;
				
				ball_position_x = BALL_INITIAL_POSITION_X;
				ball_position_y = BALL_INITIAL_POSITION_Y;
				
				dirty_flags |= BallDirty;
			}
			
			break;
		}
		case BallKickoff: {
			timer_a--;
			timer_b--;
			
			if (timer_b == 0) {
				flash_state++;
				flash_state %= 2;
				
				if (flash_state) {
					ball_color = BALL_NORMAL_COLOR;
					timer_b    = FLASH_FREQUENCY;
				} else {
					ball_color = BALL_FLASH_DARK_COLOR;
					timer_b    = FLASH_FREQUENCY;
				}
				
				dirty_flags |= BallColorDirty;
			}
			
			if (timer_a == 0) {
				game_state = InRound;
				ball_color = BALL_NORMAL_COLOR;
				
				dirty_flags |= BallDirty | BallColorDirty;
			}
			
			break;
		}
	}
}

void SendCommands() {
	// Verify there are actually commands to send
	if (dirty_flags == None)
		return;
	
	// Transmit the ball position
	if ((dirty_flags & BallDirty) != 0)
		USART_TransmitCommand(CreateBallPositionCommand(ball_position_x, ball_position_y));
	
	// Transmit Player 1 Position
	if ((dirty_flags & Player1Dirty) != 0)
		USART_TransmitCommand(CreatePlayerPositionCommand(player_1_position_y, 0));
		
	// Transmit Player 2 Position
	if ((dirty_flags & Player2Dirty) != 0)
		USART_TransmitCommand(CreatePlayerPositionCommand(player_2_position_y, 1));
		
	// Transmit Ball Color
	if ((dirty_flags & BallColorDirty) != 0)
		USART_TransmitCommand(CreateBallColorCommand(ball_color));
		
	// Transmit Player 1 Score
	if ((dirty_flags & Player1ScoreDirty) != 0)
		transmitPlayerScore(0);
	
	// Transmit Player 2 Score
	if ((dirty_flags & Player2ScoreDirty) != 0)
		transmitPlayerScore(1);
	
	// Reset the dirty flags
	dirty_flags = None;
}

// -------------------
// | USART Functions |
// -------------------

void USART_Initialize(const uint16_t ubrr) {
	// Set the BAUD rate
	UBRR0H = (uint8_t) (ubrr >> 8);
	UBRR0L = (uint8_t) (ubrr);
	
	// Enable the transmitter
	UCSR0B = (1 << 3);// | (1 << 4);
	
	// Set Frame Format: 8-data bits, 1 stop-bit, no parity
	UCSR0C = 0b00000110;
}

void USART_TransmitByte(const uint8_t data) {
	while (!(UCSR0A & (1 << 5))) {}
		
	UDR0 = data;
}
void USART_TransmitCommand(const uint32_t command) {
	uint8_t low         = (uint8_t) (command >> 0);
	uint8_t low_middle  = (uint8_t) (command >> 8);
	uint8_t high_middle = (uint8_t) (command >> 16);
	uint8_t high        = (uint8_t) (command >> 24);
	
	USART_TransmitByte(low);
	USART_TransmitByte(low_middle);
	USART_TransmitByte(high_middle);
	USART_TransmitByte(high);
}

uint8_t UART_ReceiveByte() {
	while (!(UCSR0A & (1 << 4))) {}
		
	return UDR0;
}

// ---------------------
// | Command Functions |
// ---------------------

void FillCommandBits(const uint8_t command_bits, uint32_t* command) {
	(*command) |= ((uint32_t) command_bits) << ((uint32_t) 26);
}

uint32_t CreateBackgroundColorCommand(const uint16_t rgb) {
	uint32_t command = 0;

	FillCommandBits(0, &command);
	command |= ((0x0FFF) & rgb);
	
	return command;
}

uint32_t CreateBallPositionCommand(const uint16_t x, const uint16_t y) {
	uint32_t command = 0;
	
	FillCommandBits(1, &command);
	command |= (y & 0x7FF);
	command |= ((uint32_t) (x & 0x7FF) << 11);
	
	return command;
}

uint32_t CreateBallColorCommand(const uint16_t rgb) {
	uint32_t command = 0;
	
	FillCommandBits(2, &command);
	command |= (uint16_t) (((uint16_t) 0x0FFF) & rgb);
	
	return command;
}

uint32_t CreatePlayerPositionCommand(const uint16_t y, const uint8_t player) {
	uint32_t command = 0;
	
	FillCommandBits(4, &command);
	command |= (y & 0x7FF);
	command |= ((player != 0) << 11);
	
	return command;
}

uint32_t CreatePlayerColorCommand(const uint16_t rgb, const uint8_t player) {
	uint32_t command = 0;
	
	FillCommandBits(5, &command);
	command |= (uint16_t) (((uint16_t) 0x0FFF) & rgb);
	command |= ((player != 0) << 12);
	
	return command;
}

uint32_t CreatePlayerScoreDigitCommand(const uint8_t segments, const uint8_t digit, const uint8_t player) {
	uint32_t command = 0;
	
	FillCommandBits(6, &command);
	command |= segments;
	command |= (digit         << 7);
	command |= ((player != 0) << 9);

	return command;
}

// Yeah this is where I got lazy with proper C

// UTILITY FUNCTIONS
int16_t handlePlayerMovement(int16_t player_y_position, int16_t player_input, int8_t player_dirty_flag) {
	uint16_t current_player_y = player_y_position;
	player_y_position = simax(simin((current_player_y + (player_input * PADDLE_MOVE_SPEED)), (SCREEN_HEIGHT - PADDLE_HEIGHT - 1)), 0);
	
	if (player_y_position != current_player_y)
		dirty_flags |= player_dirty_flag;
		
	return player_y_position;
}

uint8_t collisionDetected(int16_t x1, int16_t y1, uint8_t size1x, uint8_t size1y, int16_t x2, int16_t y2, uint8_t size2x, uint8_t size2y) {
	uint16_t min1x = x1;
	uint16_t min2x = x2;
	
	uint16_t max1x = x1 + size1x;
	uint16_t max2x = x2 + size2x;
	
	uint16_t min1y = y1;
	uint16_t min2y = y2;
	
	uint16_t max1y = y1 + size1y;
	uint16_t max2y = y2 + size2y;
	
	if (
		min1x < max2x &&
		max1x > min2x &&
		min1y < max2y &&
		max1y > min2y
	)
		return 1;
	
	return 0;
}

uint8_t numberToSegments(uint8_t number) {
	switch (number) {
	case 0:
		return 0b00111111;
	case 1:
		return 0b00000110;
	case 2:
		return 0b01011011;
	case 3:
		return 0b01001111;
	case 4:
		return 0b01100110;
	case 5:
		return 0b01101101;
	case 6:
		return 0b01111101;
	case 7:
		return 0b00000111;
	case 8:
		return 0b01111111;
	case 9:
		return 0b01101111;
	default:
		return 0b00000000;
	}
}

void transmitPlayerScore(uint8_t player) {
	uint8_t highest_digit = 0;
	uint8_t high_digit	  = 0;
	uint8_t low_digit	  = 0;
	uint8_t lowest_digit  = 0;
	
	// BUG: Somehow this is effecting player 1's position???????
	//  . It seems to set player 1 input 'up' (which goes down in this case) to 1, and I honestly do not know why
	
	if (player == 0) {
		// Player 1 score
		highest_digit = (uint8_t) (player_1_score / (uint16_t) 1000) % (uint16_t) 10;
		high_digit    = (uint8_t) (player_1_score / (uint16_t) 100)  % (uint16_t) 10;
		low_digit     = (uint8_t) (player_1_score / (uint16_t) 10)   % (uint16_t) 10;
		lowest_digit  = (uint8_t) (player_1_score / (uint16_t) 1)    % (uint16_t) 10;
	} else {
		// Player 2 score
		highest_digit = (uint8_t) (player_2_score / (uint16_t) 1000) % (uint16_t) 10;
		high_digit    = (uint8_t) (player_2_score / (uint16_t) 100)  % (uint16_t) 10;
		low_digit     = (uint8_t) (player_2_score / (uint16_t) 10)   % (uint16_t) 10;
		lowest_digit  = (uint8_t) (player_2_score / (uint16_t) 1)    % (uint16_t) 10;
	}
	
	USART_TransmitCommand(CreatePlayerScoreDigitCommand(0, 0, player)); // I dont know why this is necessary, but it keeps the segments from breaking?
	
	USART_TransmitCommand(CreatePlayerScoreDigitCommand(numberToSegments(lowest_digit),  3, player));
	USART_TransmitCommand(CreatePlayerScoreDigitCommand(numberToSegments(low_digit),     2, player));
	USART_TransmitCommand(CreatePlayerScoreDigitCommand(numberToSegments(high_digit),    1, player));
	USART_TransmitCommand(CreatePlayerScoreDigitCommand(numberToSegments(highest_digit), 0, player));
}