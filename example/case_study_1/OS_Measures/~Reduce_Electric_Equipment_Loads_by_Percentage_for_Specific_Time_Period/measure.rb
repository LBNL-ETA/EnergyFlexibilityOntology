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

# start the measure
class ReduceElectricEquipmentLoadsByPercentageAndTimePeriod < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see
  def name
    return 'Reduce Electric Equipment Loads by Percentage for Specific Space Type and Time Periods'
  end

  # human readable description
  def description
    return 'This measure adjusts electric equipment loads by a user-specified percentage and a user-specified time period. This is applied to a specific space type or throughout the entire building.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure will clone all of the schedules that are used as electric equipment power setting for each zone. Then the schedules are adjusted by a specified percentage during a specified time period. If the measure is applied throughout the entire building, the reduction value can be separately defined based on whether this space type is occupied or not.'
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
    space_type.setDefaultValue('*Entire Building*') # if no space type is chosen this will run on the entire building
    args << space_type

    # make an argument for reduction percentage
    occupied_space_type = OpenStudio::Measure::OSArgument.makeDoubleArgument('occupied_space_type', true)
    occupied_space_type.setDisplayName("Please fill in the equipment loads reduction in No.1-2, if you chose the 'Entire Building'. Otherwise, please fill in the value in No.3.\n 1.Electric Equipment Loads Reduction for occupied spaces (%).")
    occupied_space_type.setDefaultValue(20.0)
    args << occupied_space_type
   
    # make an argument for reduction percentage
    unoccupied_space_type = OpenStudio::Measure::OSArgument.makeDoubleArgument('unoccupied_space_type', true)
    unoccupied_space_type.setDisplayName('2.Electric Equipment Loads Reduction for unoccupied spaces (%).')
    unoccupied_space_type.setDefaultValue(50.0)
    args << unoccupied_space_type

    # make an argument for reduction percentage
    single_space_type = OpenStudio::Measure::OSArgument.makeDoubleArgument('single_space_type', true)
    single_space_type.setDisplayName('3.Electric Equipment Loads Reduction for the selected space type (%).')
    single_space_type.setDefaultValue(20.0)
    args << single_space_type

    # make an argument for the start time of the reduction
    starttime = OpenStudio::Measure::OSArgument.makeStringArgument('starttime', true)
    starttime.setDisplayName('Start Time for the Reduction')
    starttime.setDefaultValue('15:00:00')
    args << starttime

    # make an argument for the end time of the reduction
    endtime = OpenStudio::Measure::OSArgument.makeStringArgument('endtime', true)
    endtime.setDisplayName('End Time for the Reduction')
    endtime.setDefaultValue('18:00:00')
    args << endtime

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # define if the measure should run to a specific time period or whole day
    apply_to_time = true

    # assign the user inputs to variables
    object = runner.getOptionalWorkspaceObjectChoiceValue('space_type', user_arguments, model)
    single_space_type = runner.getDoubleArgumentValue('single_space_type', user_arguments)
    occupied_space_type = runner.getDoubleArgumentValue('occupied_space_type', user_arguments)
    unoccupied_space_type = runner.getDoubleArgumentValue('unoccupied_space_type', user_arguments)
    starttime = runner.getStringArgumentValue('starttime', user_arguments)
    endtime = runner.getStringArgumentValue('endtime', user_arguments)
    demo_cost_initial_const=false

    # check the lighting power reduction percentages and for reasonableness
    if occupied_space_type > 100
      runner.registerError('Please Enter a Value less than or equal to 100 for the Electric Equipment Power Reduction Percentage.')
      return false
    elsif occupied_space_type == 0
      runner.registerInfo('No Electric Equipment power adjustment requested, but some life cycle costs may still be affected.')
    elsif (occupied_space_type < 1) && (occupied_space_type > -1)
      runner.registerWarning("A Electric Equipment Power Reduction Percentage of #{occupied_space_type} percent is abnormally low.")
    elsif occupied_space_type > 90
      runner.registerWarning("A Electric Equipment Power Reduction Percentage of #{occupied_space_type} percent is abnormally high.")
    elsif occupied_space_type < 0
      runner.registerInfo('The requested value for Electric Equipment power reduction percentage was negative. This will result in an increase in Electric Equipment power.')
    end

    # check the lighting_power_reduction_percent and for reasonableness
    if unoccupied_space_type > 100
      runner.registerError('Please Enter a Value less than or equal to 100 for the Electric Equipment Power Reduction Percentage.')
      return false
    elsif unoccupied_space_type == 0
      runner.registerInfo('No Electric Equipment power adjustment requested, but some life cycle costs may still be affected.')
    elsif (unoccupied_space_type < 1) && (unoccupied_space_type > -1)
      runner.registerWarning("A Electric Equipment Power Reduction Percentage of #{unoccupied_space_type} percent is abnormally low.")
    elsif unoccupied_space_type > 90
      runner.registerWarning("A Electric Equipment Power Reduction Percentage of #{unoccupied_space_type} percent is abnormally high.")
    elsif unoccupied_space_type < 0
      runner.registerInfo('The requested value for Electric Equipment power reduction percentage was negative. This will result in an increase in Electric Equipment power.')
    end

    # check the lighting_power_reduction_percent and for reasonableness
    if single_space_type > 100
      runner.registerError('Please Enter a Value less than or equal to 100 for the Electric Equipment Power Reduction Percentage.')
      return false
    elsif single_space_type == 0
      runner.registerInfo('No Electric Equipment power adjustment requested, but some life cycle costs may still be affected.')
    elsif (single_space_type < 1) && (single_space_type > -1)
      runner.registerWarning("A Electric Equipment Power Reduction Percentage of #{single_space_type} percent is abnormally low.")
    elsif single_space_type > 90
      runner.registerWarning("A Electric Equipment Power Reduction Percentage of #{single_space_type} percent is abnormally high.")
    elsif single_space_type < 0
      runner.registerInfo('The requested value for Electric Equipment power reduction percentage was negative. This will result in an increase in Electric Equipment power.')
    end

    # check the time periods for reasonableness
    if starttime.to_f > endtime.to_f
      runner.registerError('The end time should be larger than the start time.')
      return false
    end

    # check the space_type for reasonableness
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

    # assign the time duration when DR strategy is applied, from shift_time1 to shift_time2, only applied when apply_to_time is ture
    shift_time1 = OpenStudio::Time.new(starttime)
    shift_time2 = OpenStudio::Time.new(endtime)
    shift_time3 = OpenStudio::Time.new(0, 24, 0, 0)
  
  
    # get space types in model
    if apply_to_building
          space_types = model.getSpaceTypes
        else
      space_types = []
      space_types << space_type # only run on a single space type
    end

    # make a hash of old defs and new equipments and luminaire defs
    cloned_equi_defs = {}
    # loop through space types
    space_types.each do |space_type|
      equi_set_schs = {}
      if apply_to_building                        # measure will be applied differently to space types, based on whether the space type is occupied
        if !space_type.people.empty?
          equipment_power_reduction_percent = occupied_space_type/100
        else
          equipment_power_reduction_percent = unoccupied_space_type/100
        end
        runner.registerInitialCondition(" equipment power will be reduced by #{occupied_space_type}% in occupied spaces, and reduced by #{unoccupied_space_type}% in unoccupied spaces")

      else
        equipment_power_reduction_percent = single_space_type/100     # measure will be applied evenly to all zones
        runner.registerInitialCondition(" equipment power will be reduced by #{single_space_type}% to '#{space_type.name}'.")
      end

        space_type_equipments = space_type.electricEquipment
        space_type_equipments.each do |space_type_equipment|
          #clone of not already in hash
          equi_set_sch = space_type_equipment.schedule
          if !equi_set_sch.empty?
          # clone of not already in hash
          if equi_set_schs.key?(equi_set_sch.get.name.to_s)
            new_equi_set_sch = equi_set_schs[equi_set_sch.get.name.to_s]
          else
            new_equi_set_sch = equi_set_sch.get.clone(model)
            new_equi_set_sch = new_equi_set_sch.to_Schedule.get
            new_equi_set_sch_name = new_equi_set_sch.setName("#{new_equi_set_sch.name} adjusted #{equipment_power_reduction_percent}")
           # add to the hash
            equi_set_schs[new_equi_set_sch.name.to_s] = new_equi_set_sch
          end
          # hook up clone to equipment
          space_type_equipment.setSchedule(new_equi_set_sch)
          else
          runner.registerWarning("#{space_type.equipments.name} doesn't have a schedule.")
          end
        end
       
        if apply_to_time
          runner.registerFinalCondition(" equipment power is reduced from #{shift_time1} to #{shift_time2}.")
        else
          runner.registerFinalCondition(" equipment power is reduced all day.")
        end

 
    # make equipment schedule adjustments and rename.
    equi_set_schs.each do |k, v| # old name and new object for schedule
      if !v.to_ScheduleRuleset.empty?

        # array to store profiles in
        profiles = []
        schedule = v.to_ScheduleRuleset.get

        # push default profiles to array
        default_rule = schedule.defaultDaySchedule
        profiles << default_rule

        # push profiles to array
        rules = schedule.scheduleRules
        rules.each do |rule|
          day_sch = rule.daySchedule
          profiles << day_sch
        end
        profiles.each do |sch_day|
          day_time_vector = sch_day.times
          day_value_vector = sch_day.values
          sch_day.clearValues
          count = 0
          
          if apply_to_time 
          for i in 0..(day_time_vector.size - 1)
            if day_time_vector[i]>shift_time1&&day_time_vector[i]<shift_time2 && count == 0
            target_temp_si = day_value_vector[i]*equipment_power_reduction_percent
            sch_day.addValue(shift_time1, day_value_vector[i])
            sch_day.addValue(day_time_vector[i],target_temp_si)
            count = 1
            elsif day_time_vector[i]==shift_time1 && count == 0
            target_temp_si = day_value_vector[i]
            sch_day.addValue(day_time_vector[i], target_temp_si)
            count = 1
            elsif day_time_vector[i]>shift_time2 && count == 0
            target_temp_si = day_value_vector[i]*equipment_power_reduction_percent
            sch_day.addValue(shift_time1,day_value_vector[i])
            sch_day.addValue(shift_time2,target_temp_si)
            sch_day.addValue(day_time_vector[i],day_value_vector[i])
            count = 2
            elsif day_time_vector[i]>shift_time1 && day_time_vector[i]<shift_time2 && count==1
            target_temp_si = day_value_vector[i]*equipment_power_reduction_percent
            sch_day.addValue(day_time_vector[i], target_temp_si)
           elsif day_time_vector[i]==shift_time2 && count==1
            target_temp_si = day_value_vector[i]*equipment_power_reduction_percent
            sch_day.addValue(day_time_vector[i], target_temp_si)
            count = 2
            elsif  day_time_vector[i]>shift_time2 && count == 1
            target_temp_si = day_value_vector[i]*equipment_power_reduction_percent
            sch_day.addValue(shift_time2, target_temp_si)
            sch_day.addValue(day_time_vector[i],day_value_vector[i])
            count = 2 
            else 
            target_temp_si = day_value_vector[i]
            sch_day.addValue(day_time_vector[i], target_temp_si)
            end
          end
        else
          for i in 0..(day_time_vector.size - 1)
            target_temp_si = day_value_vector[i]*equipment_power_reduction_percent
            sch_day.addValue(day_time_vector[i], target_temp_si)
          end
        end
       end
      else
        runner.registerWarning("Schedule '#{k}' isn't a ScheduleRuleset object and won't be altered by this measure.")
        v.remove # remove un-used clone
      end
    end
   end
    return true
  end
end

# this allows the measure to be used by the application
ReduceElectricEquipmentLoadsByPercentageAndTimePeriod.new.registerWithApplication
