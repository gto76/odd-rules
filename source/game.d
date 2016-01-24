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

/*
 * Return value -1 means that parameter doesn't exist, so the rule does not apply.
 * If parameter is null, it returns 0, so that a team rule without a parameter on the right side
 * of expresion can be defined.
 */
private double[] getParametersBounds(Parameter param, string[string] game, Season season) {
  if (param is null) {
    return [0, 0];
  }
  writeln("$$$ season "~to!string(season.features));
  writeln("$$$ param "~to!string(param));
  double[] distribution = getDistribution(season, param);
  writeln("$$$ distribution len "~to!string(distribution.length));
  double val = to!double(game[param.name]);
  writeln("$$$ val "~to!string(val));
  int[] absBounds = getAbsoluteBounds(distribution, val);
  writeln("$$$ min abs bound "~to!string(absBounds[0]));
  writeln("$$$ max abs bound "~to!string(absBounds[1]));
  writeln();
  return [cast(double) absBounds[0] / distribution.length,
          cast(double) absBounds[1] / distribution.length];
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






































