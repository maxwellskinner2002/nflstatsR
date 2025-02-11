library(tidyverse)
library(ggrepel)
library(nflreadr)
library(nflplotR)

# WE ARE MAKING A COMPREHENSIVE LIST OF OFFENSIVE LINE STATS BY TEAM


# Analyzing the monetary value of offensive linemen 

"Biggest need for further analysis: attributing offensive linemen to specific sides of the OL. 
Current players are only listed as tackles/guards but there is no data indicating what side they were lined up on"

"Answer: If we limit to analysis of just starting lineman, we can have a strong assumption of which specific position each player played"


"game-by-game data for every offensive lineman that was recorded as having
played at least 1 snap in a regular season or playoff game from the 2013-2014 and 2014-2015
seasons."

"for each unique offensive line formation, can we establish the position (LG, RG, LT, RT) of the lineman present on that play?"

"
Unique game code
Playoff vs. Regular Game 
Game date 
Player name
Team
Opponent 
Position
Rookie year
Draft round
Draft pick
Birthday

Base Salary 
Signing bonus -- TBD
Incentives -- TBD
Cap Value -- Needs more work to fully flesh out
Snaps
Holding penalties on rush attempts 
Holding penalties on pass attempts 

* This group of stats are TBD until I can determine sides and directions of plays
Rush attempts to side/not to side
Stuffs to side/not to side
Rush yards to side/not to side
Rush touchdowns to side/not to side
Successful rushes to side/not to side

* to side/not to side stats are TBD until I can determine sides and directions of plays
Passing yards 
Dropbacks
Passing attempts 
Passing completions 
Sacks to side/not to side
Sack yards to side/not to side
Pressures to side/not to side
Hurries to side/not to side
Knockdowns to side/not to side
Quarterback release time/attempts 
Release time/attempts under pressure


* I am missing data for probowl appearances, all pro selections, and one other list but I forgot the name of

adjusted sack rate: sacks / (sacks + passes)
  - how frequently a passer was sacked per pass attempt

"




#load_pbp()) to get: Pressure, sacks, rush yards, and penalties.
##Direction of runs to determine blocking effectiveness.
## Match QB pressure to the side of the offensive line.
# load_participation() to track which OL were on the field for each snap.
# Merge with load_rosters() to get player-specific data (e.g., draft round, rookie year).
# Analyze Salaries (load_contracts()) to compare performance vs. cost.

#pbp <- load_pbp(2023)

library(tibble)

pbp_structure <- tibble::tibble(
  Column = names(pbp),
  Type = sapply(pbp, class)
)


# Load play participation from the 2023 regular season

participation <- load_participation(seasons = 2023, include_pbp = TRUE) %>% 
  filter(play_type %in% c("pass", "run")) %>% # Filter to only pass and run plays
  filter(season_type == "REG") %>%
  mutate(gsis_id = stringr::str_split(offense_players, ";"),
      stuffed = ifelse(play_type == "run" & yards_gained < 0, 1, 0), # Including stuffs as a binary indicator
         qbh_inc = ifelse(qb_hit == 1 & incomplete_pass == 1, 1,0), # QB hit, incomplete pass
         qb_int = ifelse(qb_hit == 1 & interception == 1, 1,0), # QB hit, interception
         aly_yards = case_when( # Including adjusted line yards
           play_type == "run" & yards_gained < 0 ~ yards_gained * 1.2,   # Losses: 120% value
           play_type == "run" & yards_gained >= 0 & yards_gained <= 4 ~ yards_gained * 1.0,  # 0-4 yards: 100% value
           play_type == "run" & yards_gained >= 5 & yards_gained <= 10 ~ yards_gained * 0.5, # 5-10 yards: 50% value
           play_type == "run" & yards_gained > 10 ~ 0,                  # 11+ yards: 0% value
           play_type == "pass" ~ 0,                                      # Pass plays get 0 ALY
           TRUE ~ NA_real_)) %>%
  #separate_rows(offense_players, sep = ";") # Splits listed players on plays into separate rows 
  tidyr::unnest(c(gsis_id))


participation <- participation %>% select(gsis_id, nflverse_game_id, play_id, possession_team, offense_formation, 
                         offense_personnel, players_on_play, offense_players,ngs_air_yards, time_to_throw, 
                         was_pressure, route, home_team, away_team, season_type, week, posteam, defteam, drive, 
                         play_type, yards_gained, qb_dropback, qb_kneel, qb_spike, qb_scramble, pass_length, pass_location, 
                         air_yards, yards_after_catch, run_location, run_gap, incomplete_pass, interception, qb_hit, 
                         rush_attempt, pass_attempt, sack, touchdown, pass_touchdown, rush_touchdown, rusher_player_id, 
                         rusher_player_name, rushing_yards, penalty_team, penalty_player_id, penalty_player_name, penalty_yards, 
                         penalty_type, stuffed, qbh_inc, qb_int, aly_yards) %>% 
                                    mutate(penalty_yards = ifelse(gsis_id == penalty_player_id, penalty_yards, 0)) # Assign penalty yards only if gsis_id matches the penalized player


participation_by_game <- participation %>% 
  group_by()r %>% 
  summarize() %>%
  ungroup()

# Load individual player information
rosters <- load_rosters(2023) %>% 
    select(full_name, gsis_id, position, depth_chart_position, birth_date, rookie_year, 
           height, weight, draft_number, headshot_url)

# Load player contracts, filtering to most recent contract
contracts <- load_contracts() %>% 
    select(gsis_id, year_signed, years, value, apy, guaranteed, apy_cap_pct, inflated_value, 
           inflated_apy, inflated_guaranteed, draft_round, draft_overall, draft_year, draft_team) %>% 
  #group_by(gsis_id, year_signed, years) %>% 
  arrange(gsis_id, desc(year_signed)) %>%  # Sort by player ID & most recent contract first
  distinct(gsis_id, .keep_all = TRUE)  # Keep only the first occurrence per player


# Joining initial roster information with their lastest contract information
rosters <-  rosters %>% left_join(contracts, by = c("gsis_id" = "gsis_id"))


# Active lineup of each offensive player per player per play
full_lineup_by_play <- participation %>%
  left_join(rosters, by = c("gsis_id" = "gsis_id"))

total_pbp_structure <- tibble::tibble(
  Column = names(participation),
  Type = sapply(participation, class)
)


# Filtering to only offensive line players 
# Not including epa/wpa columns, nor anything pertaining to special teams blocking yet. 
# This is play by play information that is not aggregated at all yet

ol_participation <- full_lineup_by_play %>% 
  filter(depth_chart_position %in% c("T", "G", "C")) 


# Loads 2024 season snap counts for each player by each game
snap_counts <- load_snap_counts(season = 2023) %>% filter(game_type == "REG")

# Has all player ids to join different data sets together
player_ids <- load_ff_playerids()

# Advanced RB performance by game or by season
# Join by game id and team to attribute these stats to players
rush_advstats <- load_pfr_advstats(season = 2023, stat_type = "rush")

# Advanced QB related stats by season or by game for each respective QB. Include season argument if wanting historical data
pass_advstats <- load_pfr_advstats(season = 2023, stat_type = "pass")











