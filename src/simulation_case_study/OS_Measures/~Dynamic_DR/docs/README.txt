

###### (Automatically generated documentation)

# DR Compact Schedule

## Description
This measure implements demand flexibility measures, including lighting, plugloads, cooling, and heating, for Summer, Winter, and All year. Lighting and plugloads measures are applicable in all three scenarios, while cooling and heating are applicable only in the Summer scenario and Winter scenario, respectively.In the Summer scenario, as for example, four individual flexibility strategies, which are applied during the DR event hours of 3-7 PM include 1) lighting dimming, 2) plug load reduction through low-priority device switching, 3) global temperature adjustment (GTA), and 4) GTA + pre-cooling. The reductions are generated using a continuous uniform dbutions bounded from 0 to 100%, adjustment settings for GTA and pre-cooling are generated using a discrete uniform distribution; GTA cooling set point increases during the DR period are sampled between the range of 1F and 6F, while pre-cooling set point decreases are sampled between the range of 1F and 4F with the duration from 1 hour to 8 hours prior to the DR event start. The adjustments are applied on the baseline hourly settings using a Compact:Schedule to maintain the same Design Days settings as those in the baseline.

## Modeler Description
Files:
- measure.rb,
- resources/my_schedule.csv, 
- resources/original_schedule.csv, 
- resources/ScheduleGenerator.rb. 

There are three steps to implement the measure. 
First, a modeler needs to prepare an hourly schedule before the adjustment. There are two ways to prepare the schedule. 
  - A modeler can generate an hourly baseline schedule of the interest by running the model. You can utilize "Add Output Variable" and "Export Variables to CSV" measures that are available on the Building Component Library website (bcl.nrel.gov). ####NOTE: make sure you disable the Daylight Saving Time when you run the model. The schedule is then copied and pasted into resources/my_schedule.csv. 
  - For convenience, a previously generated schedule is also available in the resources/original_schedule.csv. The selected schedules are available for three building types (medium office detailed, large office detailed, and retail stand alone) in two vintages (post-1980 and 2010) and a big box retail model in 2010 vintage. The big box retail model is only available in an EnergyPlus model, which this measure is not applicable.

Second, a modeler loads the model and runs the measure by selecting "Apply Measure Now" under the menu "Components & Measure" in the top bar of OpenStudio GUI. The measure is located under "Whole Building" >> "Whole Building Schedules".
  - Enter the information from drop-down boxes.
  - Note: Make sure a correct schedule is selected under the drop-down menu of "Choose a schedule to be replaced". The schedule should corresponds to the type of DR.

Finally, after the measure is successfully applied, a modeler can run the model. The Daylight Saving Time also needs to be disabled.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Select the building type

**Name:** buildingType,
**Type:** Large Office Detailed,Medium Office Detailed,Retail Standalone, Big Box Retail
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Select the vintage

**Name:** vintage,
**Type:** Post-1980,2010
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Select the period

**Name:** drPeriod,
**Type:** All year, Summer, Winter
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Select the demand response type

**Name:** drType,
**Type:** Lighting, Plug loads, Summer GTA, Pre-cool and Summer GTA, Winter GTA, Pre-heat and Winter GTA,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Choose a schedule to be replaced.

**Name:** schedule_old,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Use pre-defined schedule ?

**Name:** usepredefined,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




