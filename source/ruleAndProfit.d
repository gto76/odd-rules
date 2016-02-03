module ruleAndProfit;

import std.conv;

import rule;
import profitAndOccurances;

/////////////////////
// RULE AND PROFIT //
/////////////////////

class RuleAndProfit {
  Rule rule;
  ProfitAndOccurances pao;
  this (Rule rule, ProfitAndOccurances pao) {
    this.rule = rule;
    this.pao = pao;
  }
//  override bool opEquals(Object o) {
//    if (o is null) {
//      return false;
//    }
//    if (typeid(o) != typeid(RuleAndProfit)) {
//      return false;
//    }
//    RuleAndProfit other = cast(RuleAndProfit) o;
//    return other.pao.getMaxProfit() == this.pao.getMaxProfit() &&
//           other.pao.occuran
//  }
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