#!/usr/bin/python3
#
# Usage: test.py 
# 

import sys
import re
import csv

H = [ "Div","Date","HomeTeam","AwayTeam","Full time home goals","Full time away goals","Full time result","Half time home goals","Half time away goals","Half time result","Referee","Home shots","Away shots","Home shots on target","Away shots on target","Home fouls","Away fouls","Home corners","Away corners","Home yellows","Away yellows","Home reds","Away reds","Bet365 home odds","Bet365 draw odds","Bet365 away odds","Bet&Win home odds","Bet&Win draw odds","Bet&Win away odds","gamebookers home odds","gamebookers draw odds","gamebookers away odds","Interwetten home odds","Interwetten draw odds","Interwetten away odds","Ladbrokes home odds","Ladbrokes draw odds","Ladbrokes away odds","Sportingbet home odds","Sportingbet draw odds","Sportingbet away odds","Will Hill home odds","Will Hill draw odds","Will Hill away odds","Stan James home odds","Stan James draw odds","Stan James away odds","VC Bet home odds","VC Bet draw odds","VC Bet away odds","Betbrain 1X2 bookies","Betbrain max home odds","Betbrain average home odds","Betbrain max draw odds","Betbrain average draw odds","Betbrain max away odds","Betbrain average away odds","Betbrain over/under bookies","Betbrain max >2.5","Betbrain average >2.5","Betbrain max <2.5","Betbrain average <2.5","Betbrain Asian bookies","Betbrain Asian home handicap","Betbrain max Asian home odds","Betbrain average Asian home odds","Betbrain max Asian away odds","Betbrain average Asian away odds" ]


D "Div",
date "Date",
D "HomeTeam",
D "AwayTeam",
n "Full time home goals",
n "Full time away goals",
D/n "Full time result",
n "Half time home goals",
n "Half time away goals",
D/n "Half time result",
D "Referee",
n "Home shots",
n "Away shots",
n "Home shots on target",
n "Away shots on target",
n "Home fouls",
n "Away fouls",
n "Home corners",
n "Away corners",
n "Home yellows",
n "Away yellows",
n "Home reds",
n "Away reds"

class Game:
  def __init__(self, row):
    self.p = {}
    for a in zip(H, row):
      self.p[a[0]] = a[1]

def main():
  reader = csv.reader(open('example.csv', newline='\n'), delimiter=',', quotechar='"')
  rdr = list(reader)
  rdr.pop(0)
  games = [Game(row) for row in rdr]
  #print("Home "+str(getHomeRating(games)))
  #print("Draw "+str(getDrawRating(games)))
  #print("Away "+str(getAwayRating(games)))

  #print("DrawOdds small "+str(getDrawOddSmall(games)))
  #print("DrawOdds med "+str(getDrawOddMed(games)))
  #print("DrawOdds high "+str(getDrawOddHigh(games)))

  teams = getAllValuesOf(games, "HomeTeam")
  
  for team in teams:
    print()
    wdl = getWdl(games, team)
    print(team + " " + str(wdl[4]))
    print("W   % 10.4f" % wdl[0])
    print("D   % 10.4f" % wdl[1])
    print("L   % 10.4f" % wdl[2])
    print("all % 10.4f" % wdl[3])


# for game:
  # wdlLast = getWdl(lastGame)
    # lstWdl, odds: [w, [2.8, -1, -1]]
  # goalsNuLast = getNumGl(lastGame)
    # lastGoals, odds: [5, [-1, -1, 2.1]]
  # foulsNuLast = getFouls(lastGame)
    # lastFouls, odds [14, [-1, 3.8, -1]]
  # last game = game


def getWdl(games, team):
  wins = getEvertonWinRating(games, team)
  draw = getRatingDraw(games, team)[0]
  lose = getEvertonLoseRating(games, team)[0]
  combined = wins[0] + draw + lose
  return (wins[0], draw, lose, combined, wins[1])

def getAllValuesOf(games, valueName):
  values = set()
  for game in games:
    values.add(game.p[valueName])
  return values

def getEvertonWinRating(games, team):
  return getRating(games, team, getWinnerAndOdd)

def getEvertonLoseRating(games, team):
  return getRating(games, team, getLoserAndOdd)

def getRatingDraw(games, team):
  oddVal = "max"
  games = [g for g in games if teamInGame(g, team)]
  sum = 0
  for game in games:
    if game.p["Full time result"] == "D":
      sum += float(game.p["Betbrain "+oddVal+" draw odds"]) - 1
    else:
      sum -=1
  return sum / len(games), len(games)

def getRating(games, team, fun):
  games = [g for g in games if teamInGame(g, team)]
  sum = 0
  for game in games:
    oddsTeam, odd = fun(game, "max")
    if oddsTeam == team:
      #print("Team won you get "+str(odd-1))
      sum += odd - 1
    else:
      #print("Team lost you get -1")
      sum -=1
  return sum / len(games), len(games)

def getWinner(game):
  if game.p["Full time result"] == "H":
    return game.p["HomeTeam"]
  elif game.p["Full time result"] == "A":
    return game.p["AwayTeam"]
  return ""

def getWinnerAndOdd(game, oddVal):
  if game.p["Full time result"] == "H":
    return game.p["HomeTeam"], float(game.p["Betbrain "+oddVal+" home odds"])
  elif game.p["Full time result"] == "A":
    return game.p["AwayTeam"], float(game.p["Betbrain "+oddVal+" away odds"])
  return "", float(game.p["Betbrain "+oddVal+" draw odds"])

def getLoserAndOdd(game, oddVal):
  if game.p["Full time result"] == "A":
    return game.p["HomeTeam"], float(game.p["Betbrain "+oddVal+" away odds"])
  elif game.p["Full time result"] == "H":
    return game.p["AwayTeam"], float(game.p["Betbrain "+oddVal+" home odds"])
  return "", float(game.p["Betbrain "+oddVal+" draw odds"])

def getTeamLoseRating(games, team):
  sum = 0
  for game in games:
    if game.p["Full time result"] == "H" and game.p["AwayTeam"] == team:
      sum += float(game.p["Betbrain max home odds"])
    elif game.p["Full time result"] == "A" and game.p["HomeTeam"] == team:
      sum += float(game.p["Betbrain max away odds"])
    else:
      sum -=1
  return sum / len(games), len(games)

def teamInGame(game, team):
  return team in [game.p["HomeTeam"], game.p["AwayTeam"]]

def teamWon(game, team):
  return (game.p["HomeTeam"] == team and game.p["Full time result"] == "H") or \
      (game.p["AwayTeam"] == team and game.p["Full time result"] == "A")

def getHomeRating(games):
  return getHomeAwayRating(games, "H", "home")

def getAwayRating(games):
  return getHomeAwayRating(games, "A", "away")

def getDrawRating(games):
  return getHomeAwayRating(games, "D", "draw")

def getHomeAwayRating(games, abv, name):
  sum = 0
  for game in games:
    if game.p["Full time result"] == abv:
      sum += float(game.p["Betbrain average "+name+" odds"])
    else:
      sum -=1
  return sum / len(games), len(games)

def getTeamRating(games, team):
  sum = 0
  for game in games:
    if game.p["Full time result"] == abv:
      sum += float(game.p["Betbrain max "+name+" odds"])
    else:
      sum -=1
  return sum / len(games), len(games)

def getDrawOddSmall(games):
  return getDrawOdd(games, 1, 2.8)

def getDrawOddMed(games):
  return getDrawOdd(games, 2.8, 4)

def getDrawOddHigh(games):
  return getDrawOdd(games, 4, 15)

def getDrawOdd(games, m, M):
  sum = 0
  counter = 0
  for game in games:
    if float(game.p["Betbrain average draw odds"]) < M and float(game.p["Betbrain average draw odds"]) > m:
      sum += getAverageEarning(game)
      counter += 1
  return sum / counter, counter

def getAverageEarning(game):
  sum = 0
  sum = 1 / float(game.p["Betbrain max home odds"])
  sum += 1 / float(game.p["Betbrain max draw odds"])
  sum += 1 / float(game.p["Betbrain max away odds"]) 
  return sum

if __name__ == '__main__':
  main()
