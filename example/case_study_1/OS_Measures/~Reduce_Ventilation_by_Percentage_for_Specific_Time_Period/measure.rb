# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2018, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# start the measure
class ReduceVentilationByPercentageAndTimePeriod < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'Reduce Ventilation by Percentage for Specfic Space Type and Time Periods'
  end

  # human readable description
  def description
    return 'This measure adjusts OA Ventilation by a user-specified percentage and a user-specified time period. This is applied to a specific space type or throughout the entire building.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure will clone all of the schedules that are used as OA Ventilation setting for each zone. Then the schedules are adjusted by a specified percentage during a specified time period. If the measure is applied throughout the entire building, the reduction value can be separately defined based on whether this space type is occupied or not.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make a choice argument for model objects
    space_type_handles = OpenStudio::StringVector.new
    space_type_display_names = OpenStudio::StringVector.new

    # putting model object and names into hash
    space_type_args = model.getSpaceTypes
    space_type_args_hash = {}
    space_type_args.each do |space_type_arg|
      space_type_args_hash[space_type_arg.name.to_s] = space_type_arg
    end

    # looping through sorted hash of model objects
    space_type_args_hash.sort.map do |key, value|
      # only include if space type is used in the model
      if !value.spaces.empty?
        space_type_handles << value.handle.to_s
        space_type_display_names << key
      end
    end

    # add building to string vector with space type
    building = model.getBuilding
    space_type_handles << building.handle.to_s
    space_type_display_names << '*Entire Building*'

    # make a choice argument for space type
    space_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('space_type', space_type_handles, space_type_display_names)
    space_type.setDisplayName('Apply the Measure to a Specific Space Type or to the Entire Model.')
    space_type.setDefaultValue('*Entire Building*') 
    args << space_type

    # make an argument for reduction percentage for occupied spaces (if user chose the Entire Building)
    occupied_space_type = OpenStudio::Measure::OSArgument.makeDoubleArgument('occupied_space_type', true)
    occupied_space_type.setDisplayName("Please fill in the Outdoor Air ventilation reduction in No.1-2, if you chose the 'Entire Building'. Otherwise, please fill in the value in No.3.\n 1.OA Ventilation Reduction for Occupied Spaces (%).")
    occupied_space_type.setDefaultValue(30.0)
    args << occupied_space_type
   
    # make an argument for reduction percentage for unoccupied spaces (if user chose the Entire Building)
    unoccupied_space_type = OpenStudio::Measure::OSArgument.makeDoubleArgument('unoccupied_space_type', true)
    unoccupied_space_type.setDisplayName('2.OA Ventilation Reduction for Unoccupied Spaces (%).')
    unoccupied_space_type.setDefaultValue(70.0)
    args << unoccupied_space_type

    # make an argument for reduction percentage for specific space type (if user chose only one space type to apply this measure)
    single_space_type = OpenStudio::Measure::OSArgument.makeDoubleArgument('single_space_type', true)
    single_space_type.setDisplayName('3.OA Ventilation Reduction for the Selected Space Type (%).')
    single_space_type.setDefaultValue(30.0)
    args << single_space_type

    # make an argument for the start time of the reduction
    starttime = OpenStudio::Measure::OSArgument.makeStringArgument('starttime', true)
    starttime.setDisplayName('Start Time for the Reduction')
    starttime.setDefaultValue('13:00:00')
    args << starttime

    # make an argument for the end time of the reduction
    endtime = OpenStudio::Measure::OSArgument.makeStringArgument('endtime', true)
    endtime.setDisplayName('End Time for the Reduction')
    endtime.setDefaultValue('16:00:00')
    args << endtime

    # no cost required to reduce required amount of outdoor air. Cost increase or decrease will relate to system sizing and ongoing energy use due to change in outdoor air provided.

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
    object = runner.getOptionalWorkspaceObjectChoiceValue('space_type', user_arguments, model)
    single_space_type = runner.getDoubleArgumentValue('single_space_type', user_arguments)
    occupied_space_type = runner.getDoubleArgumentValue('occupied_space_type', user_arguments)
    unoccupied_space_type = runner.getDoubleArgumentValue('unoccupied_space_type', user_arguments)
    starttime = runner.getStringArgumentValue('starttime', user_arguments)
    endtime = runner.getStringArgumentValue('endtime', user_arguments)

    # check the OA ventilation reduction percentages and for reasonableness
    if occupied_space_type > 100
      runner.registerError('Please Enter a Value less than or equal to 100 for the OA Ventilation Reduction Percentage.')
      return false
    elsif occupied_space_type == 0
      runner.registerInfo('No OA Ventilation Adjustment Requested.')
    elsif (occupied_space_type < 1) && (occupied_space_type > -1)
      runner.registerWarning("A OA Ventilation Reduction Percentage of #{occupied_space_type} percent is abnormally low.")
    elsif occupied_space_type > 90
      runner.registerWarning("A OA Ventilation Reduction Percentage of #{occupied_space_type} percent is abnormally high.")
    elsif occupied_space_type < 0
      runner.registerInfo('The requested value for OA ventilation reduction percentage was negative. This will result in an increase in OA Ventilation.')
    end

    # check the OA ventilation reduction percentages and for reasonableness
    if unoccupied_space_type > 100
      runner.registerError('Please Enter a Value less than or equal to 100 for the OA Ventilation Reduction Percentage.')
      return false
    elsif unoccupied_space_type == 0
      runner.registerInfo('No OA Ventilation Adjustment Requested.')
    elsif (unoccupied_space_type < 1) && (unoccupied_space_type > -1)
      runner.registerWarning("A OA Ventilation Reduction Percentage of #{unoccupied_space_type} percent is abnormally low.")
    elsif unoccupied_space_type > 90
      runner.registerWarning("A OA Ventilation Reduction Percentage of #{unoccupied_space_type} percent is abnormally high.")
    elsif unoccupied_space_type < 0
      runner.registerInfo('The requested value for OA ventilation reduction percentage was negative. This will result in an increase in OA ventilation.')
    end

    # check the OA ventilation reduction percentages and for reasonableness
    if single_space_type > 100
      runner.registerError('Please Enter a Value less than or equal to 100 for the OA Ventilation Reduction Percentage.')
      return false
    elsif single_space_type == 0
      runner.registerInfo('No OA Ventilation Adjustment Requested.')
    elsif (single_space_type < 1) && (single_space_type > -1)
      runner.registerWarning("A OA Ventilation Reduction Percentage of #{single_space_type} percent is abnormally low.")
    elsif single_space_type > 90
      runner.registerWarning("A OA Ventilation Reduction Percentage of #{single_space_type} percent is abnormally high.")
    elsif single_space_type < 0
      runner.registerInfo('The requested value for OA ventilation reduction percentage was negative. This will result in an increase in OA ventilation.')
    end

    # check the space_type for reasonableness
    if starttime.to_f > endtime.to_f
      runner.registerError('The end time should be larger than the start time.')
      return false
    end

    # check the space_type for reasonableness and see if measure should run on space type or on the entire building
    apply_to_building = false
    space_type = nil
    if object.empty?
      handle = runner.getStringArgumentValue('space_type', user_arguments)
      if handle.empty?
        runner.registerError('No space type was chosen.')
      else
        runner.registerError("The selected space type with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if !object.get.to_SpaceType.empty?
        space_type = object.get.to_SpaceType.get
      elsif !object.get.to_Building.empty?
        apply_to_building = true
      else
        runner.registerError('Script Error - argument not showing up as space type or building.')
        return false
      end
    end

    # helper to make numbers pretty (converts 4125001.25641 to 4,125,001.26 or 4,125,001). The definition be called through this measure.
    def neat_numbers(number, roundto = 2) # round to 0 or 2)
      if roundto == 2
        number = format '%.2f', number
      else
        number = number.round
      end
      # regex to add commas
      number.to_s.reverse.gsub(/([0-9]{3}(?=([0-9])))/, '\\1,').reverse
    end

    # time objects to use in meausre
    time_0 = OpenStudio::Time.new(0, 0, 0, 0)
    time_1 = OpenStudio::Time.new(starttime)
    time_2 = OpenStudio::Time.new(endtime)
    time_3 = OpenStudio::Time.new(0, 24, 0, 0)
    # get space design_spec_outdoor_air_objects objects used in the model
    design_spec_outdoor_air_objects = model.getDesignSpecificationOutdoorAirs
    # TODO: - it would be nice to give ranges for different calculation methods but would take some work.

    # counters needed for measure
    altered_instances = 0

    # reporting initial condition of model
    if !design_spec_outdoor_air_objects.empty?
      runner.registerInitialCondition("The initial model contained #{design_spec_outdoor_air_objects.size} design specification outdoor air objects.")
    else
      runner.registerInitialCondition('The initial model did not contain any design specification outdoor air.')
    end

    # get space types in model
    building = model.building.get
    if apply_to_building
      space_types = model.getSpaceTypes
      affected_area_si = building.floorArea
    else
      space_types = []
      space_types << space_type # only run on a single space type
      affected_area_si = space_type.floorArea
    end

    # split apart any shared uses of design specification outdoor air
    design_spec_outdoor_air_objects.each do |design_spec_outdoor_air_object|
      direct_use_count = design_spec_outdoor_air_object.directUseCount
      next if direct_use_count <= 1
      direct_uses = design_spec_outdoor_air_object.sources
      original_cloned = false

      # adjust count test for direct uses that are component data
      direct_uses.each do |direct_use|
        component_data_source = direct_use.to_ComponentData
        if !component_data_source.empty?
          direct_use_count -= 1
        end
      end
      next if direct_use_count <= 1

      direct_uses.each do |direct_use|
        # clone and hookup design spec OA
        space_type_source = direct_use.to_SpaceType
        if !space_type_source.empty?
          space_type_source = space_type_source.get
          cloned_object = design_spec_outdoor_air_object.clone
          space_type_source.setDesignSpecificationOutdoorAir(cloned_object.to_DesignSpecificationOutdoorAir.get)
          original_cloned = true
        end

        space_source = direct_use.to_Space
        if !space_source.empty?
          space_source = space_source.get
          cloned_object = design_spec_outdoor_air_object.clone
          space_source.setDesignSpecificationOutdoorAir(cloned_object.to_DesignSpecificationOutdoorAir.get)
          original_cloned = true
        end
      end

      # delete the now unused design spec OA
      if original_cloned
        runner.registerInfo("Making shared object #{design_spec_outdoor_air_object.name} unique.")
        design_spec_outdoor_air_object.remove
      end
    end




    # def to alter performance and life cycle costs of objects
    def alter_performance(object, design_spec_outdoor_air_reduction_percent, runner)
      # edit instance based on percentage reduction
      instance = object

      # not checking if fields are empty because these are optional like values for space infiltration are.
      new_outdoor_air_per_person = instance.setOutdoorAirFlowperPerson(instance.outdoorAirFlowperPerson - instance.outdoorAirFlowperPerson * design_spec_outdoor_air_reduction_percent * 0.01)
      new_outdoor_air_per_floor_area = instance.setOutdoorAirFlowperFloorArea(instance.outdoorAirFlowperFloorArea - instance.outdoorAirFlowperFloorArea * design_spec_outdoor_air_reduction_percent * 0.01)
      new_outdoor_air_ach = instance.setOutdoorAirFlowAirChangesperHour(instance.outdoorAirFlowAirChangesperHour - instance.outdoorAirFlowAirChangesperHour * design_spec_outdoor_air_reduction_percent * 0.01)
      new_outdoor_air_rate = instance.setOutdoorAirFlowRate(instance.outdoorAirFlowRate - instance.outdoorAirFlowRate * design_spec_outdoor_air_reduction_percent * 0.01)
    end

    # array of instances to change
    instances_array = []

    # loop through space types
    space_types.each do |space_type|
      if apply_to_building                         # measure will be applied differently to space types, based on whether the space type is occupied
        if !space_type.people.empty?
          design_spec_outdoor_air_reduction_percent = occupied_space_type/100
        else
          design_spec_outdoor_air_reduction_percent = unoccupied_space_type/100
        end
        runner.registerInitialCondition(" OA Ventilation will be reduced by #{occupied_space_type}% in occupied spaces, and reduced by #{unoccupied_space_type}% in unoccupied spaces")
      else
        design_spec_outdoor_air_reduction_percent = single_space_type/100      # measure will be applied evenly to all zones
        runner.registerInitialCondition(" OA Ventilation will be reduced by #{single_space_type}% to '#{space_type.name}'.")
      end


      next if space_type.spaces.size <= 0
      instances_array << space_type.designSpecificationOutdoorAir

    # get spaces in model
    if apply_to_building
      spaces = model.getSpaces
    else
      if !space_type.spaces.empty?
        spaces = space_type.spaces # only run on a single space type
      end
    end

    spaces.each do |space|
      instances_array << space.designSpecificationOutdoorAir
    end

    instance_processed = []

    instances_array.each do |instance|
      next if instance.empty?
      instance = instance.get

      # only continue if this instance has not been processed yet
      next if instance_processed.include? instance
      instance_processed << instance

      schedules = []
      schedule_args = model.getScheduleRulesets
      schedule_args.each do |schedule_arg|
      if schedule_arg.name.to_s == "OfficeMedium INFIL_Door_Opening_SCH"
         schedules << schedule_arg
      end
      end

      schedules.each do |oldschedule|
      new_schedule = oldschedule.clone(model)
      new_schedule = new_schedule.to_Schedule.get
      new_schedule_name = new_schedule.setName("#{new_schedule.name} adjusted by #{space_type.name}")
      instance.setOutdoorAirFlowRateFractionSchedule(new_schedule)

      schedule = new_schedule.to_ScheduleRuleset.get
      profiles = []
      # push default profiles to array
      default_rule = schedule.defaultDaySchedule
      profiles << default_rule

      # push profiles to array
      rules = schedule.scheduleRules
      rules.each do |rule|
        day_sch = rule.daySchedule
        profiles << day_sch
      end

      # add design days to array
      summer_design = schedule.summerDesignDaySchedule
      winter_design = schedule.winterDesignDaySchedule
      profiles << summer_design
      profiles << winter_design

    # edit profiles
      profiles.each do |day_sch|
        times = day_sch.times
        values = day_sch.values

        new_values_1 = 1 - design_spec_outdoor_air_reduction_percent
        # clear values
        day_sch.clearValues

        # make new values
        day_sch.addValue(time_1, 1 )
        day_sch.addValue(time_2,new_values_1)
        day_sch.addValue(time_3, 1 )
      end
      end
      # call def to alter performance and life cycle costs
      alter_performance(instance, design_spec_outdoor_air_reduction_percent, runner)

      # rename
      updated_instance_name = instance.setName("#{instance.name} (#{design_spec_outdoor_air_reduction_percent} percent reduction)")
      altered_instances += 1
    end

    if altered_instances == 0
      runner.registerAsNotApplicable('No design specification outdoor air objects were found in the specified space type(s).')
    end
  end

    # time objects to use in meausre
    time_0 = OpenStudio::Time.new(0, 0, 0, 0)
    time_1 = OpenStudio::Time.new(starttime)
    time_2 = OpenStudio::Time.new(endtime)

    # report final condition
    affected_area_ip = OpenStudio.convert(affected_area_si, 'm^2', 'ft^2').get
    runner.registerFinalCondition("#{altered_instances} design specification outdoor air objects in the model were altered affecting #{neat_numbers(affected_area_ip, 0)}(ft^2), from #{time_1} to #{time_2}.")

    return true
  end
end

# this allows the measure to be use by the application
ReduceVentilationByPercentageAndTimePeriod.new.registerWithApplication
