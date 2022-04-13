

###### (Automatically generated documentation)

# Pre Cooling & Heating by Certain Time Period and Thermostat Setpoint

## Description
This measure adjusts cooling and heating schedules by a user specified number of degrees and time period. This is applied throughout the entire building.

## Modeler Description
This measure will clone all of the schedules that are used as heating and cooling setpoints for thermal zones. The clones are hooked up to the thermostat in place of the original schedules. Then the schedules are adjusted by the specified values. HVAC operation schedule will also be changed if the start time of the pre-cooling/heating is earlier than the default start value. There is a checkbox to determine if the thermostat for design days should be altered.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Degrees Fahrenheit to Adjust Cooling Setpoint By

**Name:** cooling_adjustment,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Degrees Fahrenheit to Adjust heating Setpoint By

**Name:** heating_adjustment,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Start Time for Pre-cooling/heating

**Name:** starttime,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### End Time for Pre-cooling/heating

**Name:** endtime,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Alter Design Day Thermostats

**Name:** alter_design_days,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




