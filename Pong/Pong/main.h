#ifndef MAIN_H_
#define MAIN_H_

// This is C, I cant spam my [[nodiscard]] const noexcepts everywhere :(
// Whatever will I do without my beloved constexpr

// Command Data object specification:
//  . Position [x/y] -> 11 bits in length
//  . Color    [rgb] -> 12 bits in length (r then g then b)

#define CLOCK_SPEED (uint32_t) 16000000 // Apparently its running at around 16 MHz
#define BAUD_RATE   (uint32_t) 9600
#define UBRR        (uint16_t) ((CLOCK_SPEED / ((uint32_t) 16 * BAUD_RATE)) - 1)

// The assumption is that this will be running at 60 FPS, meaning this is the required amount of timer 
// pulses before a frame elapses
#define INTERRUPTS_PER_FRAME (uint8_t) ((CLOCK_SPEED / (uint32_t) (0xFFFF)) / (uint8_t) (60))

// Define the upper amount of behind-frames it can process before giving out
//  . This prevents it from getting stuck trying to process past frames if it is unable to do it fast enough
//     : It really shouldn't be a problem, but it doesn't hurt to check. I doubt the elapsed frame counter 
//     will even go above one in the first place to be honest.
#define FRAME_DROP_THRESHOLD (uint8_t) 3

#define BALL_VELOCITY      (uint8_t) 10
#define BALL_SLOW_VELOCITY (uint8_t) 5
#define PADDLE_MOVE_SPEED  (uint8_t) 15

#define SCREEN_WIDTH  (uint16_t) 1280
#define SCREEN_HEIGHT (uint16_t) 1024

#define BALL_SIZE     (uint8_t) 25
#define PADDLE_WIDTH  (uint8_t) 25
#define PADDLE_HEIGHT (uint8_t) 200

// Hold the ball for 2 seconds on score
#define GOAL_SCORE_BALL_HOLD (uint8_t) (60 * 2)

// Hold the ball for 3 seconds on kick-off
#define KICKOFF_BALL_HOLD (uint8_t) (60 * 3)

// Flash the ball every half a second
#define FLASH_FREQUENCY (uint8_t) 30

// This used to be (BALL_VELOCITY / 2), but it was causing more problems than it was worth for non-float velocity
#define PHYSICS_SUBSTEPS (uint8_t) 1

#define BALL_NORMAL_COLOR     (uint16_t) 0b0000111111111111
#define BALL_FLASH_DARK_COLOR (uint16_t) 0b0000010101010101

#define INITIAL_PLAYER_Y        (uint16_t) ((SCREEN_HEIGHT / 2) - (PADDLE_HEIGHT / 2))
#define BALL_INITIAL_POSITION_X (uint16_t) 626
#define BALL_INITIAL_POSITION_Y (uint16_t) 498

#define FRAMES_TO_RESET  (uint8_t) 120
#define RESET_FRAME_WAIT (uint8_t) 120

enum DirtyFlags {
	None              = 0,
	BallDirty         = 1 << 0,
	Player1Dirty      = 1 << 1,
	Player2Dirty      = 1 << 2,
	BallColorDirty    = 1 << 3,
	Player1ScoreDirty = 1 << 4,
	Player2ScoreDirty = 1 << 5
};

enum GameState {
	Reset = 0,
	InRound,
	BallKickoff,
	BallScored
};

// Initialization

void IO_Initialize();
void TIMER_Initialize();

// Frame Processing

void PerformReset();
void Synchronize();
void ProcessFrame();
void SendCommands();


// USART

void USART_Initialize      (const uint16_t ubrr);
void USART_TransmitByte    (const uint8_t  data);
void USART_TransmitCommand (const uint32_t command);

uint8_t USART_ReceiveByte();

// Commands

void FillCommandBits(const uint8_t command_bits, uint32_t* command);

uint32_t CreateBackgroundColorCommand  (const uint16_t rgb);
uint32_t CreateBallPositionCommand     (const uint16_t x, const uint16_t y);
uint32_t CreateBallColorCommand        (const uint16_t rgb);
uint32_t CreatePlayerPositionCommand   (const uint16_t y,        const uint8_t player);
uint32_t CreatePlayerColorCommand      (const uint16_t rgb,      const uint8_t player);
uint32_t CreatePlayerScoreDigitCommand (const uint8_t  segments, const uint8_t digit, const uint8_t player);

#endif