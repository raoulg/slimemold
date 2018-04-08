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
As the name suggests, this button toggles wether or not the pheromone is visible. As with the other 'Toggle Visiblity' buttons, the pheromone is not disabled, only invisible. Disabling pheromone visiblity may slightly up performance, but strongly decrease interest.

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
This slider dictates - again, as the name suggest - the chance for an ant to die each tick. Note that it's minimum (0.01%) is probably high enough.

### PassivePheromoneDiscretion Slider
This slider dictates how much an ant (hungry or satiated) will discrete by default each tick. It's defined in a percentage value over the maximum pheromone per patch. (Normally this is off: at 0%)

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

### Remove Ants Button (D)
_[You monster!](https://www.youtube.com/watch?v=Yy3dIicSI_0)_  
This buttons allows for removing ants from the world. The amount of ants added is dictated by the AntsToModify input, as long as it isn't over the current amount of alive ants (if it is, it will do that amount instead).

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
This program comes with ABSOLUTELY NO WARRANTY; for details type \`show w'.
This is free software, and you are welcome to redistribute it
under certain conditions; type \`show c' for details.
