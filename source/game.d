module game;

import std.algorithm;
import std.array;
import std.conv;
import std.format;
import std.range;
import std.regex;
import std.stdio;
import std.string;
import std.typecons;

import profit;
import rule;
import season;

public static const bool USE_AVERAGE_ODDS = true;
public static const string BETBRAIN_AVERAGE = "BbAv";
public static const string BETBRAIN_MAX = "BbMx";

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
      if (ruleAplies(game, season, rule)) {
        pao.occurances++;
        Res res = getResult(game);
        double profit = getProfit(game);
        setProfit(pao, res, profit);
      }
    }
  }
  return pao;
}

private bool ruleAplies(string[string] game, Season season, Rule rule) {
  bool result = false;
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
  return result;
}

private bool evalTeamRule(TeamRule teamRule, string[string] game, Season season) {
  double[] parameterBounds = getParametersBounds(teamRule.parameter, game, season);
  if (parameterBounds[0] == -1) {
    return false;
  }
  double[] otherParameterBounds = getParametersBounds(teamRule.otherParameter, game, season);
  if (otherParameterBounds[0] == -1) {
    return false;
  }
  if (teamRule.numericOperator == NumericOperator.lt) {
    return parameterBounds[0] < otherParameterBounds[1] + teamRule.constant;
  } else {
    return parameterBounds[1] >= otherParameterBounds[0] + teamRule.constant;
  }
}

bool DEBUG = true;

/*
 * Return value -1 means that parameter doesn't exist, so the rule does not apply.
 * If parameter is null, it returns 0, so that a team rule without a parameter on the right side
 * of expresion can be defined.
 */
private double[] getParametersBounds(Parameter param, string[string] game, Season season) {
  if (param is null) {
    return [0, 0];
  }
  double[] distribution = getDistribution(season, param);
  double val = getValue(param, game, season); //to!double(game[param.name]);
  if (val == double.nan) {
    return [-1];
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
private double getValue(Parameter param, string[string] game, Season season) {
  string teamName = getTeamName(game, param.team);
  int position = countUntil(season.games, game);
  int counter = param.numberOfGames;
  if (param.numberOfGames == 0) {
    counter = 1;
  }
  double sum = 0;
  // TODO for current game
  foreach_reverse (i; 0 .. position+1) {
    string[string] pastGame = season.games[i];
    if (teamInGame(pastGame, teamName)) {
      string attribute = getTeamsAttribute(teamName, pastGame, param.name);
      sum += to!double(pastGame[attribute]);
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

private bool teamInGame(string[string] game, string teamName) {
  return game["HomeTeam"] == teamName || game["AwayTeam"] == teamName;
}

private string getTeamName(string[string] game, Team team) {
  if (team == Team.H) {
    return game["HomeTeam"];
  } else {
    return game["AwayTeam"];
  }
}

private void printData(Season season, Parameter param, double[] distribution, double val,
               int[] absBounds, double[] relBounds) {
  writeln("$$$ season "~to!string(season.features));
  writeln("$$$ param "~to!string(param));
  writeln("$$$ distribution len "~to!string(distribution.length));
  writeln("$$$ val "~to!string(val));
  writeln("$$$ abs bounds "~to!string(absBounds));
  writeln("$$$ rel bounds "~to!string(relBounds));
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

public Res getResult(string[string] game) {
  string sResult = game["FTR"];
  return to!Res(sResult);
}






































