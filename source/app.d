import std.algorithm;
import std.array;
import std.conv;
import std.math;
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
    if (profit < 0.0) {
      continue;
    }
    RuleAndProfit rap = new RuleAndProfit(rule, profitAndOccurances);
    bestResults ~= rap;
//    bestResults = getNondominatedSolutions(bestResults);
//    sort(bestResults);
//    writeln();
//    writeln(to!string(bestResults));
//    writeln();

    auto nondominatedSolutions = getNondominatedSolutions(bestResults);
    sort(bestResults);
    foreach (result; bestResults) {
      writeln(result);
      write("Distance: ");
      writeln(getDistanceFromNondominatedLine(nondominatedSolutions, result));
    }
    writeln("===============================");

    counter = 1;
//    break;
  }
  writeln("\nThe End");
}

///////////////
// FUNCTIONS //
///////////////

RuleAndProfit[] getNondominatedSolutions(RuleAndProfit[] results) {
  sort(results);
  reverse(results);
  auto ret = appender!(RuleAndProfit[])();
  int maxOcc = int.min;
  foreach (rap; results) {
    if (rap.pao.occurances > maxOcc) {
      maxOcc = rap.pao.occurances;
      ret.put(rap);
    }
  }
  return ret.data;
}

double getDistanceFromNondominatedLine(RuleAndProfit[] nondominatedResults, RuleAndProfit result) {
  double[][] points = getNondominatedPoints(nondominatedResults, result);
  double[2] point = [result.pao.getMaxProfit(), result.pao.occurances/Y_AXIS_DIVIDER];
  double minDistance = double.max;
  for (int i = 0; i < points.length-1; i++) {
    double distance = distToSegment(point, points[i], points[i+1]);
    if (distance < minDistance) {
      minDistance = distance;
    }
  }
  return minDistance;
}

double[][] getNondominatedPoints(RuleAndProfit[] nondominatedResults, RuleAndProfit result) {
  bool first = true;
  auto points = appender!(double[][])();
  foreach (point; nondominatedResults) {
    if (first) {
      points.put([double.max, point.pao.occurances/Y_AXIS_DIVIDER]);
      first = false;
    }
    points.put([point.pao.getMaxProfit(), point.pao.occurances/Y_AXIS_DIVIDER]);
  }
  points.put([-double.max, nondominatedResults[$-1].pao.occurances/Y_AXIS_DIVIDER]);
  return points.data;
}

//RuleAndProfit getClosestPoint(RuleAndProfit[] nondominatedResults, RuleAndProfit result) {
//  RuleAndProfit closestPoint;
//  double minDistance = double.max;
//  foreach (point; nondominatedResults) {
//    double distance = (point.pao.getMaxProfit() - result.pao.getMaxProfit()) ^^ 2 +
//                      ((point.pao.occurances - result.pao.occurances)/Y_AXIS_DIVIDER) ^^ 2;
//    if (distance < minDistance) {
//      minDistance = distance;
//      closestPoint = point;
//    }
//  }
//  return closestPoint;
//}

/*
 * Distance to segment.
 */
double distToSegment(double[] p, double[] v, double[] w) {
  return sqrt(distToSegmentSquared(p, v, w));
}

double distToSegmentSquared(double[] p, double[] v, double[] w) {
  double l2 = dist2(v, w);
  if (l2 == 0) {
    return dist2(p, v);
  }
  double t = ((p[0]-v[0]) * (w[0]-v[0]) + (p[1]-v[1]) * (w[1]-v[1])) / l2;
  if (t < 0) {
    return dist2(p, v);
  }
  if (t > 1) {
    return dist2(p, w);
  }
  return dist2(p, [v[0] + t * (w[0] - v[0]), v[1] + t * (w[1] - v[1])]);
}

double dist2(double[] v, double[] w) {
  return (v[0] - w[0]) ^^ 2 + (v[1] - w[1]) ^^ 2;
}

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

// Team rule needs to be updated. In case of specifiying for how many seasons in past we want to
// go.
// 0..2 = [0, 1]
//  Rule rule = new Rule(
//      [new DiscreteRule("country", ["germany", "england"])],
//      [new TeamRule(new Parameter("AC", /+Team.A,+/ 3), NumericOperator.lt, null, 0.7), // corners
//       new TeamRule(new Parameter("HF", /+Team.H,+/ 5), NumericOperator.mt, null, 0.3)], // fouls
//      [LogicOperator.AND]);