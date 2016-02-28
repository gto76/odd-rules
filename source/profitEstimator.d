module profitEstimator;

import std.stdio;
import std.algorithm;
import std.array;
import std.file;
import std.conv;
import std.datetime;
import std.math;

import game;
import profitAndOccurances;
import rule;
import season;
import conf;
import ruleAndProfit;
import ruleSearch;

void estimateProfit() {
//  calculateMargin();

  writeln("Start");
  RuleAndProfit[] rules = loadRules("results/rules-2014");
//  RuleAndProfit[] rules = loadRules("results/random-rules");
//  rules = rules ~ loadRules("results/random-rules");
//  orderByScore(rules);
  writeln("Loading season");

//  string[] seasonsStr = getAllSeasonsOfYear("csv", 2011);
  string[] seasonsStr = getAllSeasonsOfYear("current-season", 2015);

//  string[] seasonsStr = [ "football-scotland-0-2015" ];
//  writeln("Seasons ### ");
//  writeln(seasonsStr);
  Season[] seasons = loadAll(seasonsStr, "current-season");
//  Season[] seasons = loadAll(seasonsStr, "csv");
  Season[] lastSeasons = loadAll(getSeasonsBeforeNoDir(seasonsStr), "csv");
  linkSeasons(seasons ~ lastSeasons);
  writeln("Linked seasons");

  double distanceThreshold = double.max;
  double profitThreshold = 0.3;
  bool print = false;
  double[] profit = getEstimateForSeasons(seasons, rules, distanceThreshold, profitThreshold, print);
  double profitSum = profit[0];
  double bets = profit[1];
  double allBets = profit[2];
  writeln("==============");
  writeln("Betet times: " ~ to!string(bets) ~ "/"  ~ to!string(allBets));
  writeln("Average profit: "~to!string(profitSum/bets));
  writeln("\nThe End");
}

double[] getEstimateForSeasons(Season[] seasons, RuleAndProfit[] rules, double distanceThreshold,
                               double profitThreshold, bool print) {
  double profitSum = 0;
  double bets = 0;
  double allBets = 0;
  foreach (season; seasons) {
//    Game[] games = getGamesAfter(season.games, DateTime(2016, 1, 18));
//    Game[] games = getGamesBetween(season.games, DateTime(2015, 10, 18), DateTime(2015, 11, 18));
//    Game[] games = getGamesAfter(season, DateTime(2016, 2, 19));
    Game[] games = season.games;
    double[] profit = getProfitForGames(games, season, rules, distanceThreshold, profitThreshold, print);
    if (!isNaN(profit[0])) {
      profitSum += profit[0];
      bets += profit[1];
      allBets += profit[2];
    }
  }
  return [ profitSum, bets, allBets ];
}

void calculateMargin() {
  writeln("Start");
  writeln("Loading season");
//  string[] seasonsStr = getAllSeasonsOfYear("csv", 2011);
  string[] seasonsStr = getAllSeasonsOfYear("current-season", 2015);
  Season[] seasons = loadAll(seasonsStr, "current-season");
  double profitSum = 0;
  double bets = 0;
  double allBets = 0;
  foreach (season; seasons) {
    Game[] games = season.games;
    double[] profit = getMarginForGames(games);
    if (!isNaN(profit[0])) {
      profitSum += profit[0];
      bets += profit[1];
      allBets += profit[2];
    }
  }
  writeln("==============");
  writeln("Betet times: " ~ to!string(bets) ~ "/"  ~ to!string(allBets));
  writeln("Average margin: "~to!string(profitSum/bets));
  writeln("\nThe End");
}

double[] getMarginForGames(Game[] games) {
//  double profitSumH = 0;
//  double profitSumD = 0;
//  double profitSumA = 0;
  double[Res] profit = [ Res.A: 0, Res.D: 0, Res.A: 0 ];
  double bets = 0;
  double allBets = 0;
  foreach (game; games) {
    Res actualResult;
    try {
      actualResult = game.getResult();
    } catch (Exception e) {
//          writeln("Game does not have a result: ");
//          writeln(game);
      continue;
    }
    profit[actualResult] += game.getProfit() + 1;
//    double profit;
//    if (actualResult == result) {
//      profit = game.getProfit();
//    } else {
//      profit = -1;
//    }
//    profitSum += profit;
    bets++;
    allBets++;
  }
  foreach (Res result; [Res.H, Res.D, Res.A]) {
    profit[result] -= bets;
  }
  double profitSum = (profit[Res.H] + profit[Res.D] + profit[Res.A]) / 3;
  return [ profitSum, bets, allBets ];
}

//class DateAndProfits {
//  Date date;
//  double[] profits;
//  this(Date date, double[] profits) {
//    this.date = date;
//    this.profits = profits;
//  }
//}
//
//public void estimateProfitByDay() {
//
//}
//
//DateAndProfits[] getDateAndProfitsSince(Date date, Season[] seasons, double threshold) {
//  DateAndProfits[] ret;
//  foreach (season; seasons) {
//    Game[] games = getGamesAfter(season, date);
//
//    double[] profit = getProfitForGames(games, season, rules, threshold);
//  }
//}

public Game[] getGamesAfter(Game[] games, DateTime dateTime) {
  Game[] ret;
  foreach (game; games) {
//    writeln(game.getDateTime());
    if (game.getDateTime() > dateTime) {
      ret ~= game;
    }
  }
  return ret;
}

public Game[] getGamesBefore(Game[] games, DateTime dateTime) {
  Game[] ret;
  foreach (game; games) {
    if (game.getDateTime() < dateTime) {
      ret ~= game;
    }
  }
  return ret;
}

public Game[] getGamesBetween(Game[] games, DateTime dateTimeStart, DateTime dateTimeEnd) {
  Game[] ret = getGamesAfter(games, dateTimeStart);
  return getGamesBefore(ret, dateTimeEnd);
}

public string[] getAllSeasonsOfYear(string dir, int year) {
  string[] ret;
//  writeln(dirEntries(dir, "*.csv", SpanMode.shallow));
  foreach (fileName; dirEntries(dir, "*.csv", SpanMode.shallow)) {
    string[] tokens = split(to!string(fileName), ".");
//    writeln(tokens);
    if (tokens.length < 2) {
      continue;
    }
    auto tokens1 = split(tokens[0], "-");
    if (tokens1.length < 2) {
      continue;
    }
//    writeln("bla "~tokens1);
    if (to!int(tokens1[$-1]) == year) {
      auto withouthDirTokens = tokens[0].split("/");
      ret ~= withouthDirTokens[1];
    }
  }
  return ret;
}

string[] getSeasonsBefore(string[] seasons) {
  string[] res;
  foreach (season; seasons) {
    writeln("Season before : "~season);
    string seasonBefore = getSeasonBefore(season);
    if (seasonBefore != "") {
      res ~= seasonBefore;
    }
  }
  return res;
}

string getSeasonBefore(string season) {
  writeln("Season: "~season);
  string[] tokens = split(season, ".");
  if (tokens.length < 2) {
    return "";
  }
  string[] tokens1 = tokens[0].split('-');
  if (tokens1.length < 2) {
    return "";
  }
  tokens1[$-1] = to!string(to!int(tokens1[$-1]) - 1);
  string ret = tokens1[0];
  for (int i = 1; i < tokens1.length; i++) {
    ret ~= '-' ~ tokens1[i];
  }
  return ret ~ ".csv";
}

string[] getSeasonsBeforeNoDir(string[] seasons) {
  string[] res;
  foreach (season; seasons) {
//    writeln("Season before : "~season);
    string seasonBefore = getSeasonBeforeNoDir(season);
    if (seasonBefore != "") {
      res ~= seasonBefore;
    }
  }
  return res;
}

string getSeasonBeforeNoDir(string season) {
//  writeln("Season: "~season);
  string[] tokens1 = season.split('-');
  if (tokens1.length < 2) {
    return "";
  }
  tokens1[$-1] = to!string(to!int(tokens1[$-1]) - 1);
  string ret = tokens1[0];
  for (int i = 1; i < tokens1.length; i++) {
    ret ~= '-' ~ tokens1[i];
  }
  return ret;
}

double[] getProfitForGames(Game[] games, Season season, RuleAndProfit[] rules, double distanceThreshold,
                           double profitThreshold, bool print) {
  int bets = 0;
//  writeln("Getting profit for season");
  double profitSum = 0;
//  writeln("Starting loop");
  if (print) {
    writeln("===========");
    writeln("Estimating sason: "~to!string(season.features));
    writeln("Reference sason: "~to!string(season.lastSeason.features));
    writeln("Number of games: "~to!string(games.length));
  }
  foreach (game; games) {
//    writeln(game);
    foreach (rule; rules) {
      if (rule.distanceFromFront > distanceThreshold) {
        break;
      }
//      if (rule.pao.occurances < 100) {
//        continue;
//      }
      if (rule.pao.getMaxProfit() < profitThreshold) {
        continue;
      }
      if (ruleAplies(game, season, rule.rule)) {
//        writeln("Rule applies: "~to!string(rule));
        Res result = rule.pao.getBestResult();
        Res actualResult;
        try {
          actualResult = game.getResult();
        } catch (Exception e) {
//          writeln("Game does not have a result: ");
//          writeln(game);
//          continue;
            break;
        }
        double profit;
        if (actualResult == result) {
          profit = game.getProfit();
        } else {
          profit = -1;
        }
        profitSum += profit;
        // CHECK THE RESULT !!!
        bets++;
        if (print) {
          printMatchingRule(game, rule, profit, bets, games, profitSum);
        }
        break; // There could be other rules that match, but we don't care.
      }
    }
  }
  return [ profitSum, bets, games.length ];
}

void printMatchingRule(Game game, RuleAndProfit rule, double profit, double bets, Game[] games, double profitSum) {
  writeln("-----------");
  writeln(game);
  writeln(rule);
  write("Profit: ");
  writeln(profit);
  writeln("BetNo: "~to!string(bets)~"/"~to!string(games.length));
  write("Season profit so far: ");
  writeln(profitSum);
  write("Avg season profit so far: ");
  writeln(profitSum/bets);
}

double[] getProfitForSeason(Season season, RuleAndProfit[] rules, double distanceThreshold, double profitThreshold,
                            bool print) {
  return getProfitForGames(season.games, season, rules, distanceThreshold, profitThreshold, print);
}

// Orders list of rules by score - distance to the front of nondominated solutions.
void orderByScore(RuleAndProfit[] rules) {
  auto nondominatedSolutions = getNondominatedSolutions(rules);
  foreach (rule; rules) {
    rule.distanceFromFront = getDistanceFromNondominatedLine(nondominatedSolutions, rule);
  }
  sort!("a.distanceFromFront < b.distanceFromFront", SwapStrategy.stable)(rules);
}

RuleAndProfit[] loadRules(string fileName) {
//    writeln("Loading rules");
  RuleAndProfit[] rules;
  string[] lines = readFile(fileName);
//      writeln("Loading rules 2");
  for (int i = 0; i < lines.length; i += 2) {
//        writeln("Loading rule " ~ to!string(i));
    auto rule = new Rule(lines[i]);
//        writeln("Loading profit " ~ to!string(i+1));
    auto poc = new ProfitAndOccurances(lines[i+1]);
    rules ~= new RuleAndProfit(rule, poc);
  }
//      writeln("Loading rules 3");
  orderByScore(rules);
  return rules;
}

string[] readFile(string fileName) {
  auto file = File(fileName, "r");
  string[] lines;
  foreach (line; file.byLine) {  // records = csvReader!(string[string])(file.byLine.joiner("\n"), null);
    lines ~= to!string(line);
  }
  return lines;
}
