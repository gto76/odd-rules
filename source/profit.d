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
   * Updates profit for all outcomes.
   */
  public void setProfit(Res res, double profitIn) {
    if (res == Res.H) {
      profit[Res.H] += profitIn-1;
      profit[Res.D] -= 1;
      profit[Res.A] -= 1;
    } else if (res == Res.D) {
      profit[Res.H] -= 1;
      profit[Res.D] += profitIn-1;
      profit[Res.A] -= 1;
    } else if (res == Res.A) {
      profit[Res.H] -= 1;
      profit[Res.D] -= 1;
      profit[Res.A] += profitIn-1;
    }
  }

  public double getAvgProfit(Res res) {
    return profit[res] / occurances;
  }

  public double getMaxProfit() {
    double max = -1000000;
    foreach (res; [Res.H, Res.D, Res.A]) {
      double val = getAvgProfit(res);
      if (val > max) {
        max = val;
      }
    }
    return max;
  }

  private void append(Appender!string w, FormatSpec!char spec, Res res) {
    formatElement(w, getAvgProfit(res), spec);
  }

  override public string toString() {
    ProfitPerResult[] profits = [ new ProfitPerResult(Res.H, getAvgProfit(Res.H)),
                                  new ProfitPerResult(Res.D, getAvgProfit(Res.D)),
                                  new ProfitPerResult(Res.A, getAvgProfit(Res.A))];
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
   * Private utility class for nicer prnting.
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
      auto spec = singleSpec("%.2f");
      w.put(to!string(result));
      w.put(": ");
      formatElement(w, profit, spec);
      return w.data;
    }
  }
}


