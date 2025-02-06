library(tidyverse)
library(ggrepel)
library(nflreadr)
library(nflplotR)



# How do I measure offensive line performance?

"
Measuring offensive line performance:
1. sacks 
2. QB hits
3. tackles for loss
4. yards gained less than/equal to 2
5. forcing a QB scramble 
"

pbp <- load_pbp(2024) %>%
  filter(season_type == "REG") %>%
  filter(!play_type %in% c("kickoff", "no_play")) %>%
  #filter(pass == 1 | rush == 1) %>%
  mutate(qbh_inc = ifelse(qb_hit == 1 & incomplete_pass == 1, 1,0),
         qb_int = ifelse(qb_hit == 1 & interception == 1, 1,0))

ls(pbp)

kc_plays <- pbp %>%
  filter(posteam == "KC") %>%
  group_by(week) %>%
  summarize(
    total_plays = sum(play_type == "run" |
                        play_type == "pass", na.rm = TRUE))


kc_line_value <- pbp %>%
  filter(sack == 1 |
           tackled_for_loss == 1 |
           yards_gained <= 2 |
           qb_scramble == 1 |
           qb_hit == 1 |
           qbh_inc == 1 |
           qb_int == 1) %>%
  filter(posteam == "KC") %>%
  group_by(posteam, week) %>%
  left_join(kc_plays, by = c("week" = "week")) %>%
  summarize(opponent = unique(defteam),
            sum_wpa = sum(wpa, na.rm = TRUE),
            avg_wpa = (sum_wpa / unique(total_plays) * 100))


# Gathering the same information as above but for the entire NFL minus the Chiefs, 
# then calculate the difference in the Chiefs; weekly WPA to the league-wide average WPA.


nfl_plays <- pbp %>%
  filter(posteam != "KC") %>%
  group_by(week, posteam) %>%
  summarize(total_plays = sum(play_type == "run" | play_type == "pass",
                              na.rm = TRUE))

nfl_line_value <- pbp %>%
  filter(posteam != "KC") %>%
  filter(sack == 1 |
           tackled_for_loss == 1 |
           yards_gained <= 2 |
           qb_scramble == 1 |
           qb_hit == 1 |
           qbh_inc == 1 |
           qb_int == 1) %>%
  left_join(nfl_plays,
            by = c("posteam" = "posteam", "week" = "week")) %>%
  group_by(week) %>%
  mutate(nfl_weekly_plays = sum(unique(total_plays))) %>%
  summarize(nfl_sum_wpa = sum(wpa, na.rm = TRUE),
            nfl_avg_wpa = (nfl_sum_wpa / unique(nfl_weekly_plays) * 100))


kc_line_value <- kc_line_value %>%
  left_join(nfl_line_value, by = c("week" = "week"))

kc_line_value <- kc_line_value %>%
  mutate(final_value = avg_wpa - nfl_avg_wpa) %>%
  select(week, opponent, final_value)

kc_line_value %>%
  print(n = 17)


#Output: values of KC offensive line performance over the course of the season in the "final_value" column.
# In week 1, the chief's provided -0.04% less WPA than the rest of the NFL. 




# Applying this to each team and measuring all offensive line performance

# Count total offensive plays for each team
team_plays <- pbp %>%
  group_by(posteam, week) %>%
  summarize(total_plays = sum(play_type == "run" | play_type == "pass", na.rm = TRUE),
            .groups = "drop")



# Filter negative plays affecting offensive line performance
team_line_value <- pbp %>%
  filter(sack == 1 |
           tackled_for_loss == 1 |
           yards_gained <= 2 |
           qb_scramble == 1 |
           qb_hit == 1 |
           qbh_inc == 1 |
           qb_int == 1) %>%
  group_by(posteam, week) %>%
  left_join(team_plays, by = c("posteam", "week")) %>%
  summarize(sum_wpa = sum(wpa, na.rm = TRUE),
            avg_wpa = (sum_wpa / unique(total_plays)) * 100,
            .groups = "drop")

# Calculate season-long average WPA for each team
team_season_wpa <- team_line_value %>%
  group_by(posteam) %>%
  summarize(season_avg_wpa = mean(avg_wpa, na.rm = TRUE),
            .groups = "drop")

# Calculate the NFL-wide average WPA excluding each team
nfl_avg_excluding_team <- team_season_wpa %>%
  rowwise() %>%
  mutate(nfl_avg_wpa = mean(team_season_wpa$season_avg_wpa[team_season_wpa$posteam != posteam], na.rm = TRUE)) %>%
  ungroup()

# Compare each team's WPA against the NFL average (excluding themselves)
ol_ranking <- nfl_avg_excluding_team %>%
  mutate(final_value = season_avg_wpa - nfl_avg_wpa) %>%
  arrange(desc(final_value))  # Rank from best to worst



## Analyzing team OL performance and how it affects position groups (WR, TE, RB, QB)

player_stats <- load_player_stats() %>% filter(season_type == "REG")

player_summary <- player_stats %>%
  group_by(player_id, player_name, position, recent_team) %>%
  #summarise(
  reframe(
    pass_yards = sum(passing_yards, na.rm = TRUE),
    pass_tds = sum(passing_tds, na.rm = TRUE),
    interceptions = sum(interceptions, na.rm = TRUE),
    rush_yards = sum(rushing_yards, na.rm = TRUE),
    rush_tds = sum(rushing_tds, na.rm = TRUE),
    rec_yards = sum(receiving_yards, na.rm = TRUE),
    rec_tds = sum(receiving_tds, na.rm = TRUE),
    rec_catches = sum(receptions, na.rm = TRUE),
    games_played = n(),
    avg_passing_epa = (sum(passing_epa, na.rm = TRUE) / games_played),
    avg_receiving_epa = (sum(receiving_epa, na.rm = TRUE) / games_played),
    avg_rushing_epa = (sum(rushing_epa, na.rm = TRUE) / games_played),
) %>%
  ungroup()


player_summary <- player_summary %>%
  mutate(
    pass_ypa = ifelse(pass_yards > 0, pass_yards / (pass_yards + interceptions), NA),
    td_to_int = ifelse(interceptions > 0, pass_tds / interceptions, pass_tds),
    rec_ypr = ifelse(rec_catches > 0, rec_yards / rec_catches, NA)
  )


# Avg EPA: add the EPA of all plays a player is directly involved in, and then divide by the number of plays

# Calculating number of plays a player was involved in
player_activity <- pbp %>%
  filter(!is.na(passer) | !is.na(rusher) | !is.na(receiver)) %>% # Keep plays where a player is involved
  mutate(active_player = coalesce(passer, rusher, receiver)) %>% # Create a single column for player involvement
  group_by(active_player) %>%
  summarise(plays_active = n())


# Merging play counts with existing player summary
player_summary <- player_summary %>% left_join(player_activity, by = c("player_name" = "active_player"))


# Player Summaries by position group to perform LR. 

qb_performance <- player_summary %>% filter(position == "QB") %>% arrange(recent_team, desc(pass_yards)) %>%
  distinct(recent_team, .keep_all = TRUE)  # Keep only the top QB for each team

wr_performance <- player_summary %>% filter(position == "WR") %>% arrange(recent_team, desc(rec_yards)) %>%
  distinct(recent_team, .keep_all = TRUE)  # Keep only the top QB for each team

rb_performance <- player_summary %>% filter(position == "RB") %>% arrange(recent_team, desc(rush_yards)) %>%
  distinct(recent_team, .keep_all = TRUE)  # Keep only the top QB for each team

# Merge OL performance with QB stats
analysis_data <- rb_performance %>%
  left_join(ol_ranking, by = c("recent_team" = "posteam"))

# Filter to top QB of each team
#analysis_data <- analysis_data %>%
#filter(games_played >= 8)



# Code for visualization

teams <- nflreadr::load_teams(current = TRUE) %>%
  select(team_abbr, team_nick, team_color, team_color2)

analysis_data <- analysis_data %>%
  left_join(teams, by = c("recent_team" = "team_abbr"))

colnames(analysis_data)


# Visual for QB passing epa vs offensive line wpa 
ggplot(data = analysis_data, aes(x = season_avg_wpa, y = avg_rushing_epa)) +
  geom_point(shape = 21,
             fill = analysis_data$team_color,
             color = analysis_data$team_color2,
             size = 4.5) +
  geom_text_repel(aes(label = player_name))

  # Linear regression to see OL impact on QB performance
model <- lm(avg_rushing_epa ~ season_avg_wpa, data = analysis_data)
summary(model)




