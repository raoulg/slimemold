globals [ showPheromone showAnts showFood totalPheromone ] ; Self-Explanatory
breed [ ants ant ] ; Ants
breed [ foods food ] ; Food
patches-own [ pheromone foodhere ]
ants-own [ eaten blessed ]

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

  ; should be self explanatory
  create-foods feedingspots [
    set shape "circle"
    set color orange
    set size (feedingspotradius * 2)
    setxy random-xcor random-ycor
    ; put actual food on feedingspots
    ask patches in-radius feedingspotradius [ set foodhere true ]
  ]

  ; populate the world with ants
  repeat (count patches) [
    let pxp (WorldSize / 2) ; Patch x preference. Default centre
    let pyp (WorldSize / 2) ; Patch y preference. Default centre
    let pap false ; Patch allow preference
    ask one-of patches [
      ; according to the requirements, adding ants had to be a stochastic process
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
        ; if AntStartingPositon is equal to center, do nothing because pxp pyp default to centre
        set pap true
      ]
    ]
    ; using a boolean workaround because ants cannot be created within ask patches environment
    if pap = true [
      create-ants 1 [
        set color red  ; ants default to hungry as shown with the color red
        set eaten 0
        set shape "circle"
        ; Using simple form to speed up computations.
        ; Who is interested in ant-like shape while simulation a slimemold, anyway.
        setxy pxp pyp
        set blessed false
      ]
    ]
  ]

  ; Without feedingspots, the ants will never develop even the faintest interesting behaviour.
  ; Nobody is interested in blessed to be false under this condition
  ; Ok, almost nobody (https://www.youtube.com/watch?v=z7VYVjR_nwE)
  if (feedingspots = 0) [ ask ants [ set blessed true ] ]

  reset-ticks
end

to step
  ; Add pheromone at feedingspots
  addFoodAtSpots
  ; control antbehaviour
  controlAnts
  ; Diffuse pheromones
  diffuse pheromone (PheromoneDiffusionRate / 100)

  ; Pheromone Dissapation/Evaporation
  set totalPheromone 0
  ask patches [
    set pheromone (pheromone * (1 - 1 / PheromoneEvaporationRate))
    if not (showPheromone = false) [ set pcolor scale-color PheromoneColor pheromone 0 (PheromoneMaxIntensity * (PheromoneContrast / 100)) ]
    if not (foodhere = true) [
      if pheromone > PheromoneMaxIntensity [ set pheromone PheromoneMaxIntensity ]
      set totalPheromone (totalPheromone + pheromone)
    ]
  ]

  ; Update pheromone contrast
  if AutomaticPheromoneContrast [
    set PheromoneContrast (precision (totalPheromone / 1000 * 2) 1)
    ;set PheromoneContrast (precision ((totalPheromone - count foods * (PheromoneMaxIntensity * (PheromoneAtFeedingSpots / 100))) / 1000 * 0.75) 1)
    if PheromoneContrast < 1 [ set PheromoneContrast 1 ]
    if PheromoneContrast > 200 [ set PheromoneContrast 200 ]
  ]

  ; Tick
  tick
end

to addFoodAtSpots
    if (pheromoneAtFeedingSpots > 0) [
    ask foods [
      ask patches in-radius feedingspotradius [
        ; keep adding pheromone against diffusion
        set pheromone (pheromone + pheromoneMaxIntensity * (pheromoneAtFeedingSpots / 100))
      ]
    ]
  ]
end

to controlAnts
    ; Ant Behaviour
  ask ants [
    ; Eat from foodsource
    letAntsEat

    ; Change of death
    dieMaybe

    ; let ants move in response to sensing environment
    antMotorControl

    ; Dump pheromone
    dumpPheromones
  ]

end

to dumpPheromones
      if (blessed = true ) [
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
end

to letAntsEat
      if (count foods in-radius (FeedingSpotRadius + 0.5) > 0) [
      set eaten AntsSatiatedTicks
      set blessed true
    ]
end

to dieMaybe
     if (random-float 100 < ChanceOfDeath) [
      die
    ]
end

to antMotorControl
      ; Sense your surroundings
    let sensedpheromone [ 0 0 ]
    ; update with direction (at item 0) of highest amount of pheromone (at item 1):
    ;   0 left
    ;   1 forward
    ;   2 right
    ;   3 don't move
    set sensedpheromone ant-sense
    ; turn left if appropriate
    if (item 0 sensedpheromone) = 0 [
      left RotationAngle
    ]
    ; turn right if appropriate
    if (item 0 sensedpheromone) = 2 [
      right RotationAngle
    ]
    ; If possible, move in the direction the ant is now facing
    if not ((item 0 sensedpheromone) = 3) [
      forward AntStepSize
    ]
end

; Ants be sensing
to-report ant-sense
  ; item 0 stores direction
  ;   0 left
  ;   1 forward
  ;   2 right
  ;   3 don't move
  ; item 1 stores amount of pheromone

  let sensedpheromone [ 3 0 ] ; default to don't move, no pheromone

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
      ; set direction forward (1) and store pheromone
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
      ; replace pheromone with left value if there is more at the left than ahead
      ; and set direction to left (0)
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
        ; if there is more to the right than left or forward,
        ; replace amount and set direction to the right (2)
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

to AntsBeBlessed
  ask ants [
    set blessed true
  ]
end

to FindSteinerTrees
  set FeedingSpotRadius 3
  set pheromoneDepositRatio 50
  set pheromoneAtFeedingSpots 60
  set PheromoneEvaporationRate 25
  set PheromoneDiffusionRate 90
  set AntsGoHungry true
  set PassivePheromoneDiscretion 0
  set CoverageRate 15
  set AntStartingPosition "Spread Out"
end
@#$#@#$#@
GRAPHICS-WINDOW
445
25
918
499
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
154
0
154
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
154.0
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
8.0
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
3.0
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
0
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
0.05
0.05
0.001
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
1000.0
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
Massacre Ants
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
50.0
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
1
100
25.0
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
1
100
75.0
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
60.0
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
10
0.0
0.1
1
%
HORIZONTAL

MONITOR
332
670
432
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
ask ants [ set eaten 0 ]
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
0
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
100.0
1
1
ticks
HORIZONTAL

BUTTON
10
670
205
703
AntsBeBlessed
AntsBeBlessed
NIL
1
T
OBSERVER
NIL
B
NIL
NIL
1

BUTTON
10
715
205
748
FindSteinerTrees
FindSteinerTrees
NIL
1
T
OBSERVER
NIL
\
NIL
NIL
1

TEXTBOX
10
635
160
653
Extra features
11
0.0
1

@#$#@#$#@
# Model
This model shows a slime mould behaving according to [a paper by Jeff Jones](https://link.springer.com/article/10.1007/s11047-010-9223-z). It uses so-called 'ants' and there pheromone to mimic the behaviour of the Physarum polycephalum slime mould.

## Ants
The ants are one of three main components in this model. The little critters are identified by their bug shape, yet unlike their shape suggests they use three sensors to sense pheromone. One of these sensors is straight in front of them, at a distance called 'Sensor Offset' (SO). The other two are angled to the right and left at the angle 'Sensor Angle' (SA).
Their movement is very simplistic. They move forward with a distance defined distance. However, before they take a step, they use their sensors to sense pheromone. The ant then turns towards the sensor sensing the most pheromone, with an angle defined as 'Rotation Angle' (RA). 
*Say the leftmost sensor picked up the most pheromone, the ant will turn left with RA and then take it's step forward.*
Ants are also the formost source of the pheromone. Once they've eaten from a foodsource they'll start discreting it at a defined rate. To be precise: they eat, move, and finally discrete. By default, ants don't go hungry and will continue discreting pheromone until the simulation is reset.

## Foodsources
The foodsources are little nodes with a defined radius at which ants can eat. By default they also discrete pheromone to help the ants find their way. Foodsources are infinitely stocked with food.

# Interface
The following section will go through all the interface elements by their respective groups, left-to-right, and downwards.

## Simulation Controls
### Setup Button (X)
The setup buttons allows for preparing the simulation to run. It clears all variables and reset the tick counter. It also creates the feeding spots and the base population of ants.

### Step Button (S)
This button allows the user to step through the simulation one tick at the time. It use is limited, because interesting behaviour only shows after a while.

### Go Button (G)
The go buttons will run the simulation tick for tick, continuosly until it is pressed again.

## World Controls
### WorldSize Slider
This slider dictates the width and height of the world in patches. (It is always square.) Changes to this slider only take effect after pressing the Setup Button (S) again. The maximum of this slider is dictated by the PatchSize slider.

### PatchSize Slider
This slider dictates the width and height of each patch in the world in pixels. (They're always square.) This slider also inversely dictates the maximum world size (the maximum of the WorldSize slider.)

### FeedingSpots Slider
This slider dictates the amount of feeding spots to spawn when the Setup Button is pressed. It's maximum is a thousanth of amount of patches present (which is the World Size squared).

### FeedingSpotRadius Slider
This slider dictates the radius of the feeding spots.

### Toggle Feeding Spot Visibility Button (F)
This button, as it's name suggests, toggles wether or not feeding spots are shown in the world. Even if they're not shown they'll still be placed and they'll also still operate as normal. Toggling feedingspot visiblity won't influence performance.

## Pheromone Controls
### PheromoneColor Input
This chooser allows to pick a base color for the pheromone. Please note that the pheromone color is scaled based on the amount of pheromone on a patch, so it might appear darker or lighter than the color chosen.

### AutomaticPheromoneContrast Switch
This switch allows enabling and disabling automatic control of the PheromoneContrast slider based on the amount of pheromone in the world. This automation works best with the pheromone spread out over the world (read, not early in the simulation).

### PheromoneContrast Slider
The pheromone contrast slider controls (somewhat) how strongly the pheromone changes color based on the amount of pheromone on a patch. A higher percentage will create generally darker pheromone and a lower will generally increase the brightness.

### Toggle Pheromone Visiblity Button (P)
As the name suggests, this button toggles wether or not the pheromone is visible. As with the other 'Toggle Visiblity' buttons, the pheromone is not disabled, only invisible. Disabling pheromone visiblity may slightly up performance, but strongly decrease the fun of watching the simulation.

### PheromoneDepositRatio Slider
This slider dictates the amount of pheromone a satiated ant dumps per tick. It is in percentages of the maximum intensity of pheromone per patch.

### PheromoneEvaporationRate Slider
This slider dictates how long it should take for pheromone to completely evaporate from a tile (if no new pheromone is added), in ticks.

### PheromoneDiffusionRate Slider
This slider dictates how much the pheromone diffuses per tick. The lower this percentage is, the further the pheromone will spread.

### PheromoneMaxIntensity Slider
This slider sets the maximum amount of pheromone per patch.

### PheromoneAtFeedingSpots Slider
This slider dictates the amount of pheromone the feeding spots discrete each tick. It is a percentage of the maximum amount of pheromone allowed per patch.

## Ant Controls
### CoverageRate Slider
This slider dictates the amount of ants to spawn when the Setup Button (X) is pressed. To be precises it dictates the change for each patch to spawn an ant on setup.

### AntStartingPosition Chooser
This chooser allows for different starting position of ants when the Setup Button (X) is pressed. It has three options:
#### Center
All ants start in the center of the world. (May make the simulation slow to start off on bigger worlds.)
#### Spread Out
Spreads out the ants randomly accross the world.
#### On Feeding Spots
Starts all ants randomly distributed accross all feeding spots.

### AntStepSize Slider
As the name suggest this slider controls the amount of patches an ant moves forward each tick.

### SensorOffset Slider
As explained in the Model section of this documentation, this slider dictates the distance between the ant and its three pheromone receptors.

### SensorAngle Slider
Also explained in the Model section of this documentation, this slider controls the angle of the left and right pheromone receptors, from the middle one.

### RotationAngle Slider
Also explained in the Model section of this documentation, this slider controls the rotation an ant will make towards the left or right if it senses the most pheromone with respectively its left or right sensors.

### AntsMayShareLocation Switch
As the name suggests this switch toggles wether or not ants may move to a spot occupied by another ant.

### AntsGoHungry Switch
This slider toggles wether or not ants will go hungry again after a certain amount of time after eating. Going hungry means they stop discreting pheromone.

### AntsSatiatedTicks Slider
This slider dictates for how long ants will be satiated when the AntsGoHungry switch is turned on.

### ChanceOfDeath Slider
This slider dictates - again, as the name suggest - the chance for an ant to die each tick. Note that even at fairly low rates the ants die swiftly, so the maximum chance is with 0.05 % still more than high enough. If you would want to kill huge amounts of ants, check the 'Playing For God' controls, more precisely 'Massacre Ants'

### PassivePheromoneDiscretion Slider
This slider dictates how much an ant (hungry or satiated) will discrete by default each tick. It's defined in a percentage value over the maximum pheromone per patch. The paper of Jones (2011) suggests that this feature models the "flux of internal protoplasm". This slider generates self-organising network structures, even without food.

### Toggle Ant Visibility Button (T)
This button toggles the showing of ants (original and new). Its actual influence on performance is minimal, however without all the crawling ants, it does *feel* somewhat smoother, and is much more pleasant to look at.

## Playing For God
### Redistribute Ants Button (R)
This button will spread out all ants accross the world randomly when pressed.

### Clear Pheromone Button (C)
This button will clear all pheromone from the world when pressed.

### Redistrube Ants & Clear Pheromone Button (&)
This button - as the name suggests - will spread out all the ants over the world randomly and clear all pheromone from the world, when pressed.

### Make All Ants Hungry Button (H)
This button will set all ants to their default 'hungry' state, in which they don't discrete any pheromone.

### AntsToModify Input
This input allows for setting the amount of ants to add or remove when pressing the Add Ants (A) and Remove Ants (D) buttons.

### Add Ants Button (A)
This button allows for adding new ants to the world. The amount of ants added is dictated by the AntsToModify Input.

### Massacre Ants Button (D)
_[You monster!](https://www.youtube.com/watch?v=Yy3dIicSI_0)_  
This buttons allows for kill ants in humongous amounts. The amount of ants added is dictated by the AntsToModify input, as long as it isn't over the current amount of alive ants (if it is, it will do that amount instead).

### Total Ants Monitor
This monitor shows the amount of alive ants currently in the world.

### Total Pheromone Monitor
This monitor shows the total maount of pheromone currently in the world.

### Draw Pheromone Button (M)
When activated, this button allows for drawing little puffs of pheromone in the world by clicking (and dragging).

## View
Exists solely of the view showing the described world/simulation.

# License
SlimeMold.nlogo Copyright (C) 2018  Raoul Grouls & Simon van Hus
This program comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to redistribute it
under certain conditions.
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
