module conf;

import rule;

/*
 * From app.d
 */
int NUM_OF_RUNS = 100000;
string[] ATTRIBUTES = ["FTHG", "FTAG", "HTHG", "HTAG", "HS", "AS", "HST", "AST", "HF", "AF", "HC",
                       "AC", "HY", "AY", "HR", "AR"];
int WIDEST_WINDOW = 10;
int OCCURANCE_TRESHOLD = 50;

/*
 * From season.d
 */
string[] SEASON_FEATURES = ["sport", "country", "league", "season"];
bool USE_DISTRIBUTIONS_CACHE = true;

const (Team[string]) ATTRIBUTES_TEAM;
const (string[string]) OTHER_TEAM_ATTRIBUTE;

static this() {
  // TODO + result, reasult half time, odds
  ATTRIBUTES_TEAM = [
    "FTHG" : Team.H,
    "FTAG" : Team.A,
    "HTHG" : Team.H,
    "HTAG" : Team.A,
    "HS" : Team.H,
    "AS" : Team.A,
    "HST" : Team.H,
    "AST" : Team.A,
    "HF" : Team.H,
    "AF" : Team.A,
    "HC" : Team.H,
    "AC" : Team.A,
    "HY" : Team.H,
    "AY" : Team.A,
    "HR" : Team.H,
    "AR" : Team.A
  ];

  OTHER_TEAM_ATTRIBUTE = [
    "FTHG" : "FTAG",
    "FTAG" : "FTHG",
    "HTHG" : "HTAG",
    "HTAG" : "HTHG",
    "HS" : "AS",
    "AS" : "HS",
    "HST" : "AST",
    "AST" : "HST",
    "HF" : "AF",
    "AF" : "HF",
    "HC" : "AC",
    "AC" : "HC",
    "HY" : "AY",
    "AY" : "HY",
    "HR" : "AR",
    "AR" : "HR"
  ];
}

/*
 * From game.d
 */
 bool DEBUG = false;

 public static const bool USE_AVERAGE_ODDS = true;
 public static const string BETBRAIN_AVERAGE = "BbAv";
 public static const string BETBRAIN_MAX = "BbMx";

 public static const string[] STRING_ATTRIBUTES = [ "Div", "Date", "HomeTeam", "AwayTeam", "FTR",
                                                    "HTR", "Referee" ];
