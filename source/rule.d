module rule;

import std.stdio;
import std.string;
import std.array;
import std.random;
import std.regex;
import std.range;
import std.conv;
import std.csv;
import std.algorithm;
import std.typecons;

import season;

///////////
// ENUMS //
///////////

enum Team { H, A }
enum Res { H, D, A }
enum NumericOperator { LT = "<", MT = ">=" }
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

  this(string line) {
//    writeln("Creating rule :"~line);
    auto tokens = line.split("AND ( ");
    auto generalRulesString = tokens[0];
    auto teamRulesString = tokens[1];
    teamRulesString = replaceFirst!(cap => "")
        (teamRulesString, regex(` \)`));

    generalRules = [ new DiscreteRule(generalRulesString) ];
//    writeln("Setting logic ops");
    setLogicOperators(teamRulesString);
//    writeln("Setting team rules");
    setTeamRules(teamRulesString);

//    writeln(generalRules);
//    writeln(logicOperators);
//    writeln(teamRules);
  }

  private void setLogicOperators(string teamRulesString) {
    auto operators = matchAll(teamRulesString, regex(`AND|OR`));
    foreach (op; operators) {
      string desc = op.hit;
      if (desc == "AND") {
        logicOperators ~= LogicOperator.AND;
      } else {
        logicOperators ~= LogicOperator.OR;
      }
    }
  }

  private void setTeamRules(string teamRulesString) {
    auto tokens = split(teamRulesString, regex("AND|OR"));
    foreach (ruleString; tokens) {
      teamRules ~= new TeamRule(ruleString.strip());
    }
  }

  /*
   * EXAMPLE:
   * ("country" = ["germany", "england"]) AND (A, "corners", 0) < 0.5 AND (H, "fouls", 1) > 0.5
   */
  override string toString() {
    string[] ret;
    foreach (val; generalRules) {
      ret ~= to!string(LogicOperator.AND);
      ret ~= val.toString();
    }
    bool first = true;
    foreach (val; zip(LogicOperator.AND ~ logicOperators, teamRules)) {
      ret ~= to!string(val[0]);
      if (first) {
        ret ~= "(";
        first = false;
      }
      ret ~= val[1].toString();
    }
    ret = ret[1..$];
    ret ~= ")";
    return ret.join(" ");
  }
}

/////////////////
// LEAGUE RULE //
/////////////////

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
  this(string line) {
    auto tokens = line.split('=');
    auto parameter = tokens[0].strip();
    super(parameter);
    auto valuesStr = removeParenthesis(tokens[1].strip());
    auto values = valuesStr.split(",");
    foreach (value; values) {
      this.values ~= removeDoubleQuotes(value.strip());
    }
  }
  override string toString() {
    return parameter ~ " = (\"" ~ values.join("\", \"") ~ "\")";
  }
}

string removeParenthesis(string line) {
  line.strip();
  line = chomp(line, ")");
  return chompPrefix(line, "(");
}

string removeDoubleQuotes(string line) {
  line.strip();
  line = chomp(line, "\"");
  return chompPrefix(line, "\"");
}

///////////////
// TEAM RULE //
///////////////

class TeamRule {
  Parameter parameter;
  NumericOperator numericOperator;
  Parameter otherParameter;
  double constant;

  this(Parameter parameter, NumericOperator numericOperator, Parameter otherParameter,
       double constant) {
    this.parameter = parameter;
    this.numericOperator = numericOperator;
    this.otherParameter = otherParameter;
    this.constant = constant;
  }

  this(string line) {
    setOperator(line);
    // '("HST", 1) > ("HY", 1) + 0.77'
    auto tokens = split(line, regex("<|>")); // TODO, change > to >= in future versions.
    // [ '("HST", 1) ', ' ("HY", 1) + 0.77' ]
    parameter = new Parameter(tokens[0].strip());
    setRightHand(tokens[1].strip());
  }

  private void setRightHand(string line) {
    // ' ("HY", 1) + 0.77'
    auto tokens = split(line, "+");
    // [ ' ("HY", 1) ', ' 0.77' ]
    if (tokens.length > 1) {
      otherParameter = new Parameter(tokens[0].strip());
      constant = to!double(tokens[1].strip());
    } else {
      constant = to!double(line);
    }
  }

  private void setOperator(string line) {
    auto operators = matchFirst(line, regex("<|>")); // TODO, change > to >= in future versions.
    auto operatorString = operators.hit;
    if (operatorString == "<") {
      numericOperator = NumericOperator.LT;
    } else {
      numericOperator = NumericOperator.MT;
    }
  }

  override string toString() {
    string[] res;
    res ~= parameter.toString();
    res ~= numericOperator;
    if (otherParameter !is null) {
      res ~= otherParameter.toString();
      res ~= "+";
    }
    if (constant != 0) {
      res ~= to!string(constant);
    }
    return res.join(" ");
  }
}

///////////////
// PARAMETER //
///////////////

/*
 * Number of games means that average for that many past games is calculaed.
 * If it is more than the number of games since the start of the season, the
 * rule fails.
 * If it is 0, it means only parameters of currnet game are processed (only
 * the ones that can be acquired before the game; home/away, referee, odds)
 * If it is -1, it means that the average of the last season is procesed,
 * if it is -2, the average of last two seasons, and so on.
 * If it exceedes the number of available seasons, the rule fails.
 */
class Parameter {
  string name;
//  Team team;
  int numberOfGames;
  this(string name, /+Team team,+/ int numberOfGames) {
//    this.team = team;
    this.name = name;
    this.numberOfGames = numberOfGames;
  }
  this(string line) {
    // ' ("HST", 1) '
    line = removeParenthesis(line);
    // '"HST", 1'
    auto tokens = line.split(',');
    // [ '"HST"', ' 1' ]
    name = removeDoubleQuotes(tokens[0]);
//    writeln("num of games: "~tokens[1]);
    numberOfGames = to!int(tokens[1].strip());
  }
  override bool opEquals(Object o) {
    if (o is null) {
      return false;
    }
    if (typeid(o) != typeid(Parameter)) {
      return false;
    }
    Parameter other = cast(Parameter) o;
    return other.name == this.name /+&& other.team == this.team+/
           && other.numberOfGames == this.numberOfGames;
  }
  override string toString() {
    return  "(" ~ ["\""~name~"\"", /+to!string(team),+/ to!string(numberOfGames)].join(", ") ~ ")";
  }
}

///////////////////////////
// RANDOM RULE GENERATOR //
///////////////////////////

// EXAMPLE RULE:
//  Rule rule = new Rule(
//      [new DiscreteRule("country", ["germany", "england"])],
//      [new TeamRule(new Parameter("AC", /+Team.A,+/ 3), NumericOperator.lt, null, 0.7), // corners
//       new TeamRule(new Parameter("HF", /+Team.H,+/ 5), NumericOperator.mt, null, 0.3)], // fouls
//      [LogicOperator.AND]);
Rule getRandomRule(Season[] seasons, string[] attributes, int widestWindow) {
  TeamRule[] teamRules;
  LogicOperator[] operators;
  int noOfTeamRules = uniform(1, 4);
  foreach (i; 0 .. noOfTeamRules) {
    auto firstParameter = getRandomParameter(attributes, widestWindow);
    auto operator = getRandomNumericOperator();
    Parameter secondParameter = getRandomOptionalParameter(attributes, widestWindow);
    double constant = cast(double) uniform(0, 101) / 100;
    teamRules ~= new TeamRule(firstParameter, operator, secondParameter, constant);
  }
  foreach (i; 0 .. noOfTeamRules-1) {
    operators ~= getRandomOperator();
  }
  return new Rule([new DiscreteRule("sport", ["football"])/+,
                   new DiscreteRule("country", ["germany", "england"])+/],
                   teamRules, operators);
}

Parameter getRandomParameter(string[] attributes, int widestWindow) {
  string attribute = attributes[uniform(0, attributes.length)];
  int windowSize = getWindowSize(widestWindow);
  return new Parameter(attribute, windowSize);
}

int getWindowSize(int widestWindow) {
  if (uniform(0,2) == 0) {
    return 1;
  } else {
    return uniform(2, widestWindow+1);
  }
}

NumericOperator getRandomNumericOperator() {
  if (uniform(0,2) == 0) {
    return NumericOperator.MT;
  } else {
    return NumericOperator.LT;
  }
}

Parameter getRandomOptionalParameter(string[] attributes, int widestWindow) {
  if (uniform(0,2) == 0) {
    return null;
  } else {
    return getRandomParameter(attributes, widestWindow);
  }
}

LogicOperator getRandomOperator() {
  if (uniform(0,2) == 0) {
    return LogicOperator.AND;
  } else {
    return LogicOperator.OR;
  }
}
