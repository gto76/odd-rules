module season;

import std.array;
//import std.c.stdlib;
import core.stdc.stdlib;
import std.algorithm;
import std.csv;
import std.file;
import std.stdio;
import std.string;
import std.regex;
import std.conv;

import game;
import rule;
import conf;

////////////
// SEASON //
////////////

class Season {
  string[string] features;
  string[] header;
  Game[] games;
  Season lastSeason;
  // Cached values:
  private size_t seasonLength = -1;
//  private ulong seasonLength = -1;
  private string[] teams;
  private Game[][string] teamsGames;
  private double[][DistributionId] distributions;

  this(string[string] features, string[] header, Game[] games) {
    this.features = features;
    this.header = header;
    this.games = games;
  }

  public double[] getDistribution(Parameter param) {
    size_t noOfGames = param.numberOfGames;
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

  private size_t getSeasonLength() {
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
    size_t numOfGames;

    this(string name, size_t numOfGames) {
      this.name = name;
      this.numOfGames = numOfGames;
    }

    override size_t toHash() {
      return name.length + to!size_t(numOfGames*20);
    }

    // This has no purpouse other than gcc throws an error if it is not present.
    override int opCmp(Object o) { 
      DistributionId other = cast(DistributionId) o;
      if (other.numOfGames < this.numOfGames) {
        return -1;
      } else {
        return 1;
      }
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

///////////////
// FUNCTIONS //
///////////////

/*
 * Reads all csv files in directory, and creates a Season object
 * from each one.
 */
public Season[] loadSeasonsFromDir(string dir) {
  Season[] seasons;
  foreach(fileName; dirEntries(dir, "*.csv", SpanMode.shallow)) {
    writeln("$$$ Loading season file: "~fileName);
    seasons ~= loadSeason(fileName);
  }
  return seasons;
}

Season[] loadAll(string[] seasonsStr, string dir) {
  Season[] res;
  foreach (seasonStr; seasonsStr) {
    string filename = to!string(dir~"/"~seasonStr~".csv");
    if (!exists(filename)) {
      writeln("### Season file does not exist. " ~ filename);
      continue;
    }
//    writeln("### Loading season from file. " ~ filename);
    stdout.flush();
    res ~= loadSeason(filename);
  }
  return res;
}

public Season loadSeason(string fileName) {
  auto file = File(fileName, "r");
  auto records = csvReader!(string[string])(file.byLine.joiner("\n"), null);
  Game[] games;
//  writeln(fileName);
  foreach(record; records) {
//    write(record["WHH"]~',');
    games ~= new Game(record);
  }
//  writeln();
  auto features = getSeasonsFeatures(fileName);
  auto season = new Season(features, records.header, games);
  file.close();
  return season;
}

private string[string] getSeasonsFeatures(string fileName) {
  int i = 0;
  string[string] features;
  string fileNameNoExtension = split(fileName, ".")[0];
//  writeln("file "~fileNameNoExtension);
  fileNameNoExtension = split(fileNameNoExtension, "/")[1];
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

double[] getSeasonsDistribution(Season season, Parameter param) {
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

/*
 * Sets lastSeason for all seasons.
 */
public void linkSeasons(Season[] seasons) {
  foreach (season; seasons) {
    auto lastSeason = getSeasonBefore(seasons, season);
    if (lastSeason is null) {
      continue;
    }
    season.lastSeason = lastSeason;
  }
}

private Season getSeasonBefore(Season[] seasons, Season seasonThis) {
//  writeln("Getting season before");
  string[string] fThis = seasonThis.features;
  foreach (seasonOther; seasons) {
    string[string] fOther = seasonOther.features;
    if (sameLeague(fThis, fOther)) {
//      writeln("same league");
      if (to!int(fThis["season"]) == to!int(fOther["season"]) + 1) { // Before it was wrongly -1 !!!, so last season was actually next one!!!
//        writeln("found season");
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
