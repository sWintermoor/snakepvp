#pragma once

inline bool SHOW_COMMENTS = true;

inline int GAME_SPEED = 3;
inline int GAME_SIZE = 5;
inline int GRID_SIZE = 5 * GAME_SIZE;
inline int CELL_SIZE = 6 * GAME_SIZE;
inline int WIDTH = GRID_SIZE * CELL_SIZE;
inline int HEIGHT = GRID_SIZE * CELL_SIZE;

inline int VELOCITY_NORMAL = 3;
inline int BOOST = 1;
inline int BOOST_DURATION_INITIAL = 0;
inline int BOOST_DURATION = 15;
inline int IMMUNITY_DURATION_INITIAL = 0;
inline int IMMUNITY_DURATION = 15;
inline int SCORE_INITIAL = 0;
inline int BANANA_INITIAL = 0;
inline int BLUEBERRY_INITIAL = 0;

inline int TIMER_INITIAL = 180 * GAME_SPEED;
inline int TICK_PAUSE = 100;
inline int FRUIT_SHIFT = 15;
