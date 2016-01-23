module averages;

import std.algorithm;
import std.array;
import std.conv;
import std.format;
import std.range;
import std.regex;
import std.stdio;
import std.string;
import std.typecons;

import season;

/*
 * Sets lastSeason for all seasons.
 */
public void linkSeasons(Season[] seasons) {
  foreach (season; seasons) {
    auto lastSeason = getSeasonBefore(seasons, season);
    if (lastSeason is null) {
      continue;
    }
    season.lastSeason = lastSeason;
  }
}

private Season getSeasonBefore(Season[] seasons, Season seasonThis) {
  string[string] fThis = seasonThis.features;
  foreach (seasonOther; seasons) {
    string[string] fOther = seasonOther.features;
    if (sameLeague(fThis, fOther)) {
      if (to!int(fThis["season"]) == to!int(fOther["season"]) - 1) {
        return seasonOther;
      }
    }
  }
  return null;
}

private bool sameLeague(string[string] fThis, string[string] fOther) {
  return fThis["sport"] == fOther["sport"] &&
         fThis["country"] == fOther["country"] &&
         fThis["league"] == fOther["league"];
}
//
//private double[][string] getAverages(Season season) {
//  double[][string] averages;
//  foreach (atribute; season.header) {
//    averages[atribute] = getAverage(season, atribute);
//  }
//  return averages;
//}
//
//private double[] getAverage(Season season, string atribute) {
////  double sum = 0;
//  double[] values;
//  foreach (game; season.games) {
//    string val = game[atribute];
//    try {
//      values ~= to!double(val);
//    } catch (ConvException e) {
//      return null;
//    }
//  }
////  return sum / season.games.length;
//  sort(values);
//  return values;
//}