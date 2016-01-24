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
  // Team rule needs to be updated. In case of specifiying for how many seasons in past we want to
  // go.
  // 0..2 = [0, 1]
  Rule rule = new Rule(
      [new DiscreteRule("country", ["germany", "england"])],
      [new TeamRule(new Parameter("AC", Team.A, 3), NumericOperator.lt, null, 0.7), // corners
       new TeamRule(new Parameter("HF", Team.H, 5), NumericOperator.mt, null, 0.3)], // fouls
      [LogicOperator.AND]);
  Season[] seasons = loadSeasonsFromDir("csv");
  linkSeasons(seasons);
  ProfitAndOccurances profitAndOccurances = getProfitAndOccurances(seasons, rule);
  writeln("Rule: \n"~to!string(rule));
  writeln(profitAndOccurances);
  writeln("The End");
}
