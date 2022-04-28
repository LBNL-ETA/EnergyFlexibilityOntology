

###### (Automatically generated documentation)

# Reduce Lighting Loads by Percentage for Specfic Space Type and Time Periods

## Description
This measure adjusts lighting loads by a user-specified percentage and a user-specified time period. This is applied to a specific space type or throughout the entire building.

## Modeler Description
This measure will clone all of the schedules that are used as lighting power setting for each zone. Then the schedules are adjusted by a specified percentage during a specified time period. If the measure is applied throughout the entire building, the reduction value can be separately defined based on whether this space type is occupied or not.

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

### Please fill in the lighting power reduction in No.1-2, if you chose the 'Entire Building'. Otherwise, please fill in the value in No.3.
 1.Lighting Power Reduction for Occupied Spaces (%).

**Name:** occupied_space_type,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### 2.Lighting Power Reduction for Unoccupied Spaces (%).

**Name:** unoccupied_space_type,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### 3.Lighting Power Reduction for the Selected Space Type (%).

**Name:** single_space_type,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Start Time for the Reduction

**Name:** starttime,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### End Time for the Reduction

**Name:** endtime,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false




