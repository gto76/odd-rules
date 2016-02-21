import std.algorithm;
import std.array;
import std.conv;
import std.file;
import std.math;
import std.format;
import std.range;
import std.regex;
import std.stdio;
import std.string;
import std.typecons;
import core.thread;
import std.typecons;

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
//  writeln("Start");
//  RuleAndProfit[] rules = loadRules("results/random-rules");
//  writeln("Loading season");
//
//  string[] seasonsStr = getAllSeasonsOfYear("csv", 2015);
//  writeln("Seasons ### ");
////  writeln(seasonsStr);
//
////  string[] seasonsStr =     [ "football-england-0-2011", "football-england-1-2011", "football-england-2-2011", "football-england-3-2011", "football-scotland-0-2011", "football-scotland-1-2011", "football-scotland-2-2011", "football-scotland-3-2011", "football-germany-0-2011", "football-germany-1-2011" ];
////  string[] seasonsStr =     [ "football-england-0-2011", "football-england-1-2011", "football-england-2-2011", "football-england-3-2011", "football-scotland-0-2011", "football-scotland-1-2011", "football-scotland-2-2011", "football-scotland-3-2011", "football-germany-0-2011", "football-germany-1-2011" ];
//  //string[] lastSeasonsStr = [ "football-england-0-2010", "football-england-1-2010", "football-england-2-2010", "football-england-3-2010", "football-scotland-0-2010", "football-scotland-1-2010", "football-scotland-2-2010", "football-scotland-3-2010", "football-germany-0-2010", "football-germany-1-2010"];
//
//  Season[] seasons = loadAll(seasonsStr);
////  Season[] lastSeasons = loadAll(lastSeasonsStr);
//  Season[] lastSeasons = loadAll(getSeasonsBeforeNoDir(seasonsStr));
//
//  linkSeasons(seasons ~ lastSeasons);
//  writeln("Linked seasons");
//  double profitSum = 0;
//  double bets = 0;
//  double allBets = 0;
//  foreach (season; seasons) {
//    double[] profit = getProfitForSeason(season, rules, 0.01);
//    if (!isNaN(profit[0])) {
//      profitSum += profit[0];
//      bets += profit[1];
//      allBets += profit[2];
//    }
//  }
//  writeln("==============");
//  writeln("Betet times: " ~ to!string(bets) ~ "/"  ~ to!string(allBets));
//  writeln("Average profit: "~to!string(profitSum/bets));
//  writeln("\nThe End");

  printUpcomingGames();
}

void printUpcomingGames() {
  writeln("Start");
  RuleAndProfit[] rules = loadRules("results/random-rules");
  writeln("Loading season");
  string[] seasonsStr = getAllSeasonsOfYear("csv", 2015);
  writeln("Seasons ### ");
  Season[] seasons = loadAll(seasonsStr);
  Season[] lastSeasons = loadAll(getSeasonsBeforeNoDir(seasonsStr));
  linkSeasons(seasons ~ lastSeasons);
  writeln("Linked seasons");

  Game[] upcomingGames = readUpcomingGames();
  addGamesToRightSeason(upcomingGames, seasons);
  GameAndRule[] gamesAndRules = getDistancesOfUpcomingGames(seasons, rules);
  foreach (gar; gamesAndRules) {
    printGar(gar);
  }
  writeln("\nThe End");
}

void addGamesToRightSeason(Game[] upcomingGames, Season[] currentSeasons) {
  foreach (game; upcomingGames) {
    string leagueAbv = game.sAttrs["Div"];
    writeln("### League abv: "~leagueAbv);
    foreach (season; currentSeasons) {
      if (season.features["sport"] == "football" &&
          season.features["country"] == COUNTRY_OF_ABV[leagueAbv] &&
          season.features["league"] == LEAGUE_LEVEL_OF_ABV[leagueAbv] &&
          season.features["season"] == "2015") { // TODO current season begining year
        season.games ~= game;
        break;
      }
    }
  }
}

Game[] readUpcomingGames() {
  string dir = "../odds-scraper/results/";
  Game[] res;
  foreach (filename; dirEntries(dir, "*.txt", SpanMode.shallow)) {
    res ~= readUpcomingGamesFromFile(filename);
  }
  return res;
}

Game[] readUpcomingGamesFromFile(string filename) {
  writeln("### Upcoming games filename: " ~filename);
  Game[] res;
  // TODO get actual year.
  // '../odds-scraper/results/football_belgium_jupiler-pro-league_2016-02-21_00-03-26.txt'
  string leagueNameWithDir = filename.split("_2016")[0];
  // '../odds-scraper/results/football_belgium_jupiler-pro-league'
  writeln("### leagueNameWithDir: " ~leagueNameWithDir);
  string leagueName = leagueNameWithDir.split('/')[$-1];
  // 'football_belgium_jupiler-pro-league'
  writeln("### LeagueName: " ~leagueName);
  string leagueAbv = SHORTER_LEAGUE_NAMES[leagueName];
  string[] lines = readFile(filename);
  string[] buf;
  foreach (line; lines) {
    if (line == "") {
      res ~= getGame(buf, leagueAbv);
      buf = [];
      continue;
    }
    buf ~= line;
  }
  writeln("### Games: " ~ to!string(res));
  return res;
}

//  Game record looks like this:
//    link;https://www.betbrain.com/football/france/ligue-2/olympique-nimes-v-fc-metz/
//    time;22/02/16 19:30
//    name;Nimes - Metz
//    bet;1X2
//    odds;2.55 3.30 3.18
//    bet;Asian Handicap
//    odds;1.77 0 2.26
//    bet;Over Under
//    odds;2.20 2.5 1.82
Game getGame(string[] lines, string leagueAbv) {
  string date;
  string homeTeam;
  string awayTeam;
  foreach (line; lines) {
    auto pairMatch = matchFirst(line, regex("^name;"));
    if (!pairMatch.empty) {
      // 'name;Nimes - Metz'
      string pair = pairMatch.post;
      // 'Nimes - Metz'
      auto teams = pair.split(" - ");
      // [ 'Nimes', 'Metz' ]
      if (teams.length < 2) {
        writeln("Error in reading teams from upcoming game file!");
        return null;
      }
      homeTeam = teams[0];
      awayTeam = teams[1];
    }
    auto timeMatch = matchFirst(line, regex("^name;"));
    if (!timeMatch.empty) {
      // 'time;22/02/16 19:30'
      string time = timeMatch.post;
      // '22/02/16 19:30'
      string[] splitTime = time.split();
      // [ '22/02/16', '19:30' ]
      if (splitTime.length < 2) {
        writeln("Error in reading time from upcoming game file!");
        return null;
      }
      date = splitTime[1];
    }
  }
  string[string] atrs = [ "Div": leagueAbv, "Date": date, "HomeTeam": homeTeam, "AwayTeam": awayTeam ];
  return new Game(atrs);
}

void printGar(GameAndRule gar) {
  writeln(gar.game.sAttrs["HomeTeam"]);
  writeln(gar.game.sAttrs["AwayTeam"]);
  writeln(gar.rule.pao.getBestResult());
  writeln(gar.rule.distanceFromFront);
  writeln("-------------");
}

GameAndRule[] getDistancesOfUpcomingGames(Season[] seasons, RuleAndProfit[] rules) {
  GameAndRule[] res;
  foreach (season; seasons) {
    res ~= getDistancesOfUpcomingGames(season, rules);
  }
  return res;
}

GameAndRule[] getDistancesOfUpcomingGames(Season season, RuleAndProfit[] rules) {
  GameAndRule[] res;
  foreach (game; season.games) {
    // If game has result, then continue;
    if("FTR" in game.sAttrs) {
      continue;
    }
    RuleAndProfit rule = getBestRuleThatAplies(season, game, rules);
    res ~= new GameAndRule(game, rule);
  }
  writeln("### Distances: "~to!string(res));
  return res;
}

class GameAndRule {
  Game game;
  RuleAndProfit rule;
  this(Game game, RuleAndProfit rule) {
    this.game = game;
    this.rule = rule;
  }
}

/*
 * Returns result and distance, or null if no rule exists.
 */
RuleAndProfit getBestRuleThatAplies(Season season, Game game, RuleAndProfit[] rules) {
  foreach (rule; rules) {
    if (ruleAplies(game, season, rule.rule)) {
      return rule;
    }
  }
  return null;
}

public string[] getAllSeasonsOfYear(string dir, int year) {
  string[] ret;
//  writeln(dirEntries(dir, "*.csv", SpanMode.shallow));
  foreach (fileName; dirEntries(dir, "*.csv", SpanMode.shallow)) {
    string[] tokens = split(to!string(fileName), ".");
//    writeln(tokens);
    if (tokens.length < 2) {
      continue;
    }
    auto tokens1 = split(tokens[0], "-");
    if (tokens1.length < 2) {
      continue;
    }
//    writeln("bla "~tokens1);
    if (to!int(tokens1[$-1]) == year) {
      auto withouthDirTokens = tokens[0].split("/");
      ret ~= withouthDirTokens[1];
    }
  }
  return ret;
}

string[] getSeasonsBefore(string[] seasons) {
  string[] res;
  foreach (season; seasons) {
    writeln("Season before : "~season);
    string seasonBefore = getSeasonBefore(season);
    if (seasonBefore != "") {
      res ~= seasonBefore;
    }
  }
  return res;
}

string getSeasonBefore(string season) {
  writeln("Season: "~season);
  string[] tokens = split(season, ".");
  if (tokens.length < 2) {
    return "";
  }
  string[] tokens1 = tokens[0].split('-');
  if (tokens1.length < 2) {
    return "";
  }
  tokens1[$-1] = to!string(to!int(tokens1[$-1]) - 1);
  string ret = tokens1[0];
  for (int i = 1; i < tokens1.length; i++) {
    ret ~= '-' ~ tokens1[i];
  }
  return ret ~ ".csv";
}


string[] getSeasonsBeforeNoDir(string[] seasons) {
  string[] res;
  foreach (season; seasons) {
//    writeln("Season before : "~season);
    string seasonBefore = getSeasonBeforeNoDir(season);
    if (seasonBefore != "") {
      res ~= seasonBefore;
    }
  }
  return res;
}

string getSeasonBeforeNoDir(string season) {
//  writeln("Season: "~season);
  string[] tokens1 = season.split('-');
  if (tokens1.length < 2) {
    return "";
  }
  tokens1[$-1] = to!string(to!int(tokens1[$-1]) - 1);
  string ret = tokens1[0];
  for (int i = 1; i < tokens1.length; i++) {
    ret ~= '-' ~ tokens1[i];
  }
  return ret;
}

double[] getProfitForSeason(Season season, RuleAndProfit[] rules, double threshold) {
  int bets = 0;
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
        writeln("BetNo: "~to!string(bets++)~"/"~to!string(season.games.length));
        writeln("Profit so far");
        writeln(profitSum);
        writeln("Avg profit so far");
        writeln(profitSum/bets);
      }
    }
  }
  return [ profitSum, bets, season.games.length ];
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
//    writeln("Loading rules");

  RuleAndProfit[] rules;
  string[] lines = readFile(fileName);
//      writeln("Loading rules 2");

  for (int i = 0; i < lines.length; i += 2) {
//        writeln("Loading rule " ~ to!string(i));

    auto rule = new Rule(lines[i]);
//        writeln("Loading profit " ~ to!string(i+1));
    auto poc = new ProfitAndOccurances(lines[i+1]);
    rules ~= new RuleAndProfit(rule, poc);
  }
//      writeln("Loading rules 3");

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
