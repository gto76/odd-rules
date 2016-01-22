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
    if (season.averages is null) {
      continue;
    }
    if (!seasonFitsTheRule(season, rule)) {
      continue;
    }
    foreach (game; season.games) {
      if (ruleAplies(game, season.games, rule)) {
        pao.occurances++;
        Res res = getResult(game);
        double profit = getProfit(game);
        setProfit(pao, res, profit);
      }
    }
  }
  return pao;
}

private bool ruleAplies(string[string] game, string[string][] games, Rule rule) {
  bool result = false;
  foreach (val; zip(LogicOperator.OR ~ rule.logicOperators, rule.teamRules)) {
    auto operator = val[0];
    auto teamRule = val[1];
    bool teamRuleEval = evalTeamRule(teamRule, game, games);
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

private bool evalTeamRule(TeamRule teamRule, string[string] game, string[string][] games) {
// TODO
//  if (typeid(teamRule) == typeid(TeamRuleWithConstant)) {
//  }
  return true;
}

public Res getResult(string[string] game) {
  string sResult = game["FTR"];
  return to!Res(sResult);
}






































