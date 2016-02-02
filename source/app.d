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
import conf;

//////////
// MAIN //
//////////

void main(string[] args) {

  Season[] seasons = loadSeasonsFromDir("csv");
  linkSeasons(seasons);

  RuleAndProfit[] bestResults;

  int counter = 1;
  foreach (i; 1 .. NUM_OF_RUNS) {
    write("#");
    stdout.flush();
    if (counter++ % 80 == 0) {
      writeln();
    }
    Rule rule = getRandomRule(seasons, ATTRIBUTES, WIDEST_WINDOW);
    ProfitAndOccurances profitAndOccurances = getProfitAndOccurances(seasons, rule);
    if (profitAndOccurances is null) {
      continue;
    }
    if (profitAndOccurances.occurances < OCCURANCE_TRESHOLD) {
      continue;
    }
    double profit = profitAndOccurances.getMaxProfit();
//    if (profit < 0.2) {
//      continue;
//    }
    RuleAndProfit rap = new RuleAndProfit(rule, profitAndOccurances);
    bestResults ~= rap;
    sort(bestResults);
    writeln();
    writeln(to!string(bestResults));
    writeln();
    counter = 1;
//    break;
  }
  writeln("\nThe End");
}

class RuleAndProfit {
  Rule rule;
  ProfitAndOccurances pao;
  this (Rule rule, ProfitAndOccurances pao) {
    this.rule = rule;
    this.pao = pao;
  }
  override bool opEquals(Object o) {
    if (o is null) {
      return false;
    }
    if (typeid(o) != typeid(RuleAndProfit)) {
      return false;
    }
    RuleAndProfit other = cast(RuleAndProfit) o;
    return other.pao.getMaxProfit() == this.pao.getMaxProfit();
  }
  override int opCmp(Object o) {
    RuleAndProfit other = cast(RuleAndProfit) o;
    if (this.pao.getMaxProfit() < other.pao.getMaxProfit()) {
      return -1;
    }
    if (this.pao.getMaxProfit() > other.pao.getMaxProfit()) {
      return 1;
    }
    return 0;
  }
  override string toString() {
    return "\n" ~ to!string(rule) ~ "\n" ~ to!string(pao);
  }
}

// Team rule needs to be updated. In case of specifiying for how many seasons in past we want to
// go.
// 0..2 = [0, 1]
//  Rule rule = new Rule(
//      [new DiscreteRule("country", ["germany", "england"])],
//      [new TeamRule(new Parameter("AC", /+Team.A,+/ 3), NumericOperator.lt, null, 0.7), // corners
//       new TeamRule(new Parameter("HF", /+Team.H,+/ 5), NumericOperator.mt, null, 0.3)], // fouls
//      [LogicOperator.AND]);