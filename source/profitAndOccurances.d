module profitAndOccurances;

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

  this(string line) {
    // 'A: 0.42 H: 0.01 D: -0.42 occ: 76,'
    line = line.strip();
    line = chomp(line, ",");
    // 'A: 0.42 H: 0.01 D: -0.42 occ: 76'
    auto tokens = line.split();
    // [ 'A:', '0.42', 'H:', '0.01', 'D:', '-0.42', 'occ:', '76' ]
    for (int i = 0; i < tokens.length; i += 2) {
      auto key = chomp(tokens[i], ":");
      auto value = tokens[i+1];
      if (key == "H") {
        profit[Res.H] = to!double(value);
      } else if (key == "D") {
        profit[Res.D] = to!double(value);
      } else if (key == "A") {
        profit[Res.A] = to!double(value);
      } else if (key == "occ") {
        occurances = to!int(value);
      }
    }
    profit[Res.H] *= occurances;
    profit[Res.D] *= occurances;
    profit[Res.A] *= occurances;
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
    poc.profit[Res.H] += profitIn;
    poc.profit[Res.D] -= 1;
    poc.profit[Res.A] -= 1;
  } else if (res == Res.D) {
    poc.profit[Res.H] -= 1;
    poc.profit[Res.D] += profitIn;
    poc.profit[Res.A] -= 1;
  } else if (res == Res.A) {
    poc.profit[Res.H] -= 1;
    poc.profit[Res.D] -= 1;
    poc.profit[Res.A] += profitIn;
  }
}

/*
 * Returns average profit of a passed result.
 */
public double getAvgProfit(ProfitAndOccurances poc, Res res) {
  return poc.profit[res] / poc.occurances;
}

public Res getBestResult(ProfitAndOccurances poc) {
  Res bestResult;
  double max = -1000000;
  foreach (res; [Res.H, Res.D, Res.A]) {
    if (poc.profit[res] > max) {
      max = poc.profit[res];
      bestResult = res;
    }
  }
  return bestResult;
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


