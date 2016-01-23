module season;

import std.algorithm;
import std.csv;
import std.file;
import std.stdio;
import std.string;
import std.regex;
import std.conv;

import rule;

/*
 * Coluld read the csv file like this, if we wanted a right types.
 * foreach(record; file.byLine.joiner("\n").csvReader!(Tuple!(string, string, string, string,
 * int, int , string, int , int, string, string, int, int, int, int, int, int , int, int, int,
 * int, int, int, double, double, int, double, double, double, double, double, double, double,
 * int, double, double, int, double, double, double, double, double, double, double, int , double,
 * double, double, double, double, int, double, double, double, double, double, double, int,
 * double, double, double, double, int, double, double, double, double, double)))
 */

class Season {
  string[string] features;
  string[] header;
  string[string][] games;
  Season lastSeason;
  // Cached values:
  private int seasonLength = -1;
  private string[] teams;
  private string[string][][string] teamsGames;
  private double[][DistributionId] distributions;

  this(string[string] features, string[] header, string[string][] games) {
    this.features = features;
    this.header = header;
    this.games = games;
  }

  double[] getDistribution(Parameter param) {
    int noOfGames =  param.numberOfGames;
    if (noOfGames > getSeasonLength()) {
      return null;
    }
    if (noOfGames == 0) {
      noOfGames = 1;
    } else if (noOfGames < 0) {
      noOfGames = getSeasonLength();
    }
    auto distId = new DistributionId(param.name, noOfGames);
    if (distributions[distId] is null) {
      distributions[distId] = generateDistribution(distId);
    }
    return distributions[distId];
  }

  private double[] generateDistribution(DistributionId distId) {
    double[] res;
    foreach (team; getTeams()) {
      res ~= generateTeamsDistribution(team, distId);
    }
    sort(res);
    return res;
  }

  private double[] generateTeamsDistribution(string team, DistributionId distId) {
    double[] res;
    string[string][] games = getTeamsGames(team);
      // TODO check range
    foreach (i; 0..getSeasonLength()-distId.numOfGames) {
      double sum = 0;
      // TODO check range
      foreach (j; i..i+distId.numOfGames) {
        string[string] game = games[j];
        string attribute = getTeamsAttribute(team, game, distId.name);
        sum += to!double(game[attribute]);
      }
      res ~= sum;
    }
    return res;
  }

  int getSeasonLength() {
    if (seasonLength != -1) {
      return seasonLength;
    }
    auto teams = getTeams();
    seasonLength = games.length / teams.length;
    return seasonLength;
  }

  private string[] getTeams() {
    if (teams !is null) {
      return teams;
    }
    foreach (game; games) {
      string homeTeam = game["HomeTeam"];
      string awayTeam = game["AwayTeam"];
      if (!teams.canFind(homeTeam)) {
        teams ~= homeTeam;
      }
      if (!teams.canFind(awayTeam)) {
        teams ~= awayTeam;
      }
    }
    return teams;
  }

  private string[string][] getTeamsGames(string team) {
    if (teamsGames[team] !is null) {
      return teamsGames[team];
    }
    foreach (game; games) {
      string homeTeam = game["HomeTeam"];
      string awayTeam = game["AwayTeam"];
      if (team == homeTeam || team == awayTeam) {
        teamsGames[team] ~= game;
      }
    }
    return teamsGames[team];
  }

  private class DistributionId {
    string name;
    int numOfGames;
    this(string name, int numOfGames) {
      this.name = name;
      this.numOfGames = numOfGames;
    }
  }
}

/*
 * Reads all csv files in directory, and creates a Season object
 * from each one.
 */
public Season[] loadSeasonsFromDir(string dir) {
  Season[] seasons;
  foreach(fileName; dirEntries(dir, "*.csv", SpanMode.shallow)) {
    writeln("$$$ Loading season file: "~fileName);
    auto file = File(fileName, "r");
    auto records = csvReader!(string[string])(file.byLine.joiner("\n"), null);
    string[string][] games;
    foreach(record; records) {
      games ~= record;
    }
    auto features = getSeasonsFeatures(fileName);
    auto season = new Season(features, records.header, games);
    seasons ~= season;
    file.close();
  }
  return seasons;
}

private string[string] getSeasonsFeatures(string fileName) {
  string[] header = ["sport", "country", "league", "season"];
  int i = 0;
  string[string] features;
  string fileNameNoExtension = split(fileName, ".")[0];
  fileNameNoExtension = split(fileNameNoExtension, "\\")[1];
  foreach(feature; split(fileNameNoExtension, "-")) {
    features[header[i++]] = to!string(feature);
  }
  return features;
}

/*
 * Returns wether all of the generalRules of the rule are satisfied.
 */
public bool seasonFitsTheRule(Season season, Rule rule) {
  foreach (generalRule; rule.generalRules) {
    if (!ruleApplies(generalRule, season.features[generalRule.parameter])) {
      return false;
    }
  }
  return true;
}

private bool ruleApplies(GeneralRule rule, string parameterValue) {
  if (typeid(rule) == typeid(DigitRule)) {
    DigitRule digitRule = cast(DigitRule) rule;
    if (digitRule.numericOperator == NumericOperator.lt) {
      return to!double(parameterValue) < digitRule.constant;
    } else {
      return to!double(parameterValue) >= digitRule.constant;
    }
  } else if (typeid(rule) == typeid(DiscreteRule)) {
    DiscreteRule disRule = cast(DiscreteRule) rule;
    return disRule.values.canFind(parameterValue);
  }
  return false;
}

double[] getDistribution(Season season, Parameter param) {
  if (param.numberOfGames >= 0) {
    return season.lastSeason.getDistribution(param);
  }
  double[] res;
  // TODO check range
  foreach (i; param.numberOfGames*-1-1..0) {
    Season curSeason = season;
  // TODO check range
    foreach (j; 0..i) {
      curSeason = curSeason.lastSeason;
      if (curSeason is null) {
        return null;
      }
      res ~= curSeason.getDistribution(param);
    }
  }
  return res;
}

/*
 * Retrurns right attribute name, depending od wether the passed team plays at home or away.
 */
private string getTeamsAttribute(string teamName, string[string] game, string origAtribute) {
  string homeTeam = game["HomeTeam"];
  string awayTeam = game["AwayTeam"];
  Team team = ATTRIBUTES_TEAM[origAtribute];
  if (teamName == homeTeam && team == Team.A ||
      teamName == awayTeam && team == Team.H) {
    return OTHER_TEAM_ATTRIBUTE[origAtribute];
  }
  return origAtribute;
}

const (Team[string]) ATTRIBUTES_TEAM;
const (string[string]) OTHER_TEAM_ATTRIBUTE;

static this() {
  // TODO + referee, result, reasult half time, odds
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