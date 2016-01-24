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

int NUM_OF_RUNS = 100;
string[] ATTRIBUTES = ["FTHG", "FTAG", "HTHG", "HTAG", "HS", "AS", "HST", "AST", "HF", "AF", "HC",
                       "AC", "HY", "AY", "HR", "AR"];
int WIDEST_WINDOW = 10;
int OCCURANCE_TRESHOLD = 50;

void main(string[] args) {
  // Team rule needs to be updated. In case of specifiying for how many seasons in past we want to
  // go.
  // 0..2 = [0, 1]
//  Rule rule = new Rule(
//      [new DiscreteRule("country", ["germany", "england"])],
//      [new TeamRule(new Parameter("AC", /+Team.A,+/ 3), NumericOperator.lt, null, 0.7), // corners
//       new TeamRule(new Parameter("HF", /+Team.H,+/ 5), NumericOperator.mt, null, 0.3)], // fouls
//      [LogicOperator.AND]);
  Season[] seasons = loadSeasonsFromDir("csv");
  linkSeasons(seasons);

  foreach (i; 1..NUM_OF_RUNS) {
    write("#");
    stdout.flush();
    if (i % 80 == 0) {
      writeln();
    }
    Rule rule = getRandomRule(seasons, ATTRIBUTES, WIDEST_WINDOW);
    ProfitAndOccurances profitAndOccurances = getProfitAndOccurances(seasons, rule);
//    if (profitAndOccurances.occurances < OCCURANCE_TRESHOLD) {
//      continue;
//    }
    double profit = profitAndOccurances.getMaxProfit();
    if (profit < 0.2) {
      continue;
    }
    writeln("\nRule: \n"~to!string(rule));
    writeln(profitAndOccurances);
  }

  writeln("\nThe End");
}
