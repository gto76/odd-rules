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

double Y_AXIS_DIVIDER = 10000;

/*
 * From season.d
 */
string[] SEASON_FEATURES = ["sport", "country", "league", "season"];
bool USE_DISTRIBUTIONS_CACHE = true;

const (Team[string]) ATTRIBUTES_TEAM;
const (string[string]) OTHER_TEAM_ATTRIBUTE;
const (string[string]) SHORTER_LEAGUE_NAMES;
const (string[string]) COUNTRY_OF_ABV;
const (string[string]) LEAGUE_LEVEL_OF_ABV;

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

  // TODO premier league - check if works
  SHORTER_LEAGUE_NAMES = [
    "football_belgium_jupiler-pro-league" : "B1",
    "football_england_premier-league" : "E0",
    "football_england_championship" : "E1",
    "football_england_conference-premier" : "E4",
    "football_england_league-1" : "E2",
    "football_england_league-2" : "E3",
    "football_france_ligue-1" : "F1",
    "football_france_ligue-2" : "F2",
    "football_germany_2-bundesliga" : "D2",
    "football_germany_bundesliga" : "D1",
    "football_greece_super-league" : "G1",
    "football_italy_serie-a" : "I1",
    "football_italy_serie-b" : "I2",
    "football_netherlands_eredivisie" : "N1",
    "football_portugal_primeira-liga" : "P1",
    "football_scotland_championship" : "SC1",
    "football_scotland_league-one" : "SC2",
    "football_scotland_league-two" : "SC3",
    "football_scotland_premiership" : "SC0",
    "football_spain_primera-division" : "SP1",
    "football_spain_segunda-division" : "SP2",
    "football_turkey_super-lig" : "T1"
  ];

  COUNTRY_OF_ABV = [
    "B1" : "belgium" ,
    "E0" : "england",
    "E1" : "england",
    "E4" : "england",
    "E2" : "england",
    "E3" : "england",
    "F1" : "france",
    "F2" : "france",
    "D2" : "germany",
    "D1" : "germany",
    "G1" : "greece",
    "I1" : "italy",
    "I2" : "italy",
    "N1" : "netherlands",
    "P1" : "portugal",
    "SC1" : "scotland",
    "SC2" : "scotland",
    "SC3" : "scotland",
    "SC0" : "scotland",
    "SP1" : "spain",
    "SP2" : "spain",
    "T1" : "turkey"
  ];

  LEAGUE_LEVEL_OF_ABV  = [
    "B1" : "0" ,
    "E0" : "0",
    "E1" : "1",
    "E4" : "4",
    "E2" : "2",
    "E3" : "3",
    "F1" : "0",
    "F2" : "1",
    "D2" : "1",
    "D1" : "0",
    "G1" : "0",
    "I1" : "0",
    "I2" : "1",
    "N1" : "0",
    "P1" : "0",
    "SC1" : "1",
    "SC2" : "2",
    "SC3" : "3",
    "SC0" : "0",
    "SP1" : "0",
    "SP2" : "1",
    "T1" : "0"
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
