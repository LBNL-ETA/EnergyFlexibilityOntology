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
class ReduceLightingLoadsByPercentageAndTimePeriod < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see
  def name
    return 'DR Lighting'
  end

  # human readable description
  def description
    return 'This measure adjusts lighting loads by a user-specified percentage and a user-specified time period. This is applied to a specific space type or throughout the entire building.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure will clone all of the schedules that are used as lighting power setting for each zone. Then the schedules are adjusted by a specified percentage during a specified time period. If the measure is applied throughout the entire building, the reduction value can be separately defined based on whether this space type is occupied or not.'
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
    occupied_space_type.setDisplayName("Please fill in the lighting power reduction in No.1-2, if you chose the 'Entire Building'. Otherwise, please fill in the value in No.3.\n 1.Lighting Power Reduction for Occupied Spaces (%).")
    occupied_space_type.setDefaultValue(30.0)
    args << occupied_space_type
   
    # make an argument for reduction percentage for unoccupied spaces (if user chose the Entire Building)
    unoccupied_space_type = OpenStudio::Measure::OSArgument.makeDoubleArgument('unoccupied_space_type', true)
    unoccupied_space_type.setDisplayName('2.Lighting Power Reduction for Unoccupied Spaces (%).')
    unoccupied_space_type.setDefaultValue(60.0)
    args << unoccupied_space_type

    # make an argument for reduction percentage for specific space type (if user chose only one space type to apply this measure)
    single_space_type = OpenStudio::Measure::OSArgument.makeDoubleArgument('single_space_type', true)
    single_space_type.setDisplayName('3.Lighting Power Reduction for the Selected Space Type (%).')
    single_space_type.setDefaultValue(30.0)
    args << single_space_type

        # make an argument for the start time of the reduction
    starttime_winter1 = OpenStudio::Measure::OSArgument.makeStringArgument('starttime_winter1', true)
    starttime_winter1.setDisplayName('Start Time for the Reduction')
    starttime_winter1.setDefaultValue('17:00:00')
    args << starttime_winter1

    # make an argument for the end time of the reduction
    endtime_winter1 = OpenStudio::Measure::OSArgument.makeStringArgument('endtime_winter1', true)
    endtime_winter1.setDisplayName('End Time for the Reduction')
    endtime_winter1.setDefaultValue('21:00:00')
    args << endtime_winter1

    # make an argument for the start time of the reduction
    starttime_winter2 = OpenStudio::Measure::OSArgument.makeStringArgument('starttime_winter2', true)
    starttime_winter2.setDisplayName('Start Time for the Reduction')
    starttime_winter2.setDefaultValue('17:00:00')
    args << starttime_winter2

    # make an argument for the end time of the reduction
    endtime_winter2 = OpenStudio::Measure::OSArgument.makeStringArgument('endtime_winter2', true)
    endtime_winter2.setDisplayName('End Time for the Reduction')
    endtime_winter2.setDefaultValue('21:00:00')
    args << endtime_winter2


    starttime_summer = OpenStudio::Measure::OSArgument.makeStringArgument('starttime_summer', true)
    starttime_summer.setDisplayName('Start Time for the Reduction during the Special Schedule')
    starttime_summer.setDefaultValue('16:00:00')
    args << starttime_summer

    # make an argument for the end time of the reduction
    endtime_summer = OpenStudio::Measure::OSArgument.makeStringArgument('endtime_summer', true)
    endtime_summer.setDisplayName('End Time for the Reduction during the Special Schedule')
    endtime_summer.setDefaultValue('20:00:00')
    args << endtime_summer

    auto_date = OpenStudio::Measure::OSArgument.makeBoolArgument('auto_date', true)
    auto_date.setDisplayName('Enable Climate-specific Periods Setting ?')
    auto_date.setDefaultValue(true)
    args << auto_date


    return args
  end



  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # define if the measure should run accordingly to different space type or evenly on the entire building
    # define if the measure should run to a specific time period or whole day

    # assign the user inputs to variables
    object = runner.getOptionalWorkspaceObjectChoiceValue('space_type', user_arguments, model)
    single_space_type = runner.getDoubleArgumentValue('single_space_type', user_arguments)
    occupied_space_type = runner.getDoubleArgumentValue('occupied_space_type', user_arguments)
    unoccupied_space_type = runner.getDoubleArgumentValue('unoccupied_space_type', user_arguments)
    starttime_winter1 = runner.getStringArgumentValue('starttime_winter1', user_arguments)
    endtime_winter1 = runner.getStringArgumentValue('endtime_winter1', user_arguments)
    starttime_winter2 = runner.getStringArgumentValue('starttime_winter2', user_arguments)
    endtime_winter2 = runner.getStringArgumentValue('endtime_winter2', user_arguments)
    starttime_summer = runner.getStringArgumentValue('starttime_summer', user_arguments)
    endtime_summer = runner.getStringArgumentValue('endtime_summer', user_arguments)
    auto_date = runner.getBoolArgumentValue('auto_date', user_arguments)
    demo_cost_initial_const=false

    winter_start_month1 = 1
    winter_end_month1 = 5
    summer_start_month = 6
    summer_end_month = 8
    winter_start_month2 = 9
    winter_end_month2 = 12

    ######### GET CLIMATE ZONES ################
    if auto_date
      ashraeClimateZone = ''
      #climateZoneNUmber = ''
      climateZones = model.getClimateZones
      climateZones.climateZones.each do |climateZone|
        if climateZone.institution == 'ASHRAE'
          ashraeClimateZone = climateZone.value
          runner.registerInfo("Using ASHRAE Climate zone #{ashraeClimateZone}.")
        end
      end

      if ashraeClimateZone == '' # should this be not applicable or error?
        runner.registerError("Please assign an ASHRAE Climate Zone to your model using the site tab in the OpenStudio application. The measure can't make AEDG recommendations without this information.")
        return false # note - for this to work need to check for false in measure.rb and add return false there as well.
      end

      if ashraeClimateZone == '2A'
        starttime_summer = '16:01:00'
        endtime_summer = '19:59:00'
        starttime_winter1 = '4:59:00'
        endtime_winter1 = '8:59:00'
        starttime_winter2 = '16:01:00'
        endtime_winter2 = '19:59:00'
      elsif ashraeClimateZone == '2B'
        starttime_summer = '14:59:00'
        endtime_summer = '18:59:00'
        starttime_winter1 = '4:59:00'
        endtime_winter1 = '8:59:00'
        starttime_winter2 = '16:01:00'
        endtime_winter2 = '19:59:00'
      elsif ashraeClimateZone == '3A'
        starttime_summer = '16:59:00'
        endtime_summer = '20:59:00'
        starttime_winter1 = '4:59:00'
        endtime_winter1 = '8:59:00'
        starttime_winter2 = '16:01:00'
        endtime_winter2 = '19:59:00'
      elsif ashraeClimateZone == '3B'
        starttime_summer = '16:59:00'
        endtime_summer = '20:59:00'
        starttime_winter1 = '4:59:00'
        endtime_winter1 = '8:59:00'
        starttime_winter2 = '17:01:00'
        endtime_winter2 = '20:59:00'
      elsif ashraeClimateZone == '3C'
        starttime_summer = '16:01:00'
        endtime_summer = '19:59:00'
        starttime_winter1 = '4:59:00'
        endtime_winter1 = '8:59:00'
        starttime_winter2 = '16:01:00'
        endtime_winter2 = '19:59:00'
      elsif ashraeClimateZone == '4A'
        unoccupied_space_type = 0
        occupied_space_type = 0
        single_space_type = 0
        starttime_summer = '2:59:00'
        endtime_summer = '6:59:00'
        starttime_winter1 = '6:01:00'
        endtime_winter1 = '9:59:00'
        starttime_winter2 = '16:01:00'
        endtime_winter2 = '19:59:00'
      elsif ashraeClimateZone == '4B'
        starttime_summer = '14:59:00'
        endtime_summer = '18:59:00'
        starttime_winter1 = '4:59:00'
        endtime_winter1 = '8:59:00'
        starttime_winter2 = '16:01:00'
        endtime_winter2 = '19:59:00'
      elsif ashraeClimateZone == '4C'
        starttime_summer = '14:59:00'
        endtime_summer = '18:59:00'
        starttime_winter1 = '6:01:00'
        endtime_winter1 = '9:59:00'
        starttime_winter2 = '16:01:00'
        endtime_winter2 = '19:59:00'
      elsif ashraeClimateZone == '5A'
        unoccupied_space_type = 0
        occupied_space_type = 0
        single_space_type = 0
        starttime_summer = '2:59:00'
        endtime_summer = '6:59:00'
        starttime_winter1 = '6:01:00'
        endtime_winter1 = '9:59:00'
        starttime_winter2 = '16:01:00'
        endtime_winter2 = '19:59:00'
      elsif ashraeClimateZone == '5B'
        starttime_summer = '14:59:00'
        endtime_summer = '18:59:00'
        starttime_winter1 = '6:01:00'
        endtime_winter1 = '9:59:00'
        starttime_winter2 = '16:01:00'
        endtime_winter2 = '19:59:00'
      elsif ashraeClimateZone == '5C'
        starttime_summer = '14:59:00'
        endtime_summer = '18:59:00'
        starttime_winter1 = '6:01:00'
        endtime_winter1 = '9:59:00'
        starttime_winter2 = '16:59:00'
        endtime_winter2 = '20:59:00'
      elsif ashraeClimateZone == '6A'
        starttime_summer = '14:59:00'
        endtime_summer = '18:59:00'
        starttime_winter1 = '17:59:00'
        endtime_winter1 = '21:59:00'
        starttime_winter2 = '17:59:00'
        endtime_winter2 = '21:59:00'
      elsif ashraeClimateZone == '6B'
        starttime_summer = '14:59:00'
        endtime_summer = '18:59:00'
        starttime_winter1 = '6:01:00'
        endtime_winter1 = '9:59:00'
        starttime_winter2 = '16:01:00'
        endtime_winter2 = '19:59:00'
      elsif ashraeClimateZone == '7A'
        starttime_summer = '14:59:00'
        endtime_summer = '18:59:00'
        starttime_winter1 = '17:59:00'
        endtime_winter1 = '17:59:00'
        starttime_winter2 = '17:59:00'
        endtime_winter2 = '21:59:00'
      end
    end

    runner.registerInfo("unoccupied #{unoccupied_space_type} occupied #{occupied_space_type} single #{single_space_type}")
    # check the lighting power reduction percentages and for reasonableness
    if occupied_space_type > 100
      runner.registerError('Please Enter a Value less than or equal to 100 for the Lighting Power Reduction Percentage.')
      return false
    elsif occupied_space_type == 0
      runner.registerInfo('No lighting power adjustment requested, but some life cycle costs may still be affected.')
    elsif (occupied_space_type < 1) && (occupied_space_type > -1)
      runner.registerWarning("A Lighting Power Reduction Percentage of #{occupied_space_type} percent is abnormally low.")
    elsif occupied_space_type > 90
      runner.registerWarning("A Lighting Power Reduction Percentage of #{occupied_space_type} percent is abnormally high.")
    elsif occupied_space_type < 0
      runner.registerInfo('The requested value for lighting power reduction percentage was negative. This will result in an increase in lighting power.')
    end

    # check the lighting_power_reduction_percent and for reasonableness
    if unoccupied_space_type > 100
      runner.registerError('Please Enter a Value less than or equal to 100 for the Lighting Power Reduction Percentage.')
      return false
    elsif unoccupied_space_type == 0
      runner.registerInfo('No lighting power adjustment requested, but some life cycle costs may still be affected.')
    elsif (unoccupied_space_type < 1) && (unoccupied_space_type > -1)
      runner.registerWarning("A Lighting Power Reduction Percentage of #{unoccupied_space_type} percent is abnormally low.")
    elsif unoccupied_space_type > 90
      runner.registerWarning("A Lighting Power Reduction Percentage of #{unoccupied_space_type} percent is abnormally high.")
    elsif unoccupied_space_type < 0
      runner.registerInfo('The requested value for lighting power reduction percentage was negative. This will result in an increase in lighting power.')
    end

    # check the lighting_power_reduction_percent and for reasonableness
    if single_space_type > 100
      runner.registerError('Please Enter a Value less than or equal to 100 for the Lighting Power Reduction Percentage.')
      return false
    elsif single_space_type == 0
      runner.registerInfo('No lighting power adjustment requested, but some life cycle costs may still be affected.')
    elsif (single_space_type < 1) && (single_space_type > -1)
      runner.registerWarning("A Lighting Power Reduction Percentage of #{single_space_type} percent is abnormally low.")
    elsif single_space_type > 90
      runner.registerWarning("A Lighting Power Reduction Percentage of #{single_space_type} percent is abnormally high.")
    elsif single_space_type < 0
      runner.registerInfo('The requested value for lighting power reduction percentage was negative. This will result in an increase in lighting power.')
    end

    # check the time periods for reasonableness
    if (starttime_winter1.to_f > endtime_winter1.to_f) && (starttime_winter2.to_f > endtime_winter2.to_f) && (starttime_summer.to_f > endtime_summer.to_f)
      runner.registerError('The end time should be larger than the start time.')
      return false
    end

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


    ############################################

    # assign the time duration when DR strategy is applied, from shift_time1 to shift_time2, only applied when apply_to_time is ture
    shift_time1 = OpenStudio::Time.new(starttime_winter1)
    shift_time2 = OpenStudio::Time.new(endtime_winter1)
    shift_time3 = OpenStudio::Time.new(0, 24, 0, 0)
    shift_time4 = OpenStudio::Time.new(starttime_summer)
    shift_time5 = OpenStudio::Time.new(endtime_summer)
    shift_time6 = OpenStudio::Time.new(starttime_winter2)
    shift_time7 = OpenStudio::Time.new(endtime_winter2)
   
    # get space types in model
    if apply_to_building
          space_types = model.getSpaceTypes
        else
      space_types = []
      space_types << space_type # only run on a single space type
    end

    # make a hash of old defs and new lights and luminaire defs
    cloned_lights_defs = {}
    cloned_luminaire_defs = {}
    # loop through space types
    space_types.each do |space_type|
      lgt_set_schs = {}
      if apply_to_building                         # measure will be applied differently to space types, based on whether the space type is occupied
        if !space_type.people.empty?
          lighting_power_reduction_percent = 1 - (occupied_space_type/100)
        else
          lighting_power_reduction_percent = 1 - (unoccupied_space_type/100)
        end
        runner.registerInitialCondition(" lighting power will be reduced by #{occupied_space_type}% in occupied spaces, and reduced by #{unoccupied_space_type}% in unoccupied spaces")

      else
        lighting_power_reduction_percent = 1 - (single_space_type/100)      # measure will be applied evenly to all zones
        runner.registerInitialCondition(" lighting power will be reduced by #{single_space_type}% to '#{space_type.name}'.")
      end

      space_type_lights = space_type.lights
      space_type_lights.each do |space_type_light|
      #clone of not already in hash
      lgt_set_sch = space_type_light.schedule
      if !lgt_set_sch.empty?
      # clone of not already in hash
      if lgt_set_schs.key?(lgt_set_sch.get.name.to_s)
      new_lgt_set_sch = lgt_set_schs[lgt_set_sch.get.name.to_s]
      else
      new_lgt_set_sch = lgt_set_sch.get.clone(model)
      new_lgt_set_sch = new_lgt_set_sch.to_Schedule.get
      new_lgt_set_sch_name = new_lgt_set_sch.setName("#{new_lgt_set_sch.name} adjusted #{lighting_power_reduction_percent}")
      # add to the hash
      lgt_set_schs[new_lgt_set_sch.name.to_s] = new_lgt_set_sch
      end
      # hook up clone to lighting
      space_type_light.setSchedule(new_lgt_set_sch)
      else
      runner.registerWarning("#{space_type.lights.name} doesn't have a schedule.")
      end
      end

      runner.registerFinalCondition(" lighting power is reduced from #{shift_time1} to #{shift_time2} in the Winter. lighting power is reduced from #{shift_time4} to #{shift_time5} in the Summer")


    #id = 0
 
    # make light schedule adjustments and rename.
    lgt_set_schs.each do |k, v| # old name and new object for schedule
      if !v.to_ScheduleRuleset.empty?

        schedule = v.to_ScheduleRuleset.get
        default_rule = schedule.defaultDaySchedule
        rules = schedule.scheduleRules

        days_covered = Array.new(7, false)

        if rules.length > 0
          rules.each do |rule|
            summerStartMonth = OpenStudio::MonthOfYear.new(summer_start_month)
            summerEndMonth = OpenStudio::MonthOfYear.new(summer_end_month)
            summerStartDate = OpenStudio::Date.new(summerStartMonth, 1)
            summerEndDate = OpenStudio::Date.new(summerEndMonth, 30)
            
            summer_rule = rule.clone(model).to_ScheduleRule.get
            summer_rule.setStartDate(summerStartDate)
            summer_rule.setEndDate(summerEndDate)

            allDaysCovered(summer_rule, days_covered)

            cloned_day_summer = rule.daySchedule.clone(model)
            cloned_day_summer.setParent(summer_rule)

            summer_day = summer_rule.daySchedule
            day_time_vector = summer_day.times
            day_value_vector = summer_day.values
            summer_day.clearValues
            
            summer_day = createDaySchedule(summer_day, day_time_vector, day_value_vector, shift_time4, shift_time5, lighting_power_reduction_percent)
          
            ##############################################
            winterStartMonth1 = OpenStudio::MonthOfYear.new(winter_start_month1)
            winterEndMonth1 = OpenStudio::MonthOfYear.new(winter_end_month1)
            winterStartDate1 = OpenStudio::Date.new(winterStartMonth1, 1)
            winterEndDate1 = OpenStudio::Date.new(winterEndMonth1, 30)
            
            winter_rule1 = rule #rule.clone(model).to_ScheduleRule.get
            winter_rule1.setStartDate(winterStartDate1)
            winter_rule1.setEndDate(winterEndDate1)


            cloned_day_winter = rule.daySchedule.clone(model)
            cloned_day_winter.setParent(winter_rule1)

            winter_day1 = winter_rule1.daySchedule
            day_time_vector = winter_day1.times
            day_value_vector = winter_day1.values
            winter_day1.clearValues
            
            winter_day1 = createDaySchedule(winter_day1, day_time_vector, day_value_vector, shift_time6, shift_time7, lighting_power_reduction_percent)
            if shift_time1 != shift_time6 
              winter_day1 = createDaySchedule(winter_day1, day_time_vector, day_value_vector, shift_time1, shift_time2, lighting_power_reduction_percent)
            end
            ###################################################
            winterStartMonth2 = OpenStudio::MonthOfYear.new(winter_start_month2)
            winterEndMonth2 = OpenStudio::MonthOfYear.new(winter_end_month2)
            winterStartDate2 = OpenStudio::Date.new(winterStartMonth2, 1)
            winterEndDate2 = OpenStudio::Date.new(winterEndMonth2, 30)
            
            winter_rule2 = winter_rule1.clone(model).to_ScheduleRule.get
            winter_rule2.setStartDate(winterStartDate2)
            winter_rule2.setEndDate(winterEndDate2)
            
            cloned_day_winter2 = winter_day1.clone(model)
            cloned_day_winter2.setParent(winter_rule2)
          end
        end
        #runner.registerInfo("BEFORE #{days_covered}")
        if days_covered.include?(false)
            summerStartMonth = OpenStudio::MonthOfYear.new(summer_start_month)
            summerEndMonth = OpenStudio::MonthOfYear.new(summer_end_month)
            summerStartDate = OpenStudio::Date.new(summerStartMonth, 1)
            summerEndDate = OpenStudio::Date.new(summerEndMonth, 30)
            
            summer_rule = OpenStudio::Model::ScheduleRule.new(schedule)
            summer_rule.setStartDate(summerStartDate)
            summer_rule.setEndDate(summerEndDate)
            coverSomeDays(summer_rule, days_covered)
            allDaysCovered(summer_rule, days_covered)

            cloned_day_summer = default_rule.clone(model)
            cloned_day_summer.setParent(summer_rule)

            summer_day = summer_rule.daySchedule
            day_time_vector = summer_day.times
            day_value_vector = summer_day.values
            summer_day.clearValues
            
            summer_day = createDaySchedule(summer_day, day_time_vector, day_value_vector, shift_time4, shift_time5, lighting_power_reduction_percent)
          
            ##############################################
            winterStartMonth1 = OpenStudio::MonthOfYear.new(winter_start_month1)
            winterEndMonth1 = OpenStudio::MonthOfYear.new(winter_end_month1)
            winterStartDate1 = OpenStudio::Date.new(winterStartMonth1, 1)
            winterEndDate1 = OpenStudio::Date.new(winterEndMonth1, 30)
            
            winter_rule1 = summer_rule.clone(model).to_ScheduleRule.get #OpenStudio::Model::ScheduleRule.new(schedule)
            winter_rule1.setStartDate(winterStartDate1)
            winter_rule1.setEndDate(winterEndDate1)

            #coverSomeDays(winter_rule1, days_covered)
            #allDaysCovered(summer_rule, days_covered)

            cloned_day_winter = default_rule.clone(model)
            cloned_day_winter.setParent(winter_rule1)

            winter_day1 = winter_rule1.daySchedule
            day_time_vector = winter_day1.times
            day_value_vector = winter_day1.values
            winter_day1.clearValues
            
            winter_day1 = createDaySchedule(winter_day1, day_time_vector, day_value_vector, shift_time6, shift_time7, lighting_power_reduction_percent)
            if shift_time1 != shift_time6 
              winter_day1 = createDaySchedule(winter_day1, day_time_vector, day_value_vector, shift_time1, shift_time2, lighting_power_reduction_percent)
            end
            ###################################################
            winterStartMonth2 = OpenStudio::MonthOfYear.new(winter_start_month2)
            winterEndMonth2 = OpenStudio::MonthOfYear.new(winter_end_month2)
            winterStartDate2 = OpenStudio::Date.new(winterStartMonth2, 1)
            winterEndDate2 = OpenStudio::Date.new(winterEndMonth2, 30)
            
            winter_rule2 = winter_rule1.clone(model).to_ScheduleRule.get #OpenStudio::Model::ScheduleRule.new(schedule)
            winter_rule2.setStartDate(winterStartDate2)
            winter_rule2.setEndDate(winterEndDate2)
            
            cloned_day_winter2 = winter_day1.clone(model)
            cloned_day_winter2.setParent(winter_rule2)
        end
        #runner.registerInfo("AFTER Summer #{days_covered}")
      else
        runner.registerWarning("Schedule '#{k}' isn't a ScheduleRuleset object and won't be altered by this measure.")
        v.remove # remove un-used clone
      end
    end

   end
    return true
  end

  def allDaysCovered(sch_rule, sch_day_covered)
    if sch_rule.applySunday 
      sch_day_covered[0] = true
    end
    if sch_rule.applyMonday
      sch_day_covered[1] = true
    end
    if sch_rule.applyTuesday
      sch_day_covered[2] = true
    end
    if sch_rule.applyWednesday
      sch_day_covered[3] = true
    end
    if sch_rule.applyThursday
      sch_day_covered[4] = true
    end
    if sch_rule.applyFriday
      sch_day_covered[5] = true
    end
    if sch_rule.applySaturday
      sch_day_covered[6] = true
    end
  end

  def coverSomeDays(sch_rule, sch_day_covered)
    if sch_day_covered[0] == false
      sch_rule.setApplySunday(true)
    end
    if sch_day_covered[1] == false
      sch_rule.setApplyMonday(true)
    end
    if sch_day_covered[2] == false
      sch_rule.setApplyTuesday(true)
    end
    if sch_day_covered[3] == false
      sch_rule.setApplyWednesday(true)
    end
    if sch_day_covered[4] == false
      sch_rule.setApplyThursday(true)
    end
    if sch_day_covered[5] == false
      sch_rule.setApplyFriday(true)
    end
    if sch_day_covered[6] == false
      sch_rule.setApplySaturday(true)
    end

  end

  def createDaySchedule(sch_day, vec_time, vec_value, time_begin, time_end, percentage)
    count = 0
    for i in 0..(vec_time.size - 1)
      if vec_time[i]>time_begin&&vec_time[i]<time_end && count == 0
      target_temp_si = vec_value[i]*percentage
      sch_day.addValue(time_begin, vec_value[i])
      sch_day.addValue(vec_time[i],target_temp_si)
      count = 1
      elsif vec_time[i]==time_end && count == 0
      target_temp_si = vec_value[i]*percentage
      sch_day.addValue(time_begin, vec_value[i])
      sch_day.addValue(vec_time[i],target_temp_si)
      count = 2
      elsif vec_time[i]==time_begin && count == 0
      target_temp_si = vec_value[i]
      sch_day.addValue(vec_time[i], target_temp_si)
      count = 1
      elsif vec_time[i]==time_end && count == 0
      target_temp_si = vec_value[i]*percentage
      sch_day.addValue(time_begin, vec_value[i])
      sch_day.addValue(vec_time[i],target_temp_si)
      count = 2
      elsif vec_time[i]>time_end && count == 0
      target_temp_si = vec_value[i]*percentage
      sch_day.addValue(time_begin,vec_value[i])
      sch_day.addValue(time_end,target_temp_si)
      sch_day.addValue(vec_time[i],vec_value[i])
      count = 2
      elsif vec_time[i]>time_begin && vec_time[i]<time_end && count==1
      target_temp_si = vec_value[i]*percentage
      sch_day.addValue(vec_time[i], target_temp_si)
      elsif vec_time[i]==time_end && count==1
      target_temp_si = vec_value[i]*percentage
      sch_day.addValue(vec_time[i], target_temp_si)
      count = 2
      elsif  vec_time[i]>time_end && count == 1
      target_temp_si = vec_value[i]*percentage
      sch_day.addValue(time_end, target_temp_si)
      sch_day.addValue(vec_time[i],vec_value[i])
      count = 2 
      else 
      target_temp_si = vec_value[i]
      sch_day.addValue(vec_time[i], target_temp_si)
      end
    end

    return sch_day
  end
end

# this allows the measure to be used by the application
ReduceLightingLoadsByPercentageAndTimePeriod.new.registerWithApplication
