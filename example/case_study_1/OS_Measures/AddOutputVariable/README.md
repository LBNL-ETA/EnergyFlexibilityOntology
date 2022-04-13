

###### (Automatically generated documentation)

# Add Output Variable

## Description
This measure adds an output variable at the requested reporting frequency.

## Modeler Description
The measure just passes in the string and does not validate that it is a proper variable name. It is up to the user to know this or to look at the .rdd file from a previous simulation run.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Enter Variable Name

**Name:** variable_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Reporting Frequency

**Name:** reporting_frequency,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Enter Key Name
Enter * for all objects or the full name of a specific object to.
**Name:** key_value,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false




