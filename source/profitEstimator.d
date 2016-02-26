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
  writeln("Start");
  RuleAndProfit[] rules = loadRules("results/rules-2014");
  writeln("Loading season");
//  string[] seasonsStr = getAllSeasonsOfYear("csv", 2015);
  string[] seasonsStr = getAllSeasonsOfYear("current-season", 2015);
  writeln("Seasons ### ");
//  writeln(seasonsStr);
  Season[] seasons = loadAll(seasonsStr, "current-season");
  Season[] lastSeasons = loadAll(getSeasonsBeforeNoDir(seasonsStr), "csv");
  linkSeasons(seasons ~ lastSeasons);
  writeln("Linked seasons");
  double profitSum = 0;
  double bets = 0;
  double allBets = 0;
  foreach (season; seasons) {
    Game[] games = getGamesAfter(season, DateTime(2016, 1, 18, 12, 0));
//    writeln(games);
//    double[] profit = getProfitForSeason(season, rules, 0.01);
    double[] profit = getProfitForGames(games, season, rules, 0.01);
    if (!isNaN(profit[0])) {
      profitSum += profit[0];
      bets += profit[1];
      allBets += profit[2];
    }
  }
  writeln("==============");
  writeln("Betet times: " ~ to!string(bets) ~ "/"  ~ to!string(allBets));
  writeln("Average profit: "~to!string(profitSum/bets));
  writeln("\nThe End");
}

public Game[] getGamesAfter(Season season, DateTime dateTime) {
  Game[] ret;
  foreach (game; season.games) {
//    writeln(game.getDateTime());
    if (game.getDateTime() > dateTime) {
      ret ~= game;
    }
  }
  return ret;
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

double[] getProfitForGames(Game[] games, Season season, RuleAndProfit[] rules, double threshold) {
  int bets = 0;
//  writeln("Getting profit for season");
  double profitSum = 0;
  orderByScore(rules);
//  writeln("Starting loop");
  writeln("===========");
  writeln("Estimating sason: "~to!string(season.features));
  writeln("Last sason: "~to!string(season.lastSeason.features));
  foreach (game; games) {
    foreach (rule; rules) {
      if (rule.distanceFromFront > threshold) {
        break;
      }
      // TODO, here last season should probably be passed, as a reference season.
      if (ruleAplies(game, season, rule.rule)) {
        Res result = rule.pao.getBestResult();
        Res actualResult;
        try {
          actualResult = game.getResult();
        } catch (Exception e) {
          // Game does not have an result, continue.
          continue;
        }
        double profit;
        if (actualResult == result) {
          profit = game.getProfit();
        } else {
          profit = -1;
        }
        profitSum += profit;
        // CHECK THE RESULT !!!
        writeln("-----------");
//        writeln("Betting on game: ");
//        writeln(game);
//        writeln("Rule: ");
        writeln("Date: "~game.sAttrs["Date"]);
        writeln("Teams: "~game.sAttrs["HomeTeam"]~" - "~game.sAttrs["AwayTeam"]);
        writeln(rule);
        write("Profit: ");
        writeln(profit);
        writeln("BetNo: "~to!string(bets++)~"/"~to!string(games.length));
        write("Season profit so far: ");
        writeln(profitSum);
        write("Avg season profit so far: ");
        writeln(profitSum/bets);
      }
    }
  }
  return [ profitSum, bets, season.games.length ];
}

double[] getProfitForSeason(Season season, RuleAndProfit[] rules, double threshold) {
  return getProfitForGames(season.games, season, rules, threshold);
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
