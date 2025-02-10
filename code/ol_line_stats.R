library(tidyverse)
library(ggrepel)
library(nflreadr)
library(nflplotR)

# WE ARE MAKING A COMPREHENSIVE LIST OF OFFENSIVE LINE STATS BY TEAM


# Analyzing the monetary value of offensive linemen 

"game-by-game data for every offensive lineman that was recorded as having
played at least 1 snap in a regular season or playoff game from the 2013-2014 and 2014-2015
seasons."

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

"




#load_pbp()) to get: Pressure, sacks, rush yards, and penalties.
##Direction of runs to determine blocking effectiveness.
## Match QB pressure to the side of the offensive line.
# load_participation() to track which OL were on the field for each snap.
# Merge with load_rosters() to get player-specific data (e.g., draft round, rookie year).
# Analyze Salaries (load_contracts()) to compare performance vs. cost.

pbp <- load_pbp(2023)

library(tibble)

pbp_structure <- tibble::tibble(
  Column = names(pbp),
  Type = sapply(pbp, class)
)


# Load play participation from the 2023 regular season

participation <- load_participation(seasons = 2023, include_pbp = TRUE) %>% 
  filter(play_type %in% c("pass", "run")) %>% # Filter to only pass and run plays
  filter(season_type == "REG") %>%
  separate_rows(offense_players, sep = ";") # Splits listed players on plays into separate rows 


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
  left_join(rosters, by = c("offense_players" = "gsis_id"))

participation_structure <- tibble::tibble(
  Column = names(participation),
  Type = sapply(participation, class)
)


# Filtering to only offensive line players 
ol_participation <- full_lineup_by_play %>% filter(depth_chart_position %in% c("T", "G", "C")) 


