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
import core.thread;

import game;
import profitAndOccurances;
import rule;
import season;
import conf;
import ruleAndProfit;

//////////
// MAIN //
//////////

void main(string[] args) {
  writeln("Start");

  RuleAndProfit[] rules = loadRules("results/random-rules");

//  foreach (rule; rules) {
//    writeln("----------");
//    writeln(rule.distanceFromFront);
//    writeln(rule);
//  }
  writeln("Loading season");

  Season season = loadSeason("csv/football-belgium-0-2012.csv");
  Season lastSeason = loadSeason("csv/football-belgium-0-2011.csv");
  linkSeasons([lastSeason, season]);
  writeln("Linked seasons");
  writeln("last season");
  writeln(season.lastSeason);
  writeln("last last season");
  writeln(lastSeason.lastSeason);
  double profit = getProfitForSeason(season, rules, 0.01);
  writeln("==============");
  writeln("Profit for season: "~to!string(profit));

  writeln("\nThe End");
}

double getProfitForSeason(Season season, RuleAndProfit[] rules, double threshold) {
  writeln("Getting profit for season");
  double profitSum = 0;
  orderByScore(rules);
  writeln("Starting loop");
  foreach (game; season.games) {
    foreach (rule; rules) {
      if (rule.distanceFromFront > threshold) {
        break;
      }
      // TODO, here last season should probably be passed, as a reference season.
      if (ruleAplies(game, season, rule.rule)) {
        Res result = rule.pao.getBestResult();
        Res actualResult = game.getResult();
        double profit;
        if (actualResult == result) {
          profit = game.getProfit();
        } else {
          profit = -1;
        }
        profitSum += profit;
        // CHECK THE RESULT !!!
        writeln("-----------");
        writeln("Betting on game: ");
        writeln(game);
        writeln("Rule: ");
        writeln(rule);
        writeln("Profit: ");
        writeln(profit);
      }
    }
  }
  return profitSum;
}

// Orders list of rules by score - distance to the front of nondominated solutions.
void orderByScore(RuleAndProfit[] rules) {
  auto nondominatedSolutions = getNondominatedSolutions(rules);
  foreach (rule; rules) {
    rule.distanceFromFront = getDistanceFromNondominatedLine(nondominatedSolutions, rule);
  }
  sort!("a.distanceFromFront < b.distanceFromFront", SwapStrategy.stable)(rules);
}


RuleAndProfit[] loadRules(string fileName) {
    writeln("Loading rules");

  RuleAndProfit[] rules;
  string[] lines = readFile(fileName);
      writeln("Loading rules 2");

  for (int i = 0; i < lines.length; i += 2) {
        writeln("Loading rule " ~ to!string(i));

    auto rule = new Rule(lines[i]);
        writeln("Loading profit " ~ to!string(i+1));
    auto poc = new ProfitAndOccurances(lines[i+1]);
    rules ~= new RuleAndProfit(rule, poc);
  }
      writeln("Loading rules 3");

  return rules;
}

string[] readFile(string fileName) {
  auto file = File(fileName, "r");
  string[] lines;
  foreach (line; file.byLine) {  // records = csvReader!(string[string])(file.byLine.joiner("\n"), null);
    lines ~= to!string(line);
  }
  return lines;
}

void randomRuleSearch() {
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
    RuleAndProfit rap = getRandomRap(seasons);
    if (rap is null ||
        rap.pao.occurances < OCCURANCE_TRESHOLD ||
        rap.pao.getMaxProfit() < 0.0) {
      continue;
    }
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
}

///////////////
// FUNCTIONS //
///////////////


//RuleAndProfit findLocalMinimum(RuleAndProfit[] nondominatedResults, RuleAndProfit result) {
//  double min = getDistanceFromNondominatedLine(nondominatedResults, result);
//
//  // foreach teamRule in rule:
//    // foreach parameter.numOfGames, otherParam.numOfGames, constant:
//      Rule newRule = rule
//      newRule.teamRules[i].parameter.numOfGames ++
//      double distance = getDistanceFromNondominatedLine(nondominatedResults, result)...
//      newRule.teamRules[i].parameter.numOfGames --
//}


//private Problem<S> problem;
//
//public static final int TOURNAMENTS_ROUNDS = 1;
//
//private List<List<Double>> indicatorValues;
//private double maxIndicatorValue;
//
//private int populationSize;
//private int archiveSize;
//private int maxEvaluations;
//
//private List<S> archive;
//
//private CrossoverOperator<S> crossoverOperator;
//private MutationOperator<S> mutationOperator;
//private SelectionOperator<List<S>, S> selectionOperator;
//
//private Fitness<S> solutionFitness = new Fitness<S>();
//
//public void run(int populationSize, Season[] seasons) {
//  RuleAndProfit[] solutionSet;
//  RuleAndProfit[] archive;
//  int evaluations = 0;
//
//  // Creates the initial solutionSet.
//  while (evaluations < populationSize) {
//    Rule rule = getRandomRule(seasons, ATTRIBUTES, WIDEST_WINDOW);
//    ProfitAndOccurances profitAndOccurances = getProfitAndOccurances(seasons, rule);
//    if (profitAndOccurances is null) {
//      continue;
//    }
//    RuleAndProfit rap = new RuleAndProfit(rule, profitAndOccurances);
//    solutionSet ~= rap;
//    evaluations++;
//  }
//
//  // ITERATION CONDITION:
//  while (evaluations < maxEvaluations) {
//    archive.addAll(solutionSet);
//
//    calculateFitness(archive);
//    while (archive.size() > populationSize) {
//      removeWorst(archive);
//    }
//    solutionSet.clear();
//    while (solutionSet.size() < populationSize) {
//      // SELECTION:
//      S parent1 = selectionOperator.execute(archive);
//      S parent2 = selectionOperator.execute(archive);
//      List<S> parents = Arrays.asList(parent1, parent2);
//      // CROSSOVER: p1 + p2 => c
//      S child = crossoverOperator.execute(parents).get(0);
//      // MUTATION: c => c`
//      mutationOperator.execute(child);
//      // EVALUATION:
//      problem.evaluate(child);
//      solutionSet.add(child);
//      evaluations++;
//    }
//
//  }
//}

void mutate(Rule rule) {

}

RuleAndProfit getRandomRap(Season[] seasons) {
  Rule rule = getRandomRule(seasons, ATTRIBUTES, WIDEST_WINDOW);
  ProfitAndOccurances profitAndOccurances = getProfitAndOccurances(seasons, rule);
  if (profitAndOccurances is null) {
    return null;
  }
  return new RuleAndProfit(rule, profitAndOccurances);
}

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
  double[][] points = getNondominatedPoints(nondominatedResults);
  double[2] point = [result.pao.getMaxProfit(), result.pao.occurances/Y_AXIS_DIVIDER];
  double minDistance = double.max;
  for (int i = 0; i < points.length-1; i++) {
    double distance = distToSegment(point, points[i], points[i+1]);
    if (distance < minDistance) {
      minDistance = distance;
    }
  }
  if (isNondominated(nondominatedResults, result) && minDistance != 0) {
    return -minDistance;
  }
  return minDistance;
}

/*
 * Checks if the passed RuleAndProfit is nodndominated by the array of RulesAndProfits.
 */
bool isNondominated(RuleAndProfit[] nondominatedResults, RuleAndProfit result) {
  auto combinedResults = getNondominatedSolutions(nondominatedResults ~ result);
  double[][] points = getNondominatedPoints(combinedResults);
  double[2] point = [result.pao.getMaxProfit(), result.pao.occurances/Y_AXIS_DIVIDER];
  return points.canFind(point);
}

double[][] getNondominatedPoints(RuleAndProfit[] nondominatedResults) {
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

// todo: Team rule needs to be updated. In case of specifiying for how many seasons in past we want to
// go.

// 0..2 = [0, 1] !

//  Rule rule = new Rule(
//      [new DiscreteRule("country", ["germany", "england"])],
//      [new TeamRule(new Parameter("AC", /+Team.A,+/ 3), NumericOperator.lt, null, 0.7), // corners
//       new TeamRule(new Parameter("HF", /+Team.H,+/ 5), NumericOperator.mt, null, 0.3)], // fouls
//      [LogicOperator.AND]);
