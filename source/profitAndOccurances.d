module profit;

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
import game;
import conf;

///////////////////////////
// PROFIT AND OCCURANCES //
///////////////////////////

class ProfitAndOccurances {
  double[Res] profit;
  int occurances = 0;

  this() {
    profit[Res.H] = 0;
    profit[Res.D] = 0;
    profit[Res.A] = 0;
  }

  /*
   * Returns string with average profit for every result and number of occurances.
   * Profits are ordered from the bigest to smallest.
   */
  override public string toString() {
    ProfitPerResult[] profits = [ new ProfitPerResult(Res.H, getAvgProfit(this, Res.H)),
                                  new ProfitPerResult(Res.D, getAvgProfit(this, Res.D)),
                                  new ProfitPerResult(Res.A, getAvgProfit(this, Res.A))];
    sort(profits);
    reverse(profits);
    auto w = appender!string();
    foreach (profit; profits) {
      w.put(to!string(profit));
      w.put(" ");
    }
    w.put("occ: ");
    w.put(to!string(occurances));
    return w.data;
  }

  /*
   * Helper class for toString method.
   */
  private class ProfitPerResult {
    Res result;
    double profit;
    this(Res result, double profit) {
      this.result = result;
      this.profit = profit;
    }
    override bool opEquals(Object o) {
      if (o is null) {
        return false;
      }
      if (typeid(o) != typeid(ProfitPerResult)) {
        return false;
      }
      ProfitPerResult other = cast(ProfitPerResult) o;
      return other.profit == this.profit;
    }
    override int opCmp(Object o) {
      ProfitPerResult other = cast(ProfitPerResult) o;
      if (this.profit < other.profit) {
        return -1;
      }
      if (this.profit > other.profit) {
        return 1;
      }
      return 0;
    }
    override string toString() {
      auto w = appender!string();
      auto spec = singleSpec("%.4f");
      w.put(to!string(result));
      w.put(": ");
      formatElement(w, profit, spec);
      return w.data;
    }
  }
}

///////////////
// FUNCTIONS //
///////////////

/*
 * Updates profit for all outcomes.
 */
public void setProfit(ProfitAndOccurances poc, Res res, double profitIn) {
  if (res == Res.H) {
    poc.profit[Res.H] += profitIn-1;
    poc.profit[Res.D] -= 1;
    poc.profit[Res.A] -= 1;
  } else if (res == Res.D) {
    poc.profit[Res.H] -= 1;
    poc.profit[Res.D] += profitIn-1;
    poc.profit[Res.A] -= 1;
  } else if (res == Res.A) {
    poc.profit[Res.H] -= 1;
    poc.profit[Res.D] -= 1;
    poc.profit[Res.A] += profitIn-1;
  }
}

/*
 * Returns average profit of a passed result.
 */
public double getAvgProfit(ProfitAndOccurances poc, Res res) {
  return poc.profit[res] / poc.occurances;
}

/*
 * Finds which result has the highest average profit, and returns it.
 */
public double getMaxProfit(ProfitAndOccurances poc) {
  double max = -1000000;
  foreach (res; [Res.H, Res.D, Res.A]) {
    double val = getAvgProfit(poc, res);
    if (val > max) {
      max = val;
    }
  }
  return max;
}


