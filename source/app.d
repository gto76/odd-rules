import std.algorithm;
import std.array;
import std.conv;
import std.format;
import std.range;
import std.regex;
import std.stdio;
import std.string;
import std.typecons;

import rule;
import season;

public static const bool USE_AVERAGE_ODDS = true;
public static const string BETBRAIN_AVERAGE = "BbAv";
public static const string BETBRAIN_MAX = "BbMx";

class ProfitAndOccurances {
  double[Res] profit;
  int occurances = 0;
  this() {
    profit[Res.H] = 0;
    profit[Res.D] = 0;
    profit[Res.A] = 0;
  }
  public double getAvgProfit(Res res) {
    return profit[res] / occurances;
  }
  override public string toString() {
    auto w = appender!string();
    auto spec = singleSpec("%.2f");
    w.put("H: ");
    append(w, spec, Res.H);
    w.put(" D: ");
    append(w, spec, Res.D);
    w.put(" A: ");
    append(w, spec, Res.A);
    w.put(" occ: ");
    w.put(to!string(occurances));
//    return "H: " ~append(Res.H) ~ " D: " ~ to!string(getAvgProfit(Res.D))
//           ~ " A: " ~ to!string(getAvgProfit(Res.A)) ~ " occ: " ~ to!string(occurances);
    return w.data;
  }
  private void append(Appender!string w, FormatSpec!char spec, Res res) {
    formatElement(w, getAvgProfit(res), spec);
  }
}

//////////
// MAIN //
//////////

void main(string[] args) {
  // todo season in for of: before current.
  Rule rule = new Rule([new DiscreteRule("country", ["germany", "england"])],
                       [new TeamRuleWithConstant(new ParameterForLastGames("corners", Team.A,  0), NumericOperator.lt, 0.5),
                        new TeamRuleWithConstant(new ParameterForLastGames("fouls", Team.H, 1), NumericOperator.mt, 0.5)],
                       [LogicOperator.AND]);
  //foreach(record; file.byLine.joiner("\n").csvReader!(Tuple!(string, string, string, string, int, int , string, int , int, string, string, int, int, int, int, int, int , int, int, int, int, int, int, double, double, int, double, double, double, double, double, double, double, int, double, double, int, double, double, double, double, double, double, double, int , double, double, double, double, double, int, double, double, double, double, double, double, int, double, double, double, double, int, double, double, double, double, double)))
  Season[] seasons = loadSeasonsFromDir("csv");
  writeln("Analizing rule: \n"~to!string(rule));
  ProfitAndOccurances profitAndOccurances = getProfitAndOccurances(seasons, rule);
  writeln(profitAndOccurances);
  writeln("The End");
}

private ProfitAndOccurances getProfitAndOccurances(Season[] seasons, Rule rule) {
  auto pao = new ProfitAndOccurances();
  foreach (season; seasons) {
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

private void setProfit(ProfitAndOccurances pao, Res res, double profit) {
  if (res == Res.H) {
    pao.profit[Res.H] += profit-1;
    pao.profit[Res.D] -= 1;
    pao.profit[Res.A] -= 1;
  } else if (res == Res.D) {
    pao.profit[Res.H] -= 1;
    pao.profit[Res.D] += profit-1;
    pao.profit[Res.A] -= 1;
  } else if (res == Res.A) {
    pao.profit[Res.H] -= 1;
    pao.profit[Res.D] -= 1;
    pao.profit[Res.A] += profit-1;
  }
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

private Res getResult(string[string] game) {
  string sResult = game["FTR"];
  return to!Res(sResult);
}

private double getProfit(string[string] game) {
  Res result = getResult(game);
  string columnBase = "";
  if (USE_AVERAGE_ODDS) {
    columnBase = BETBRAIN_AVERAGE;
  } else {
    columnBase = BETBRAIN_MAX;
  }
  string column = columnBase ~ to!string(result);
  string sProfit = game[column];
  return to!double(sProfit);
}


