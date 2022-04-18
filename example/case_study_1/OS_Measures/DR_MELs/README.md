

###### (Automatically generated documentation)

# DR MELs

## Description
This measure adjusts electric equipment loads by a user-specified percentage and a user-specified time period. This is applied to a specific space type or throughout the entire building.

## Modeler Description
This measure will clone all of the schedules that are used as electric equipment power setting for each zone. Then the schedules are adjusted by a specified percentage during a specified time period. If the measure is applied throughout the entire building, the reduction value can be separately defined based on whether this space type is occupied or not.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Apply the Measure to a Specific Space Type or to the Entire Model.

**Name:** space_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Please fill in the equipment loads reduction in No.1-2, if you chose the 'Entire Building'. Otherwise, please fill in the value in No.3.
 1.Electric Equipment Loads Reduction for occupied spaces (%).

**Name:** occupied_space_type,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### 2.Electric Equipment Loads Reduction for unoccupied spaces (%).

**Name:** unoccupied_space_type,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### 3.Electric Equipment Loads Reduction for the selected space type (%).

**Name:** single_space_type,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Start Time for the Reduction

**Name:** starttime_winter2,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### End Time for the Reduction

**Name:** endtime_winter2,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Start Time for the Reduction

**Name:** starttime_winter1,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### End Time for the Reduction

**Name:** endtime_winter1,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Start Time for the Reduction during the Special Schedule

**Name:** starttime_summer,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### End Time for the Reduction during the Special Schedule

**Name:** endtime_summer,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Enable Climate-specific Periods Setting ?

**Name:** auto_date,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




