module profitEstimator;

import std.stdio;
import std.algorithm;
import std.array;
import std.file;
import std.conv;
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
  RuleAndProfit[] rules = loadRules("results/random-rules");
  writeln("Loading season");
  string[] seasonsStr = getAllSeasonsOfYear("csv", 2015);
  writeln("Seasons ### ");
//  writeln(seasonsStr);
  Season[] seasons = loadAll(seasonsStr);
  Season[] lastSeasons = loadAll(getSeasonsBeforeNoDir(seasonsStr));
  linkSeasons(seasons ~ lastSeasons);
  writeln("Linked seasons");
  double profitSum = 0;
  double bets = 0;
  double allBets = 0;
  foreach (season; seasons) {
    double[] profit = getProfitForSeason(season, rules, 0.01);
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
  writeln("Getting profit for season");
  double profitSum = 0;
  orderByScore(rules);
  writeln("Starting loop");
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
        writeln("Betting on game: ");
        writeln(game);
        writeln("Rule: ");
        writeln(rule);
        writeln("Profit: ");
        writeln(profit);
        writeln("BetNo: "~to!string(bets++)~"/"~to!string(games.length));
        writeln("Profit so far");
        writeln(profitSum);
        writeln("Avg profit so far");
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
