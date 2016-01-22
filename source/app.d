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
import averages;

//////////
// MAIN //
//////////

void main(string[] args) {
  // Team rule needs to be updated. In case of specifiying for how many seasons in past we want to go.
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
