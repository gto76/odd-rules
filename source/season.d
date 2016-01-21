module season;

import std.algorithm;
import std.csv;
import std.file;
import std.stdio;
import std.string;
import std.regex;
import std.conv;

import rule;

class Season {
  string[string] features;
  string[] header;
  string[string][] games;
  this(string[string] features, string[] header, string[string][] games) {
    this.features = features;
    this.header = header;
    this.games = games;
  }
}

/*
 * Reads all csv files in directory, and creates a Season object
 * from each one.
 */
public Season[] loadSeasonsFromDir(string dir) {
  Season[] seasons;
  foreach(fileName; dirEntries(dir, "*.csv", SpanMode.shallow)) {
    writeln("$$$ Loading season file: "~fileName);
    auto file = File(fileName, "r");
    auto records = csvReader!(string[string])(file.byLine.joiner("\n"), null);
    string[string][] games;
    foreach(record; records) {
      games ~= record;
    }
    auto features = getSeasonsFeatures(fileName);
    auto season = new Season(features, records.header, games);
    seasons ~= season;
    file.close();
  }
  return seasons;
}

private string[string] getSeasonsFeatures(string fileName) {
  string[] header = ["sport", "country", "league", "season"];
  int i = 0;
  string[string] features;
  string fileNameNoExtension = split(fileName, ".")[0];
  fileNameNoExtension = split(fileNameNoExtension, "\\")[1];
  foreach(feature; split(fileNameNoExtension, "-")) {
    features[header[i++]] = to!string(feature);
  }
  return features;
}

/*
 * Returns wether all of the generalRules of the rule are satisfied.
 */
public bool seasonFitsTheRule(Season season, Rule rule) {
  foreach (generalRule; rule.generalRules) {
    if (!ruleApplies(generalRule, season.features[generalRule.parameter])) {
      return false;
    }
  }
  return true;
}

private bool ruleApplies(GeneralRule rule, string parameterValue) {
  if (typeid(rule) == typeid(DigitRule)) {
    DigitRule digitRule = cast(DigitRule) rule;
    if (digitRule.numericOperator == NumericOperator.lt) {
      return to!double(parameterValue) < digitRule.constant;
    } else {
      return to!double(parameterValue) >= digitRule.constant;
    }
  } else if (typeid(rule) == typeid(DiscreteRule)) {
    DiscreteRule disRule = cast(DiscreteRule) rule;
    return disRule.values.canFind(parameterValue);
  }
  return false;
}