import std.algorithm;
import std.array;
import std.conv;
import std.file;
import std.math;
import std.format;
import std.range;
import std.regex;
import std.stdio;
import std.string;
import std.typecons;
import core.thread;

import game;
import profitAndOccurances;
import rule;
import season;
import conf;
import ruleAndProfit;
import ruleSearch;
import profitEstimator;

//////////
// MAIN //
//////////

void main(string[] args) {
//  randomRuleSearch();
//  estimateProfit();
  printUpcomingGames();
}

void printUpcomingGames() {
  writeln("Start");
  RuleAndProfit[] rules = loadRules("results/random-rules");
  orderByScore(rules);
//  writeln("Loading season");
  string[] seasonsStr = getAllSeasonsOfYear("csv", 2015);
//  writeln("Seasons ### ");
  Season[] seasons = loadAll(seasonsStr);
  Season[] lastSeasons = loadAll(getSeasonsBeforeNoDir(seasonsStr));
  linkSeasons(seasons ~ lastSeasons);
//  writeln("Linked seasons");

  Game[] upcomingGames = readUpcomingGames();
  addGamesToRightSeason(upcomingGames, seasons);
  GameAndRule[] gamesAndRules = getDistancesOfUpcomingGames(seasons, rules);
  sortByDate(gamesAndRules);
  foreach (gar; gamesAndRules) {
    printGar(gar);
  }
  writeln("\nThe End");
}

// Orders list of Games with Rules by date.
void sortByDate(GameAndRule[] gamesAndRules) {
//  auto nondominatedSolutions = getNondominatedSolutions(rules);
//  foreach (rule; rules) {
//    rule.distanceFromFront = getDistanceFromNondominatedLine(nondominatedSolutions, rule);
//  }
  sort!("a.game.getDateTime() < b.game.getDateTime", SwapStrategy.stable)(gamesAndRules);
}

void addGamesToRightSeason(Game[] upcomingGames, Season[] currentSeasons) {
  foreach (game; upcomingGames) {
    string leagueAbv = game.sAttrs["Div"];
//    writeln("### League abv: "~leagueAbv);
    foreach (season; currentSeasons) {
      if (season.features["sport"] == "football" &&
          season.features["country"] == COUNTRY_OF_ABV[leagueAbv] &&
          season.features["league"] == LEAGUE_LEVEL_OF_ABV[leagueAbv] &&
          season.features["season"] == "2015") { // TODO current season begining year
        season.games ~= game;
        break;
      }
    }
  }
}

Game[] readUpcomingGames() {
  string dir = "../odds-scraper/results/";
  Game[] res;
  foreach (filename; dirEntries(dir, "*.txt", SpanMode.shallow)) {
    res ~= readUpcomingGamesFromFile(filename);
  }
  return res;
}

Game[] readUpcomingGamesFromFile(string filename) {
//  writeln("### Upcoming games filename: " ~filename);
  Game[] res;
  // TODO get actual year.
  // '../odds-scraper/results/football_belgium_jupiler-pro-league_2016-02-21_00-03-26.txt'
  string leagueNameWithDir = filename.split("_2016")[0];
  // '../odds-scraper/results/football_belgium_jupiler-pro-league'
//  writeln("### leagueNameWithDir: " ~leagueNameWithDir);
  string leagueName = leagueNameWithDir.split('/')[$-1];
  // 'football_belgium_jupiler-pro-league'
//  writeln("### LeagueName: " ~leagueName);
  string leagueAbv = SHORTER_LEAGUE_NAMES[leagueName];
  string[] lines = readFile(filename);
  string[] buf;
  foreach (line; lines) {
    if (line == "") {
      res ~= getGame(buf, leagueAbv);
      buf = [];
      continue;
    }
    buf ~= line;
  }
//  writeln("### Games: " ~ to!string(res));
  return res;
}

//  Game record looks like this:
//    link;https://www.betbrain.com/football/france/ligue-2/olympique-nimes-v-fc-metz/
//    time;22/02/16 19:30
//    name;Nimes - Metz
//    bet;1X2
//    odds;2.55 3.30 3.18
//    bet;Asian Handicap
//    odds;1.77 0 2.26
//    bet;Over Under
//    odds;2.20 2.5 1.82
Game getGame(string[] lines, string leagueAbv) {
  string date;
  string homeTeam;
  string awayTeam;
  string link;
  string time;
  foreach (line; lines) {
    auto linkMatch = matchFirst(line, regex("^link;"));
    if (!linkMatch.empty) {
      // 'link;https://www.betbrain.com/football/france/ligue-2/olympique-nimes-v-fc-metz/'
      link = linkMatch.post;
      // 'https://www.betbrain.com/football/france/ligue-2/olympique-nimes-v-fc-metz/'
    }
    auto pairMatch = matchFirst(line, regex("^name;"));
    if (!pairMatch.empty) {
      // 'name;Nimes - Metz'
      string pair = pairMatch.post;
      // 'Nimes - Metz'
      auto teams = pair.split(" - ");
      // [ 'Nimes', 'Metz' ]
      if (teams.length < 2) {
        writeln("Error in reading teams from upcoming game file!");
        return null;
      }
      homeTeam = teams[0];
      awayTeam = teams[1];
    }
    auto timeMatch = matchFirst(line, regex("^time;"));
    if (!timeMatch.empty) {
      // 'time;22/02/16 19:30'
      string timeAndDate = timeMatch.post;
      // '22/02/16 19:30'
      string[] splitTime = timeAndDate.split();
      // [ '22/02/16', '19:30' ]
      if (splitTime.length < 2) {
        writeln("Error in reading time from upcoming game file!");
        return null;
      }
      date = splitTime[0];
      time = splitTime[1];
    }
  }
  string[string] atrs = [ "Div": leagueAbv, "Date": date, "HomeTeam": homeTeam, "AwayTeam": awayTeam, "Link": link,
                          "Time": time ];
  return new Game(atrs);
}

void printGar(GameAndRule gar) {
  if (gar.rule is null) {
    return;
  }
  printAttrAndComma(gar, "Date");
  printAttrAndComma(gar, "Time");
  printAttrAndComma(gar, "HomeTeam");
  printAttrAndComma(gar, "AwayTeam");
  write(gar.rule.pao.getBestResult());
  write(",");
  write(gar.rule.distanceFromFront);
  write(",");
  write(gar.game.sAttrs["Link"]);
  writeln();
}

void printAttrAndComma(GameAndRule gar, string attr) {
  write(gar.game.sAttrs[attr]);
  write(",");
}

GameAndRule[] getDistancesOfUpcomingGames(Season[] seasons, RuleAndProfit[] rules) {
  GameAndRule[] res;
  foreach (season; seasons) {
    res ~= getDistancesOfUpcomingGames(season, rules);
  }
  return res;
}

GameAndRule[] getDistancesOfUpcomingGames(Season season, RuleAndProfit[] rules) {
  GameAndRule[] res;
  foreach (game; season.games) {
    // If game has result, then continue;
    if("FTR" in game.sAttrs) {
      continue;
    }
    RuleAndProfit rule = getBestRuleThatAplies(season, game, rules);
//    writeln("### Rule and profit that applies: "~to!string(rule));
    res ~= new GameAndRule(game, rule);
  }
//  writeln("### Distances: "~to!string(res));
  return res;
}

class GameAndRule {
  Game game;
  RuleAndProfit rule;
  this(Game game, RuleAndProfit rule) {
    this.game = game;
    this.rule = rule;
  }
}

/*
 * Returns result and distance, or null if no rule exists.
 */
RuleAndProfit getBestRuleThatAplies(Season season, Game game, RuleAndProfit[] rules) {
  foreach (rule; rules) {
    if (ruleAplies(game, season, rule.rule)) {
      return rule;
    }
  }
  return null;
}
