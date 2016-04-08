Odd Rules
=========

#### Živjo!

Sprogramiral sem algoritem, ki izračuna število pojavitev in dobičkonosnost pravila. 
Sama pravila zaenkrat generira naključno.

Za podatke sem podal glavne evropske nogometne lige (zadnje 3 sezone), kar je približno 20000 tekem. Podatke sem dobil iz http://www.football-data.co.uk/data.php

Rezultati po osmih urah
-----------------------

#### Najbolj dobičkonosna pravila, ki imajo vsaj 50 pojavitev (0.25% vseh tekem)
```
sport = ("football") AND ( ("FTAG", 4) < 0.08 AND ("HS", 2) > 0.07 AND ("HF", 9) > ("HTAG", 6) + 0.81 )
A: 0.65 H: -0.29 D: -0.32 occ: 92
==========================
sport = ("football") AND ( ("HTAG", 7) > ("AS", 9) + 0.89 )
A: 0.67 H: -0.30 D: -0.49 occ: 53
==========================
sport = ("football") AND ( ("HR", 5) > ("HY", 7) + 0.93 AND ("AS", 1) < ("HY", 1) + 0.44 )
A: 1.00 H: -0.19 D: -0.59 occ: 54
```

#### Najbolj dobičkonosna pravila, ki imajo vsaj 200 pojavitev (1% vseh tekem)
```
sport = ("football") AND ( ("HTAG", 4) < 0.02 AND ("AY", 9) > ("HS", 1) + 0.42 )
A: 0.28 H: -0.19 D: -0.25 occ: 206 
==========================
sport = ("football") AND ( ("HTHG", 10) < ("AF", 7) + 0.77 AND ("AY", 1) < ("AC", 1) + 0.87 AND ("FTAG", 6) < 0.02 )
A: 0.29 D: -0.10 H: -0.21 occ: 377
==========================
sport = ("football") AND ( ("AS", 1) < ("HY", 1) + 0.09 AND ("FTAG", 6) < 0.01 )
A: 0.32 H: -0.22 D: -0.22 occ: 244 
```

##### Legenda
* FTHG: Full time home goals
* FTAG: Full time away goals
* HTHG: Half time home goals
* HTAG: Half time away goals
* HS: Home shots
* AS: Away shots
* HST: Home shots on target
* AST: Away shots on tartget
* HF: Home fouls
* AF: Away fouls
* HC: Home corners
* AC: Away corners
* HY: Home yellow cards
* AY: Away yellow cards
* HR: Home red cards
* AR: Away red cards

Pravilo ima obliko
------------------

* PRAVILA KI DEFINIRAJO LIGO, AND
  - (šport, država, katera liga v državi, od katere sezone naprej)
* PRAVILA KI DEFINIRAJO TEKMO
  - pravilo AND/OR pravilo AND/OR ...

#### Pravilo ki definira tekmo
  * parameter `<`/`>` parameter + konstanta (0.0 -> 1.0), ali
  * parameter `<`/`>` konstanta (0.0 -> 1.0)

#### Parameter
  * (atribut (goli, kartoni, ...) , število tekem)

Število tekem pomeni, za koliko tekem nazaj se gleda vrednost attributa.

Vrednost vsakega parametera je med 0 in 1. Dobi se jo tako, da se prvo izračuna 
vsoto atributov. Nato se izračuna vse možne vrednosti identičnega parametera v prejšnji 
sezoni. Nato se pogleda katero mesto med temi vrednostmi zavzema trenutna vrednost. 
Se pravi naprimer, če je v tekmi ena ekipa dala rekordno število golov (glede na 
prejšnjo sezono), bo ta parameter imel vrednost 1.0, ali če je dala srednjo vrednost 
golov (mediano), bo imel parameter vrednost 0.5.

Manjka še
---------
* Algoritem, ki bo za podano tekmo vrnil veljavna pravila.
* Optimizacijski algoritem, ki bo iskal pravila.

How to profile
--------------
--build=profile

How to install Dlang on Debian
------------------------------
To enable it, add the repository sources:
```
$ sudo wget http://netcologne.dl.sourceforge.net/project/d-apt/files/d-apt.list -O /etc/apt/sources.list.d/d-apt.list
```
then update local info and install "d-apt" public key (fingerprint 0xEBCF975E5BA24D5E):
```
$ sudo apt-get update && sudo apt-get -y --allow-unauthenticated install --reinstall d-apt-keyring && sudo apt-get update
```
then install:
```
sudo apt-get install dmd-bin



For setting up git server check
-------------------------------
https://git-scm.com/book/it/v2/Git-on-the-Server-Setting-Up-the-Server


