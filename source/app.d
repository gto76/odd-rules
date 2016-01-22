import std.algorithm;
import std.array;
import std.conv;
import std.format;
import std.range;
import std.regex;
import std.stdio;
import std.string;
import std.typecons;

import game;
import profit;
import rule;
import season;

//////////
// MAIN //
//////////

void main(string[] args) {
  Rule rule = new Rule(
      [new DiscreteRule("country", ["germany", "england"])],
      [new TeamRule(new ParameterForLastGames("corners", Team.A,  0), NumericOperator.lt, null, 0.5),
       new TeamRule(new ParameterForLastGames("fouls", Team.H, 1), NumericOperator.mt, null, 0.5)],
      [LogicOperator.AND]);
  Season[] seasons = loadSeasonsFromDir("csv");
  setAverages(seasons);
  writeln("Analizing rule: \n"~to!string(rule));
  ProfitAndOccurances profitAndOccurances = getProfitAndOccurances(seasons, rule);
  writeln(profitAndOccurances);
  writeln("The End");
}

private void setAverages(Season[] seasons) {
  foreach (season; seasons) {
    auto seasonBefore = getSeasonBefore(seasons, season);
    if (seasonBefore is null) {
      continue;
    }
    season.averages = getAverages(seasonBefore);
  }
}

private Season getSeasonBefore(Season[] seasons, Season seasonThis) {
  string[string] fThis = seasonThis.features;
  foreach (seasonOther; seasons) {
    string[string] fOther = seasonOther.features;
    if (sameLeague(fThis, fOther)) {
      if (to!int(fThis["season"]) == to!int(fOther["season"]) - 1) {
        return seasonOther;
      }
    }
  }
  return null;
}

private bool sameLeague(string[string] fThis, string[string] fOther) {
  return fThis["sport"] == fOther["sport"] &&
         fThis["country"] == fOther["country"] &&
         fThis["league"] == fOther["league"];
}

private double[string] getAverages(Season season) {
  double[string] averages;
  foreach (atribute; season.header) {
    averages[atribute] = getAverage(season, atribute);
  }
  return averages;
}

private double getAverage(Season season, string atribute) {
  double sum = 0;
  foreach (game; season.games) {
    string val = game[atribute];
    try {
      sum += to!double(val);
    } catch (ConvException e) {
      return 0;
    }
  }
  return sum / season.games.length;
}