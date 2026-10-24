// self-playing snake for the RV32I core (no mul/div, no libc)
// Find a path to food with BFS; use flood fill to estimate free space.
// output: each byte written to 0x10000000 is printed by the testbench
#include <stdint.h>

#define CONSOLE (*(volatile uint8_t *)0x10000000)

#define W 32            // grid width incl. walls, power of 2 so we can shift
#define H 16            // grid height incl. walls
#define N (W * H)       // 512 cells
#define TARGET_SCORE 40
#define MAX_STEPS 3000

enum { EMPTY = 0, WALL = 1, BODY = 2, FOOD = 3 };

static uint8_t  grid[N];
static uint16_t body[N];          // ring buffer of cell indices
static uint16_t head, tail, len;  // head/tail index body[]; len counts occupied cells
static uint16_t food;
static uint16_t queue[N];
static uint8_t  first_dir[N];
static uint16_t seen[N];
static uint16_t stamp;
static uint32_t rng = 0x2545F491u;

static const int16_t dirs[4] = { -W, 1, W, -1 };   // up, right, down, left

// clang can still call these with -nostdlib
void *memset(void *d, int c, unsigned n) {
    uint8_t *p = d; while (n--) *p++ = (uint8_t)c; return d;
}
void *memcpy(void *d, const void *s, unsigned n) {
    uint8_t *p = d; const uint8_t *q = s; while (n--) *p++ = *q++; return d;
}

static void putch(char c) { CONSOLE = (uint8_t)c; }
static void puts_(const char *s) { while (*s) putch(*s++); }

// print a number without using divide
static void putu(uint32_t v) {
    static const uint32_t p10[5] = { 10000, 1000, 100, 10, 1 };
    int started = 0;
    for (int i = 0; i < 5; i++) {
        char d = '0';
        while (v >= p10[i]) { v -= p10[i]; d++; }
        if (d != '0' || started || i == 4) { putch(d); started = 1; }
    }
}

static uint32_t xorshift(void) {
    rng ^= rng << 13; rng ^= rng >> 17; rng ^= rng << 5;
    return rng;
}

static int passable(int i) { return grid[i] == EMPTY || grid[i] == FOOD; }

static void place_food(void) {
    uint32_t i;
    do { i = xorshift() & (N - 1); } while (grid[i] != EMPTY);
    grid[i] = FOOD;
    food = (uint16_t)i;
}

static void new_stamp(void) {
    if (++stamp == 0) { memset(seen, 0, sizeof seen); stamp = 1; }
}

// BFS from start, returns first move toward food or -1 if no path
static int bfs_to_food(int start) {
    int qh = 0, qt = 0;
    new_stamp();
    seen[start] = stamp;
    for (int d = 0; d < 4; d++) {
        int n = start + dirs[d];
        if (passable(n) && seen[n] != stamp) {
            seen[n] = stamp; first_dir[n] = (uint8_t)d; queue[qt++] = (uint16_t)n;
        }
    }
    while (qh < qt) {
        int c = queue[qh++];
        if (c == food) return first_dir[c];
        for (int d = 0; d < 4; d++) {
            int n = c + dirs[d];
            if (passable(n) && seen[n] != stamp) {
                seen[n] = stamp; first_dir[n] = first_dir[c]; queue[qt++] = (uint16_t)n;
            }
        }
    }
    return -1;
}

// count free cells reachable from start
static int flood(int start) {
    int qh = 0, qt = 0;
    new_stamp();
    seen[start] = stamp; queue[qt++] = (uint16_t)start;
    while (qh < qt) {
        int c = queue[qh++];
        for (int d = 0; d < 4; d++) {
            int n = c + dirs[d];
            if (passable(n) && seen[n] != stamp) { seen[n] = stamp; queue[qt++] = (uint16_t)n; }
        }
    }
    return qt;
}

static int choose_move(void) {
    int h = body[head];
    int d = bfs_to_food(h);
    if (d >= 0 && flood(h + dirs[d]) >= len) return d;   // enough reachable space
    int best = -1, best_area = 0;                          // else pick the move with most space
    for (int k = 0; k < 4; k++) {
        int n = h + dirs[k];
        if (!passable(n)) continue;
        int a = flood(n);
        if (a > best_area) { best_area = a; best = k; }
    }
    return best;
}

// ANSI 256 color codes, same color for background and text
// so each 2 char cell shows as a solid block
#define C_WALL  240
#define C_EMPTY 234
#define C_BODY  34
#define C_HEAD  46
#define C_FOOD  196

static int cur_color = -1;

static void set_color(int c) {
    if (c == cur_color) return;
    puts_("\x1b[48;5;"); putu((uint32_t)c);
    puts_(";38;5;");     putu((uint32_t)c);
    putch('m');
    cur_color = c;
}

static void draw(uint32_t score, uint32_t steps) {
    puts_("\x1b[H");
    int hcell = body[head];
    for (int y = 0; y < H; y++) {
        for (int x = 0; x < W; x++) {
            int i = (y << 5) | x;
            char c; int col;
            switch (grid[i]) {
                case WALL: c = '#'; col = C_WALL; break;
                case BODY: if (i == hcell) { c = '@'; col = C_HEAD; }
                           else            { c = 'o'; col = C_BODY; } break;
                case FOOD: c = '*'; col = C_FOOD; break;
                default:   c = ' '; col = C_EMPTY; break;
            }
            set_color(col);
            putch(c); putch(c);              // 2 chars per cell so it looks square
        }
        puts_("\x1b[0m\n");                  // reset color at end of line
        cur_color = -1;
    }
    puts_("\x1b[1;36m RV32I SNAKE\x1b[0m   score "); putu(score);
    puts_("   length "); putu(len);
    puts_("   step "); putu(steps);
    puts_("      \n");
}

int main(void) {
    for (int y = 0; y < H; y++)
        for (int x = 0; x < W; x++)
            grid[(y << 5) | x] = (x == 0 || y == 0 || x == W - 1 || y == H - 1) ? WALL : EMPTY;

    // start with a 3 cell snake, head on the right
    tail = 0; head = 2; len = 3;
    for (int k = 0; k < 3; k++) {
        body[k] = (uint16_t)((8 << 5) | (6 + k));
        grid[body[k]] = BODY;
    }
    place_food();

    uint32_t score = 0, steps = 0;
    puts_("\x1b[2J");
    draw(score, steps);

    int alive = 1;
    while (alive && score < TARGET_SCORE && steps < MAX_STEPS) {
        int d = choose_move();
        if (d < 0) { alive = 0; break; }
        int next = body[head] + dirs[d];
        int ate = (grid[next] == FOOD);
        if (!ate) { grid[body[tail]] = EMPTY; tail = (tail + 1) & (N - 1); }
        else      { score++; len++; }
        if (grid[next] == WALL || grid[next] == BODY) { alive = 0; break; }
        grid[next] = BODY;
        head = (head + 1) & (N - 1);
        body[head] = (uint16_t)next;
        steps++;
        if (ate) place_food();
        draw(score, steps);
    }

    puts_(alive ? "\n  TARGET REACHED\n"
                : "\n  GAME OVER\n");
    return (int)score;
}
