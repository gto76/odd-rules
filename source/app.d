import std.stdio;
import std.string;
import std.array;
import std.range;
import std.conv;

import std.csv;
import std.algorithm;
import std.typecons;

enum Team { H, A }
enum Had : Team { H = Team.H, D, A = Team.A}
enum NumericOperator { lt = "<", mt = ">" }
enum LogicOperator { AND, OR }

//////////
// RULE //
//////////

class Rule {
  GeneralRule[] generalRules;
  TeamRule[] teamRules;
  LogicOperator[] logicOperators;
  this(GeneralRule[] generalRules, TeamRule[] teamRules,
       LogicOperator[] logicOperators) {
    this.generalRules = generalRules;
    this.teamRules = teamRules;
    this.logicOperators = logicOperators;
  }
  /**
  * ("country" = ["germany", "england"]) AND (A, "corners", 0) < 0.5 AND (H, "fouls", 1) > 0.5
  */
  override string toString() {
    string[] ret;
    foreach (val; generalRules) {
      ret ~= to!string(LogicOperator.AND);
      ret ~= val.toString();
    }
    foreach (val; zip(LogicOperator.AND ~ logicOperators, teamRules)) {
      ret ~= to!string(val[0]);
      ret ~= val[1].toString();
    }
    ret = ret[1..$];
    return ret.join(" ");
  }
}

//////////////////
// GENERAL RULE //
//////////////////

abstract class GeneralRule {
  string parameter;
  this(string parameter) {
    this.parameter = parameter;
  }
}

// League level, ...
class DigitRule : GeneralRule {
  NumericOperator numericOperator;
  double constant;
  this(string parameter, NumericOperator numericOperator, double constant) {
    super(parameter);
    this.numericOperator = numericOperator;
    this.constant = constant;
  }
  override string toString() {
    return [parameter, numericOperator, to!string(constant)].join(" ");
  }
}

// Country, sport, ...
class DiscreteRule : GeneralRule {
  string[] values;
  this(string parameter,string[] values) {
    super(parameter);
    this.values = values;
  }
  override string toString() {
    return parameter ~ " = (\"" ~ values.join("\", \"") ~ "\")";
  }
}

///////////////
// TEAM RULE //
///////////////

abstract class TeamRule {
  Parameter parameter;
  NumericOperator numericOperator;
  this(Parameter parameter, NumericOperator numericOperator) {
    this.parameter = parameter;
    this.numericOperator = numericOperator;
  }
}

class TeamRuleWithOtherParameter : TeamRule {
  Parameter otherParameter;
  this(Parameter parameter, NumericOperator numericOperator,
       Parameter otherParameter) {
    super(parameter, numericOperator);
    this.otherParameter = otherParameter;
  }
  override string toString() {
    return [parameter.toString(), numericOperator, otherParameter.toString()].join(" ");
  }
}

class TeamRuleWithConstant : TeamRule {
  double constant;
  this(Parameter parameter, NumericOperator numericOperator,
       double constant) {
    super(parameter, numericOperator);
    this.constant = constant;
  }
  override string toString() {
    return [parameter.toString(), numericOperator, to!string(constant)].join(" ");
  }
}

///////////////
// PARAMETER //
///////////////

abstract class Parameter {
  string name;
  Team team;
  this(string name, Team team) {
    this.team = team;
    this.name = name;
  }
}

class ParameterWholeSeason : Parameter {
  this(string name, Team team) {
    super(name, team);
  }
  override string toString() {
    return "(\"" ~ [name, to!string(team)].join("\", \"") ~ "\")";
  }
}

class ParameterForLastGames : Parameter {
  int numberOfGames;
  this(string name, Team team, int numberOfGames) {
    super(name, team);
    this.numberOfGames = numberOfGames;
  }
  override string toString() {
    //return "(" ~ [name, to!string(team), to!string(numberOfGames)].join(", ") ~ ")";
    return  "(" ~ ["\""~name~"\"", to!string(team), to!string(numberOfGames)].join(", ") ~ ")";
  }
}

//////////
// MAIN //
//////////

class ProfitAndCommones {
  double profit;
  double commones;
  this(double profit, double commones) {
    this.profit = profit;
    this.commones = commones;
  }
}

class SeasonWithHeader {
  string[] header;
  string[string][] games;
  this(string[] header, string[string][] games) {
    this.header = header;
    this.games = games;
  }
}

void main(string[] args) {
  Rule rule = new Rule([new DiscreteRule("country", ["germany", "england"])],
                       [new TeamRuleWithConstant(new ParameterForLastGames("corners", Team.A,  0), NumericOperator.lt, 0.5),
                       new TeamRuleWithConstant(new ParameterForLastGames("fouls", Team.H, 1), NumericOperator.mt, 0.5)],
                       [LogicOperator.AND]);

  writeln(rule);
  //foreach(record; file.byLine.joiner("\n").csvReader!(Tuple!(string, string, string, string, int, int , string, int , int, string, string, int, int, int, int, int, int , int, int, int, int, int, int, double, double, int, double, double, double, double, double, double, double, int, double, double, int, double, double, double, double, double, double, double, int , double, double, double, double, double, int, double, double, double, double, double, double, int, double, double, double, double, int, double, double, double, double, double)))
  auto file = File("E0.csv", "r");
  auto records = csvReader!(string[string])(file.byLine.joiner("\n"), null);
  string[string][] games;
  foreach(record; records) {
    games ~= record;
  }
  auto swh = new SeasonWithHeader(records.header, games);
  file.close();
  auto profitAndCommones = getProfitAndCommones([swh], rule);
}

ProfitAndCommones getProfitAndCommones(SeasonWithHeader[] swhs, Rule rule) {
  writeln(swhs[0].games[0]["Div"]);
  writeln(swhs[0].header[4]);
  return null;
}
















