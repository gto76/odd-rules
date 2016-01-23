module rule;

import std.stdio;
import std.string;
import std.array;
import std.range;
import std.conv;
import std.csv;
import std.algorithm;
import std.typecons;

///////////
// ENUMS //
///////////

enum Team { H, A }
enum Res { H, D, A }
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
  override string toString() {
    string[] res;
    res ~= parameter.toString();
    res ~= numericOperator;
    if (otherParameter !is null) {
      res ~= otherParameter.toString();
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
  Team team;
  int numberOfGames;
  this(string name, Team team, int numberOfGames) {
    this.team = team;
    this.name = name;
    this.numberOfGames = numberOfGames;
  }
  override bool opEquals(Object o) {
    if (o is null) {
      return false;
    }
    if (typeid(o) != typeid(Parameter)) {
      return false;
    }
    Parameter other = cast(Parameter) o;
    return other.team == this.team && other.team == this.team
           && other.numberOfGames == this.numberOfGames;
  }
  override string toString() {
    return  "(" ~ ["\""~name~"\"", to!string(team), to!string(numberOfGames)].join(", ") ~ ")";
  }
}
