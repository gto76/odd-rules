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
