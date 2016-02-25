module game;

import core.exception;
import std.algorithm;
import std.array;
import std.conv;
import std.datetime;
import std.format;
import std.math;
import std.range;
import std.regex;
import std.stdio;
import std.string;
import std.typecons;

import profitAndOccurances;
import rule;
import season;
import conf;

//////////
// GAME //
//////////

class Game {
  string[string] sAttrs;
  double[string] dAttrs;
  bool dateSet = false;
  DateTime dateTime;

  this(string[string] attrs) {
    foreach (key, value; attrs) {
      if (STRING_ATTRIBUTES.canFind(key)) {
        sAttrs[key] = value;
      } else {
        if (value == "") {
          continue;
        }
        dAttrs[key] = to!double(value);
      }
    }
  }

  public Res getResult() {
    string sResult = sAttrs["FTR"];
    if (sResult == "") {
      throw new Exception("Result not present in game "~to!string(sAttrs));
    }
    return to!Res(sResult);
  }

  /*
   * Returns profit of winning option.
   */
  public double getProfit() {
    Res result = getResult();
    string columnBase = "";
    if (USE_AVERAGE_ODDS) {
      columnBase = BETBRAIN_AVERAGE;
    } else {
      columnBase = BETBRAIN_MAX;
    }
    string column = columnBase ~ to!string(result);
    if (column !in dAttrs) {
      // No Betbrain attribute.
      return double.nan;
    }
    return dAttrs[column];
  }

  // Returns null if doesn't exist.
  public DateTime getDateTime() {
    if (dateSet) {
      return dateTime;
    }
    string sResult = sAttrs["Date"];
    if (sAttrs["Date"] == "" || sAttrs["Time"] == "") {
      writeln("Date or Time not present in game, returning null");
    }
    string date = sAttrs["Date"];
    // '27/02/16'
    string[] dateTokens = date.split('/');
    string year = dateTokens[2];
    string month = dateTokens[1];
    string day = dateTokens[0];
    string time = sAttrs["Time"];
    // '12:45'
    string[] timeTokens = time.split(':');
    string hour = timeTokens[0];
    string minute = timeTokens[1];
    dateTime = DateTime(to!int(year), to!int(month), to!int(day), to!int(hour), to!int(minute));
    dateSet = true;
    return dateTime;
  }
}

///////////////
// FUNCTIONS //
///////////////

/*
 * Returns profit and occurances for all games of passed seasons, that apply to
 * the rule.
 */
public ProfitAndOccurances getProfitAndOccurances(Season[] seasons, Rule rule) {
  auto pao = new ProfitAndOccurances();
  foreach (season; seasons) {
    if (season.lastSeason is null) {
      continue;
    }
    if (!seasonFitsTheRule(season, rule)) {
      continue;
    }
    foreach (game; season.games) {
      if (ruleAplies(game, season, rule)) { // Shouldn't last season be passed here!!! TODO
        Res res;
        try {
          res = game.getResult();
        } catch (Exception e) {
          continue;
        }
        double profit = game.getProfit();
        if (isNaN(profit)) {
          continue;
        }
        pao.occurances++;
        pao.setProfit(res, profit);
      }
    }
  }
  return pao;
}

public bool ruleAplies(Game game, Season season, Rule rule) {
  bool result = false;
  try {
    foreach (val; zip(LogicOperator.OR ~ rule.logicOperators, rule.teamRules)) {
      auto operator = val[0];
      auto teamRule = val[1];
      bool teamRuleEval = evalTeamRule(teamRule, game, season);
      if (operator == LogicOperator.OR) {
        result = result || teamRuleEval;
      } else if (operator == LogicOperator.AND) {
        if (!teamRuleEval) {
          return false;
        }
      }
    }
  } catch(RangeError e) {
    writeln("$$$ Range error");
    writeln("Game "~to!string(game));
    writeln("Season "~to!string(season));
    writeln("Rule "~to!string(rule));
  }
  return result;
}

private bool evalTeamRule(TeamRule teamRule, Game game, Season season) {
  double[] parameterBounds = getParametersBounds(teamRule.parameter, game, season);
  if (parameterBounds is null) {
    return false;
  }
  double[] otherParameterBounds = getParametersBounds(teamRule.otherParameter, game, season);
  if (otherParameterBounds is null) {
    return false;
  }
  if (teamRule.numericOperator == NumericOperator.LT) {
    return parameterBounds[0] < otherParameterBounds[1] + teamRule.constant;
  } else {
    return parameterBounds[1] >= otherParameterBounds[0] + teamRule.constant;
  }
}

/*
 * Return value null means that parameter doesn't exist, so the rule does not apply.
 * If parameter is null, it returns 0, so that a team rule without a parameter on the right side
 * of expresion can be defined.
 */
private double[] getParametersBounds(Parameter param, Game game, Season season) {
  if (param is null) {
    return [0, 0]; // suspicious todo
  }
  double[] distribution = getSeasonsDistribution(season, param);
  if (distribution is null) {
    return null;
  }
  double val = getValue(param, game, season);
  if (isNaN(val)) {
    return null;
  }
  int[] absBounds = getAbsoluteBounds(distribution, val);
  double[] relBounds = [cast(double) absBounds[0] / distribution.length,
                        cast(double) absBounds[1] / distribution.length];
  if (DEBUG) {
    printData(season, param, distribution, val, absBounds, relBounds);
  }
  return relBounds;
}

// TODO for whole seasons (param)
private double getValue(Parameter param, Game game, Season season) {
  Team team = ATTRIBUTES_TEAM[param.name];
  string teamName = getTeamName(game, team);
  auto position = countUntil(season.games, game);
  int counter = param.numberOfGames;
  if (param.numberOfGames == 0) {
    counter = 1;
  }
  double sum = 0;
  // TODO for current game
  foreach_reverse (i; 0 .. position) {
    Game pastGame = season.games[i];
    if (teamInGame(pastGame, teamName)) {
      string attribute = getTeamsAttribute(teamName, pastGame, param.name);
      if (attribute !in pastGame.dAttrs) {
        return double.nan;
      }
      sum += to!double(pastGame.dAttrs[attribute]);
      if (--counter == 0) {
        break;
      }
    }
  }
  bool notEnoughGames = counter != 0;
  if (notEnoughGames) {
    return double.nan;
  }
  return sum;
}

private bool teamInGame(Game game, string teamName) {
  return game.sAttrs["HomeTeam"] == teamName || game.sAttrs["AwayTeam"] == teamName;
}

private string getTeamName(Game game, Team team) {
  if (team == Team.H) {
    return game.sAttrs["HomeTeam"];
  } else {
    return game.sAttrs["AwayTeam"];
  }
}

private void printData(Season season, Parameter param, double[] distribution, double val,
               int[] absBounds, double[] relBounds) {
  writeln("$$$ season "~to!string(season.features));
  writeln("$$$ param "~to!string(param));
  writeln("$$$ distribution len "~to!string(distribution.length));
  writeln("$$$ val "~to!string(val));
  writeln("$$$ abs bounds "~to!string(absBounds));
  write("$$$ rel bounds [ ");
  foreach (bound; relBounds) {
    writef("%.2f ", bound);
  }
  writeln("]");
  writeln();
}

private int[] getAbsoluteBounds(double[] distribution, double val) {
  int min = -1;
  int max = -1;
  for (int i = 0; i < distribution.length; i++) {
    double curVal = distribution[i];
    if (curVal > val) {
      if (min == -1) {
        min = i;
      }
      max = i;
      break;
    }
    if (curVal == val && min == -1) {
      min = i;
    }
  }
  return [min, max];
}

























