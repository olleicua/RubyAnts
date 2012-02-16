#!/usr/bin/env sh
./playgame.py --player_seed 42 --end_wait=0.25 --verbose --log_dir game_logs --turns 1000 --map_file maps/maze/maze_04p_01.map "$@" "python sample_bots/python/LeftyBot.py" "ruby bots/explore.rb" "ruby bots/explore.rb" "ruby bots/random.rb"
