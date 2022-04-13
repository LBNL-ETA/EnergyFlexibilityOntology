# *** Copyright Notice ***

# OS Measures Copyright (c) 2021, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any required
#   approvals from the U.S. Dept. of Energy). All rights reserved.

# If you have questions about your rights to use or distribute this software,
# please contact Berkeley Lab's Innovation & Partnerships Office at  IPO@lbl.gov.

# NOTICE.  This Software was developed under funding from the U.S. Department of
# Energy and the U.S. Governmen```````````````t consequently retains certain rights. As such,
# the U.S. Government has been granted for itself and others acting on its behalf
# a paid-up, nonexclusive, irrevocable, worldwide license in the Software to
# reproduce, distribute copies to the public, prepare derivative works, and
# perform publicly and display publicly, and to permit other to do so.

# start the measure
class DynamicDR < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Dynamic DR'
  end

  # human readable description
  def description
    return 'This measure implements demand flexibility measures, including lighting, plugloads, cooling, and heating, for Summer, Winter, and All year. Lighting and plugloads measures are applicable in all three scenarios, while cooling and heating are applicable only in the Summer scenario and Winter scenario, respectively.In the Summer scenario, as for example, four individual flexibility strategies, which are applied during the DR event hours of 3-7 PM include 1) lighting dimming, 2) plug load reduction through low-priority device switching, 3) global temperature adjustment (GTA), and 4) GTA + pre-cooling. The reductions are generated using a continuous uniform dbutions bounded from 0 to 100%, adjustment settings for GTA and pre-cooling are generated using a discrete uniform distribution; GTA cooling set point increases during the DR period are sampled between the range of 1F and 6F, while pre-cooling set point decreases are sampled between the range of 1F and 4F with the duration from 1 hour to 8 hours prior to the DR event start. The adjustments are applied on the baseline hourly settings using a Compact:Schedule to maintain the same Design Days settings as those in the baseline.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'File:measure.rb, resources/original_schedule.csv, resources/ScheduleGenerator.rb. There are two steps to implement the measure. First, a modeler generates an hourly baseline schedule of the interest by running the model. A previously generated schedule is also available in the resources/original_schedule.csv. The selected schedules are available for three building types (medium office detailed, large office detailed, and retail stand alone) in two vintages (post-1980 and 2010) and a big box retail model in 2010 vintage. The big box retail model is only available in an EnergyPlus model, which this measure is not applicable. Second, a modeler loads the model and runs the measure by selecting "Apply Measure Now" under the menu "Components & Measure" in the top bar of OpenStudio GUI. The measure is located under "Whole Building" >> "Whole Building Schedules".'
  end

# define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    bldgType = OpenStudio::StringVector.new
    bldgType << 'Large Office Detailed'
    bldgType << 'Medium Office Detailed'
    bldgType << 'Retail Standalone'
    bldgType << 'Big Box Retail'
    buildingType = OpenStudio::Ruleset::OSArgument.makeChoiceArgument('buildingType', bldgType, true)
    buildingType.setDisplayName('Select the building type')
    buildingType.setDefaultValue('Retail Standalone')
    args << buildingType


    # make an argument for control_type
    vint = OpenStudio::StringVector.new
    vint << 'Post-1980'
    vint << '2010'
    vintage = OpenStudio::Ruleset::OSArgument.makeChoiceArgument('vintage', vint, true)
    vintage.setDisplayName('Select the vintage')
    vintage.setDefaultValue('2010')
    args << vintage

    # make an argument for control_type
    period = OpenStudio::StringVector.new
    period << 'All year'
    period << 'Summer'
    period << 'Winter'
    drPeriod = OpenStudio::Ruleset::OSArgument.makeChoiceArgument('drPeriod', period, true)
    drPeriod.setDisplayName('Select the period')
    drPeriod.setDefaultValue('All year')
    args << drPeriod


    # make an argument for control_type
    drtyp = OpenStudio::StringVector.new
    drtyp << 'Lighting'
    drtyp << 'Plug loads'
    drtyp << 'Summer GTA'
    drtyp << 'Pre-cool and Summer GTA'
    drtyp << 'Winter GTA'
    drtyp << 'Pre-heat and Winter GTA'
    drType = OpenStudio::Ruleset::OSArgument.makeChoiceArgument('drType', drtyp, true)
    drType.setDisplayName('Select the demand response type')
    drType.setDefaultValue('Lighting')
    args << drType

    # populate choice argument for schedules in the model
    sch_handles = OpenStudio::StringVector.new
    sch_display_names = OpenStudio::StringVector.new

    # putting schedule names into hash
    sch_hash = {}
    model.getSchedules.each do |sch|
      sch_hash[sch.name.to_s] = sch
    end

    # looping through sorted hash of schedules
    sch_hash.sort.map do |sch_name, sch|
      if !sch.scheduleTypeLimits.empty?
        unitType = sch.scheduleTypeLimits.get.unitType
        puts "#{sch.name}, #{unitType}"
        # if unitType == 'Temperature'
        sch_handles << sch.handle.to_s
        sch_display_names << sch_name
        # end
      end
    end

    # add empty handle to string vector with schedules
    sch_handles << OpenStudio.toUUID('').to_s
    sch_display_names << '*No Change*'

    # make an argument for cooling schedule
    schedule_old = OpenStudio::Measure::OSArgument.makeChoiceArgument('schedule_old', sch_handles, sch_display_names, true)
    schedule_old.setDisplayName('Choose a schedule to be replaced.')
    schedule_old.setDefaultValue('*No Change*') # if no change is chosen then cooling schedules will not be changed
    args << schedule_old

    usepredefined = OpenStudio::Measure::OSArgument.makeBoolArgument('usepredefined', true)
    usepredefined.setDisplayName('Use pre-defined schedule?')
    usepredefined.setDefaultValue(true)
    args << usepredefined


    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    buildingType = runner.getStringArgumentValue('buildingType', user_arguments)
    vintage = runner.getStringArgumentValue('vintage', user_arguments)
    drType = runner.getStringArgumentValue('drType', user_arguments)
    drPeriod = runner.getStringArgumentValue('drPeriod', user_arguments)
    schedule_old = runner.getOptionalWorkspaceObjectChoiceValue('schedule_old', user_arguments, model)
    usepredefined = runner.getBoolArgumentValue('usepredefined', user_arguments)
    # schedule_new = runner.getOptionalWorkspaceObjectChoiceValue('schedule_new', user_arguments, model)

    bl_m = {"Large Office Detailed" => "largeofficedetailed",
            "Medium Office Detailed" => "mediumofficedetailed",
            "Retail Standalone" => "retail",
            "Big Box Retail" => "bbr"}

    vt_m = {"Post-1980" => "p1980", "2010" => "2010"}
    dr_m = {"Lighting" => "lighting", "Plug loads" => "plugloads",
              "Summer GTA" => "summer_gta", "Pre-cool and Summer GTA" => "summer_precool",
              "Winter GTA" => "winter_gta", "Pre-heat and Winter GTA" => "winter_preheat"}
    dp_m = {"All year" => "allyear", "Summer" => "summer", "Winter" => "winter"}

    root_path = File.dirname(__FILE__) + '/resources/'

    #### generate a new schedule ####
    runner.registerInfo("Generate the new schedule")

    load root_path + 'ScheduleGenerator.rb'
    schedGen = ScheduleGenerator.new(bl_m[buildingType], vt_m[vintage], dr_m[drType], dp_m[drPeriod], usepredefined)
    runner.registerInfo("The schedule model is created.")
    
    #### add the schedule objects to the model ####
    runner.registerInfo("The the schedule objects to the original model")
    model2 = OpenStudio::Model::Model.load(OpenStudio::Path.new(root_path + "out_compact_schedule.osm")).get
    runner.registerInfo("The model has #{model2.modelObjects.size} objects")
    if model2.modelObjects.size > 0
      model2.modelObjects.each {|o| o.clone(model)}
      runner.registerInfo("There are '#{model2.modelObjects.size}' objects in the model")
    end

    schedule_new_name = model2.getSchedules[0].name.get
    runner.registerInfo("The schedule model '#{schedule_new_name}' is added to the original model.")

    #### replace the old schedule with a new one ####
    runner.registerInfo("The the original schedule with the new schedule")
    if schedule_old.empty?
      handle = runner.getStringArgumentValue('schedule_old', user_arguments)
      if handle == OpenStudio.toUUID('').to_s
        # no change
        schedule_old = nil
      else
        runner.registerError("The selected schedule with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
        return false
      end
    else
      if !schedule_old.get.to_Schedule.empty?
        schedule_old = schedule_old.get.to_Schedule.get
      else
        runner.registerError('Script Error - argument not showing up as schedule.')
        return false
      end
    end

    ### retrieve the new schedule after being imported into the model
    schedule_new = model.getScheduleByName(schedule_new_name).get

    schedule_old.sources.each do |source|
      source_index = source.getSourceIndices(schedule_old.handle)
      source_index.each do |field|
        source.setPointer(field, schedule_new.handle)
      end
    end
    schedule_old_name = schedule_old.name.get
    schedule_old.remove
    
    runner.registerInfo("The original schedule '#{schedule_old_name}' with the new schedule '#{schedule_new.name.get}'")
    schedule_new.setName(schedule_old_name)


    runner.registerInitialCondition("The building with original schedule '#{schedule_old_name}'.")
    runner.registerFinalCondition("The building with updated schedule '#{schedule_new.name.get}'.")

    return true
  end
end

# register the measure to be used by the application
DynamicDR.new.registerWithApplication
