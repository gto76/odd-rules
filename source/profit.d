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

  public double getMaxProfit() {
    double max = double.min_normal;
    foreach (res; [Res.H, Res.D, Res.A]) {
      double val = getAvgProfit(res);
      if (val > max) {
        max = val;
      }
    }
    return max;
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
    return w.data;
  }

  private void append(Appender!string w, FormatSpec!char spec, Res res) {
    formatElement(w, getAvgProfit(res), spec);
  }
}

/*
 * Returns profit of winning option.
 */
public double getProfit(string[string] game) {
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

/*
 * Updated profits for all outcomes.
 */
public void setProfit(ProfitAndOccurances pao, Res res, double profit) {
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
