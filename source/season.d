module season;

import std.array;
import std.c.stdlib;
import std.algorithm;
import std.csv;
import std.file;
import std.stdio;
import std.string;
import std.regex;
import std.conv;

import game;
import rule;

string[] SEASON_FEATURES = ["sport", "country", "league", "season"];
bool USE_DISTRIBUTIONS_CACHE = true;

class Season {
  string[string] features;
  string[] header;
  Game[] games;
  Season lastSeason;
  // Cached values:
  private int seasonLength = -1;
  private string[] teams;
  private Game[][string] teamsGames;
  private double[][DistributionId] distributions;

  this(string[string] features, string[] header, Game[] games) {
    this.features = features;
    this.header = header;
    this.games = games;
  }

  public double[] getDistribution(Parameter param) {
    int noOfGames = param.numberOfGames;
    if (noOfGames > getSeasonLength()) {
      return null;
    }
    if (noOfGames == 0) {
      noOfGames = 1;
    } else if (noOfGames < 0) {
      noOfGames = getSeasonLength();
    }
    auto distId = new DistributionId(param.name, noOfGames);
    if (!USE_DISTRIBUTIONS_CACHE) {
      return generateDistribution(distId);
    }
    if (distId !in distributions) {
      distributions[distId] = generateDistribution(distId);
    }
    return distributions[distId];
  }

  private double[] generateDistribution(DistributionId distId) {
    auto res = appender!(double[])();
    foreach (team; getTeams()) {
       double[] teamsDistribution = generateTeamsDistribution(team, distId);
       if (teamsDistribution == null) {
         return null;
       }
       res.put(teamsDistribution);
    }
    double[] resArray = res.data;
    sort(resArray);
    return resArray;
  }

  private double[] generateTeamsDistribution(string team, DistributionId distId) {
    auto res = appender!(double[])();
    Game[] teamGames = getTeamsGames(team);
    // TODO check range
    foreach (i; 0 .. teamGames.length - distId.numOfGames-1) {
      double sum = 0;
      // TODO check range
      foreach (j; i .. i + distId.numOfGames) {
        if (j >= teamGames.length) {
          writeln("$$$ core.exception.RangeError team "~team);
          writeln("$$$ j "~to!string(j)~" teamGames.length "~to!string(teamGames.length));
          exit(1);
        }
        Game game = teamGames[j];
        string attribute = getTeamsAttribute(team, game, distId.name);
        if (attribute !in game.dAttrs) {
          return null;
        }
        sum += game.dAttrs[attribute];
      }
      res.put(sum);
    }
    return res.data;
  }

  private int getSeasonLength() {
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
      string homeTeam = game.sAttrs["HomeTeam"];
      string awayTeam = game.sAttrs["AwayTeam"];
      if (!teams.canFind(homeTeam)) {
        teams ~= homeTeam;
      }
      if (!teams.canFind(awayTeam)) {
        teams ~= awayTeam;
      }
    }
    return teams;
  }

  private Game[] getTeamsGames(string team) {
    if (team in teamsGames) {
      return teamsGames[team];
    }
    foreach (game; games) {
      string homeTeam = game.sAttrs["HomeTeam"];
      string awayTeam = game.sAttrs["AwayTeam"];
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
    override size_t toHash() {
      return name.length + numOfGames*20;
    }
    override bool opEquals(Object o) {
      if (o is null) {
        return false;
      }
      if (typeid(o) != typeid(DistributionId)) {
        return false;
      }
      DistributionId other = cast(DistributionId) o;
      return other.name == this.name
             && other.numOfGames == this.numOfGames;
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
    Game[] games;
    foreach(record; records) {
      games ~= new Game(record);
    }
    auto features = getSeasonsFeatures(fileName);
    auto season = new Season(features, records.header, games);
    seasons ~= season;
    file.close();
  }
  return seasons;
}

private string[string] getSeasonsFeatures(string fileName) {
  int i = 0;
  string[string] features;
  string fileNameNoExtension = split(fileName, ".")[0];
  fileNameNoExtension = split(fileNameNoExtension, "\\")[1];
  foreach(feature; split(fileNameNoExtension, "-")) {
    features[SEASON_FEATURES[i++]] = to!string(feature);
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
    if (digitRule.numericOperator == NumericOperator.LT) {
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
  foreach_reverse (i; 1 .. -param.numberOfGames+1) {
    Season curSeason = season;
    // TODO check range
    foreach (j; 0 .. i) {
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
public string getTeamsAttribute(string teamName, Game game, string origAtribute) {
  string homeTeam = game.sAttrs["HomeTeam"];
  string awayTeam = game.sAttrs["AwayTeam"];
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