globals [ showPheromone showAnts showFood totalPheromone ] ; Self-Explanatory
breed [ ants ant ] ; Ants
breed [ foods food ] ; Food
patches-own [ pheromone ]
ants-own [ eaten ]

; Development purposes ONLY
to drawpheromone
  if mouse-down? [
    let x (round mouse-xcor)
    let y (round mouse-ycor)
    ask patch x y [
      set pheromone (pheromone + 0.1 * PheromoneMaxIntensity)
      if pheromone > PheromoneMaxIntensity [
        set pheromone PheromoneMaxIntensity
        if not (showPheromone = false) [ set pcolor scale-color PheromoneColor pheromone 0 (PheromoneMaxIntensity * (PheromoneContrast / 100)) ]
      ]
    ]
  ]
end

to setup
  clear-all

  ; Setup world according to options
  resize-world 0 WorldSize 0 WorldSize
  set-patch-size PatchSize

  ; Clear all pheromone of the field
  clearPheromone

  create-foods feedingspots [
    set shape "circle"
    set color orange
    set size (feedingspotradius * 2)
    setxy random-xcor random-ycor
  ]

  repeat (count patches) [
    let pxp 0 ; Patch x preference
    let pyp 0 ; Patch y preference
    let pap false ; Patch allow preference
    ask one-of patches [
      if random 100 < coverageRate [
        if AntStartingPosition = "Spread Out" [
          set pxp pxcor
          set pyp pycor
        ]
        if AntStartingPosition = "On Feeding Spots" [
          ask one-of foods [
            set pxp xcor
            set pyp ycor
          ]
        ]
        set pap true
      ]
    ]
    if pap = true [
      create-ants 1 [
        set color red
        set shape "bug"
        set eaten 0
        setxy pxp pyp
      ]
    ]
  ]

  reset-ticks
end

to step
  ; Add pheromone at feedingspots
  if pheromoneAtFeedingSpots > 0 [
    ask foods [
      ask patch-here [
        set pheromone (pheromone + pheromoneMaxIntensity * (pheromoneAtFeedingSpots / 100))
      ]
    ]
  ]

  ; Ant Behaviour
  ask ants [
    ; Eat from foodsource
    if (count foods in-radius (FeedingSpotRadius + 0.5) > 0) [ set eaten AntsSatiatedTicks ]

    ; Change of death
    if (random-float 100 < ChanceOfDeath) [ die ]

    ; Sense your surroundings
    let sensedpheromone [ 0 0 ]
    set sensedpheromone ant-sense
    if (item 0 sensedpheromone) = 0 [
      left RotationAngle
    ]
    if (item 0 sensedpheromone) = 2 [
      right RotationAngle
    ]

    ; If possible, move
    if not ((item 0 sensedpheromone) = 3) [ forward AntStepSize ]

    ; Dump pheromone
    ifelse eaten > 0 [
      if AntsGoHungry [
        set eaten (eaten - 1)
      ]
      set color green
      ask patch-here [
        set pheromone (pheromone + (pheromoneMaxIntensity * (pheromoneDepositRatio / 100)))
        if pheromone > pheromoneMaxIntensity [ set pheromone pheromoneMaxIntensity ]
      ]
    ] [
      set color red
      ask patch-here [
        ; Passive pheromone discretion
        set pheromone (pheromone + (pheromoneMaxIntensity * (passivePheromoneDiscretion / 100)))
      ]
    ]
  ]

  ; Diffuse pheromones
  diffuse pheromone (PheromoneDiffusionRate / 100)

  ; Pheromone Dissapation/Evaporation
  set totalPheromone 0
  ask patches [
    if pheromone > PheromoneMaxIntensity [ set pheromone PheromoneMaxIntensity ]
    set pheromone (pheromone * (1 - 1 / PheromoneEvaporationRate))
    if not (showPheromone = false) [ set pcolor scale-color PheromoneColor pheromone 0 (PheromoneMaxIntensity * (PheromoneContrast / 100)) ]
    set totalPheromone (totalPheromone + pheromone)
  ]

  ; Update pheromone contrast
  if AutomaticPheromoneContrast [
    set PheromoneContrast (precision ((totalPheromone - count foods * (PheromoneMaxIntensity * (PheromoneAtFeedingSpots / 100))) / 1000 * 0.75) 1)
    if PheromoneContrast < 1 [ set PheromoneContrast 1 ]
    if PheromoneContrast > 200 [ set PheromoneContrast 200 ]
  ]

  ; Tick
  tick
end

; Ants be sensing
to-report ant-sense
  let sensedpheromone [ 3 0 ]

  ; Look forward
  let cimf false ; Can I Move Forward (Is there not another ant there?)
  ask patch-ahead AntStepSize [
    if (count ants-at pxcor pycor) = 0 or AntsMayShareLocation [
      set cimf true
    ]
  ]
  ; If I can move forward, consider pheromone
  if cimf [
    ask patch-ahead SensorOffset [
      set sensedpheromone list 1 pheromone
    ]
  ]

  ; Look Left
  let ciml false ; Can I Move Left (Is there not another ant there?)
  ask patch-left-and-ahead RotationAngle AntStepSize [
    if (count ants-at pxcor pycor) = 0 or AntsMayShareLocation [
      set ciml true
    ]
  ]
  ; If I can move left, consider pheromone
  if ciml [
    ask patch-left-and-ahead SensorAngle SensorOffset [
      if pheromone > (item 1 sensedpheromone) [
        set sensedpheromone list 0 pheromone
      ]
    ]
  ]

  ; Look Right
  let cimr false ; Can I Move Right (Is there not another ant there?)
  ask patch-right-and-ahead RotationAngle AntStepSize [
    if (count ants-at pxcor pycor) = 0 or AntsMayShareLocation [
      set cimr true
    ]
  ]
  ; If I can move right, consider pheromone
  if cimr [
    ask patch-right-and-ahead SensorAngle SensorOffset [
      if (pheromone > item 1 sensedpheromone) [
        set sensedpheromone list 2 pheromone
      ]
    ]
  ]

  report sensedpheromone
end

; Clear all pheromone from the world
to ClearPheromone
  ask patches [
    set pheromone 0
    if not (showPheromone = false) [ set pcolor scale-color PheromoneColor pheromone 0 (PheromoneMaxIntensity * (PheromoneContrast / 100)) ]
  ]
end

; Modify the amount of ants
to ModAnts [ n ]
  if n > 0 [
    create-ants n [
      set color red
      set shape "bug"
      setxy random-xcor random-ycor
      set eaten 0
      if (showAnts = false) [ ht ]
    ]
  ]
  if n < 0 [
    if (abs n > count ants) [ set n (count ants) ]
    ask n-of (abs n) ants [
      die
    ]
  ]
end

; Spread out the ants over the playfield
to RedistributeAnts
  ask ants [
    setxy random-xcor random-ycor
  ]
end

; Toggle the visibility of ants
to ToggleAnts
  ; Fallback for initial showAnts value (is 0, should be considered true)
  if (showAnts = 0) [ set showAnts true ]

  ; Toggle showAnts
  set showAnts (not showAnts)

  ; Update ants
  ask ants [
    ifelse showAnts [ st ] [ ht ]
  ]
end

; Toggle Food
to ToggleFood
  ; Fallback for initial showFood value (is 0, should be considered true)
  if (showFood = 0) [ set showFood true ]

  ; Toggle showFood
  set showFood (not showFood)

  ; Update foods
  ask foods [
    ifelse showFood [ st ] [ ht ]
  ]
end

; Toggle the visibility of pheromone
to TogglePheromone
  ; Fallback for initial showPheromone value (is 0, should be considered true)
  if (showPheromone = 0) [ set showPheromone true ]

  ; Toggle showPheromone
  set showPheromone (not showPheromone)

  ; Update patches
  ifelse showPheromone [
    ask patches [
      set pcolor (scale-color PheromoneColor pheromone 0 1)
    ]
  ] [
    ask patches [
      set pcolor black
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
445
25
1056
637
-1
-1
3.0
1
10
1
1
1
0
1
1
1
0
200
0
200
1
1
1
ticks
30.0

TEXTBOX
10
65
160
83
World Controls
11
0.0
1

SLIDER
5
80
210
113
WorldSize
WorldSize
20
62 * (10 / patchSize)
200.0
2
1
patches²
HORIZONTAL

BUTTON
5
25
70
58
Setup
setup
NIL
1
T
OBSERVER
NIL
X
NIL
NIL
1

BUTTON
75
25
140
58
Step
step
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
0

BUTTON
145
25
210
58
Go
step
T
1
T
OBSERVER
NIL
G
NIL
NIL
0

TEXTBOX
10
10
160
28
Simulation Controls
11
0.0
1

TEXTBOX
450
10
600
28
View
11
0.0
1

SLIDER
5
115
210
148
PatchSize
PatchSize
1
40
3.0
1
1
px
HORIZONTAL

SLIDER
225
25
430
58
CoverageRate
CoverageRate
0
100
15.0
1
1
%
HORIZONTAL

CHOOSER
225
60
430
105
AntStartingPosition
AntStartingPosition
"Center" "Spread Out" "On Feeding Spots"
1

TEXTBOX
230
10
380
28
Ant Controls
11
0.0
1

SLIDER
5
150
210
183
FeedingSpots
FeedingSpots
0
(WorldSize * WorldSize) / 1000
20.0
1
1
spots
HORIZONTAL

SLIDER
5
185
210
218
FeedingSpotRadius
FeedingSpotRadius
0.5
WorldSize / 10
0.5
0.5
1
patches
HORIZONTAL

SLIDER
225
110
430
143
AntStepSize
AntStepSize
0
WorldSize / 10
1.0
.1
1
patch(es)
HORIZONTAL

SLIDER
225
180
430
213
SensorAngle
SensorAngle
0
180
22.5
1
1
°
HORIZONTAL

SWITCH
225
250
430
283
AntsMayShareLocation
AntsMayShareLocation
1
1
-1000

SLIDER
225
215
430
248
RotationAngle
RotationAngle
0
180
45.0
1
1
°
HORIZONTAL

SLIDER
225
355
430
388
ChanceOfDeath
ChanceOfDeath
0
1
0.01
0.01
1
%
HORIZONTAL

TEXTBOX
230
475
380
493
Playing for God
11
0.0
1

BUTTON
225
490
325
523
Redistribute Ants
RedistributeAnts
NIL
1
T
OBSERVER
NIL
R
NIL
NIL
0

BUTTON
330
490
430
523
Clear Pheromone
ClearPheromone
NIL
1
T
OBSERVER
NIL
C
NIL
NIL
0

BUTTON
225
525
430
558
Redistribute Ants & Clear Pheromone
RedistributeAnts\nClearPheromone
NIL
1
T
OBSERVER
NIL
&
NIL
NIL
0

SLIDER
225
145
430
178
SensorOffset
SensorOffset
0
10
9.0
0.1
1
patches
HORIZONTAL

INPUTBOX
5
280
210
340
PheromoneColor
45.0
1
0
Color

SWITCH
5
345
210
378
AutomaticPheromoneContrast
AutomaticPheromoneContrast
0
1
-1000

SLIDER
5
380
210
413
PheromoneContrast
PheromoneContrast
1
200
200.0
1
1
%
HORIZONTAL

INPUTBOX
225
595
325
665
AntsToModify
100.0
1
0
Number

BUTTON
330
595
430
628
Add Ants
ModAnts (abs AntsToModify)
NIL
1
T
OBSERVER
NIL
A
NIL
NIL
0

TEXTBOX
215
10
230
751
|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|
11
5.0
1

TEXTBOX
10
265
160
283
Pheromone Controls\n
11
0.0
1

BUTTON
330
632
430
665
Remove Ants
ModAnts (-1 * abs AntsToModify)
NIL
1
T
OBSERVER
NIL
D
NIL
NIL
0

TEXTBOX
435
10
450
751
|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|
11
5.0
1

BUTTON
225
425
430
458
Toggle Ant Visibility
ToggleAnts
NIL
1
T
OBSERVER
NIL
T
NIL
NIL
0

TEXTBOX
225
460
435
478
-----------------------------------------
13
5.0
1

BUTTON
5
415
210
448
Toggle Pheromone Visibility
TogglePheromone
NIL
1
T
OBSERVER
NIL
P
NIL
NIL
0

TEXTBOX
5
250
215
268
-----------------------------------------
13
5.0
1

BUTTON
5
220
210
253
Toggle Feeding Spot Visibility
ToggleFood
NIL
1
T
OBSERVER
NIL
F
NIL
NIL
0

SLIDER
5
450
210
483
PheromoneDepositRatio
PheromoneDepositRatio
0
100
100.0
1
1
%
HORIZONTAL

SLIDER
5
485
210
518
PheromoneEvaporationRate
PheromoneEvaporationRate
0
100
5.0
1
1
ticks
HORIZONTAL

SLIDER
5
520
210
553
PheromoneDiffusionRate
PheromoneDiffusionRate
0
100
90.0
1
1
%/tick
HORIZONTAL

SLIDER
5
555
210
588
PheromoneMaxIntensity
PheromoneMaxIntensity
0
100
50.0
1
1
/ patch
HORIZONTAL

BUTTON
225
720
430
753
Draw Pheromone
drawpheromone
T
1
T
OBSERVER
NIL
M
NIL
NIL
0

MONITOR
225
670
325
715
Total Ants
count ants
0
1
11

SLIDER
5
590
210
623
PheromoneAtFeedingSpots
PheromoneAtFeedingSpots
0
100
100.0
1
1
%
HORIZONTAL

SLIDER
225
390
430
423
PassivePheromoneDiscretion
PassivePheromoneDiscretion
0
1
0.0
0.1
1
%
HORIZONTAL

MONITOR
332
670
427
715
Total Pheromone
totalPheromone
0
1
11

BUTTON
225
560
430
593
Make All Ants Hungry
ask ants [ set eaten false ]
NIL
1
T
OBSERVER
NIL
H
NIL
NIL
0

SWITCH
225
285
430
318
AntsGoHungry
AntsGoHungry
1
1
-1000

SLIDER
225
320
430
353
AntsSatiatedTicks
AntsSatiatedTicks
1
100
50.0
1
1
ticks
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
