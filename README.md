---
title: "NFL Fantasy Football Stats Repository"
author: "Maxwell Skinner"
date: "`r Sys.Date()`"
output: html_document
---

# nflstatsR

Personal Project with the goal of analyzing NFL stats and trends to optimize fantasy football drafting and mid-season roster adjustments and trade analyzers

## Overview

This repository uses the **nflreadr** package used for analysis, modeling, and visualizations. This package gives real-time and historical data from the ESPN

## Data Source

Obtained most NFL data from the [**nflverse**](https://github.com/nflverse/nflverse-data), which offers real-time and historical insights

## Repository Structure

## THIS IS EXAMPLE OUTLINE STRUCTURE, WILL CHANGE AS I AM FURTHER INTO THIS PROJECT

### `/data/`

-   Stores all data files used in analysis.
-   **`raw/`**: Contains unprocessed raw datasets.
-   **`processed/`**: Contains cleaned and transformed data for analysis.
-   Example files:
    -   `nfl_fantasy_2023.csv`: Contains fantasy player statistics for the 2023 season.
    -   `nfl_player_stats.csv`: Aggregated player performance statistics.

### `/notebooks/`

-   Contains **Jupyter notebooks** for exploratory analysis and modeling.
-   Example notebooks:
    -   `exploratory_analysis.ipynb`: Initial exploration of the dataset.
    -   `modeling.ipynb`: Machine learning models for predicting fantasy football performance.

### `/src/`

-   Includes **Python scripts** for data collection and processing.
-   Example scripts:
    -   `data_scraper.py`: Fetches fantasy football data from APIs.
    -   `data_cleaning.py`: Cleans and preprocesses raw data.
    -   `fantasy_projections.py`: Generates player projections using statistical models.

### `/visualizations/`

-   Stores **images and dashboards** used to present results.
-   Example files:
    -   `fantasy_dashboard.png`: Screenshot of Tableau dashboard.
    -   `top_performers_chart.png`: Visualization of top fantasy performers.

### Key Documentation Files

-   `README.md`: Provides an overview of the project and instructions for use.
-   `dashboard.md`: Contains a link to the public **Tableau dashboard** and insights.
-   `research.md`: Documents findings, methodologies, and key insights from the project.
-   `requirements.txt`: Lists Python dependencies needed to run scripts.

## Getting Started

To get started with this repository: 1. Clone the repository: `bash    git clone https://github.com/your-username/nfl-fantasy-stats.git    cd nfl-fantasy-stats` 2. Install dependencies: `bash    pip install -r requirements.txt` 3. Open the **notebooks** and explore the **visualizations** for insights.

------------------------------------------------------------------------

This structure ensures a well-organized repository for **data analysis, modeling, and visualization**. 🚀

## Questions to Answer:

-   How do I measure offensive line performance?
-   How DIRECTLY does offensive line performance affect key positions (QB, WR, RB, TE)
-   How to estimate number of targets of a specific player in a game?
-   Correlation between number of targets and number of yards/TDs?
-   How to find a QB's "favorite player to throw too"
    -   eg. Mahomes/Kelce, Burrow/Chase
-   Classifying "high risk" QBs
    -   eg. Cousins
-   Way to track injuries in real time and find who is next on the depth chart or potential likely players to pick up and substitute
    -   Looking specifically for a quick pick up in some cases
        -   eg. Pacheco injury --\> Hunt pickup, Cousins benched --\> Penix Jr.
-   How a player's predicted stats is affected when traded to a new team?
