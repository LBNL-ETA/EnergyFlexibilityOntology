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
class PreCoolingAndHeating < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see
  def name
    return 'Precooling Preheating (Medium Office)'
  end

  # human readable description
  def description
    return 'This measure adjusts cooling and heating schedules by a user specified number of degrees and time period. This is applied throughout the entire building.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure will clone all of the schedules that are used as heating and cooling setpoints for thermal zones. The clones are hooked up to the thermostat in place of the original schedules. Then the schedules are adjusted by the specified values. HVAC operation schedule will also be changed if the start time of the pre-cooling/heating is earlier than the default start value. There is a checkbox to determine if the thermostat for design days should be altered.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for adjustment to cooling setpoint
    cooling_adjustment = OpenStudio::Measure::OSArgument.makeDoubleArgument('cooling_adjustment', true)
    cooling_adjustment.setDisplayName('Degrees Fahrenheit to Adjust Cooling Setpoint By')
    cooling_adjustment.setDefaultValue(-2.0)
    args << cooling_adjustment

    # make an argument for the start time of pre-cooling/heating
    starttime_cooling = OpenStudio::Measure::OSArgument.makeStringArgument('starttime_cooling', true)
    starttime_cooling.setDisplayName('Start Time for Pre-cooling')
    starttime_cooling.setDefaultValue('11:59:00')
    args << starttime_cooling

    # make an argument for the end time of pre-cooling/heating
    endtime_cooling = OpenStudio::Measure::OSArgument.makeStringArgument('endtime_cooling', true)
    endtime_cooling.setDisplayName('End Time for Pre-cooling')
    endtime_cooling.setDefaultValue('15:59:00')
    args << endtime_cooling

    # make an argument for adjustment to heating setpoint
    heating_adjustment = OpenStudio::Measure::OSArgument.makeDoubleArgument('heating_adjustment', true)
    heating_adjustment.setDisplayName('Degrees Fahrenheit to Adjust heating Setpoint By')
    heating_adjustment.setDefaultValue(2.0)
    args << heating_adjustment

    starttime_heating = OpenStudio::Measure::OSArgument.makeStringArgument('starttime_heating', true)
    starttime_heating.setDisplayName('Start Time for Pre-heating')
    starttime_heating.setDefaultValue('0:01:00')
    args << starttime_heating

    # make an argument for the end time of pre-cooling/heating
    endtime_heating = OpenStudio::Measure::OSArgument.makeStringArgument('endtime_heating', true)
    endtime_heating.setDisplayName('End Time for Pre-heating')
    endtime_heating.setDefaultValue('4:59:00')
    args << endtime_heating

    # make an argument for adjustment to heating setpoint
    alter_design_days = OpenStudio::Measure::OSArgument.makeBoolArgument('alter_design_days', true)
    alter_design_days.setDisplayName('Alter Design Day Thermostats')
    alter_design_days.setDefaultValue(false)
    args << alter_design_days

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

    # assign the user inputs to variables
    cooling_adjustment = runner.getDoubleArgumentValue('cooling_adjustment', user_arguments)
    heating_adjustment = runner.getDoubleArgumentValue('heating_adjustment', user_arguments)
    alter_design_days = runner.getBoolArgumentValue('alter_design_days', user_arguments)
    starttime_cooling = runner.getStringArgumentValue('starttime_cooling', user_arguments)
    endtime_cooling = runner.getStringArgumentValue('endtime_cooling', user_arguments)
    starttime_heating = runner.getStringArgumentValue('starttime_heating', user_arguments)
    endtime_heating = runner.getStringArgumentValue('endtime_heating', user_arguments)
    auto_date = runner.getBoolArgumentValue('auto_date', user_arguments)

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
      # else
      #   climateZoneNumber = ashraeClimateZone.split(//).first
      end
      # #runner.registerInfo("CLIMATE ZONE #{ashraeClimateZone}. Right now does not do anything.")
      #     if !['1', '2', '3', '4', '5', '6', '7', '8'].include? climateZoneNumber
      #       runner.registerError('ASHRAE climate zone number is not within expected range of 1 to 8.')
      #       return false # note - for this to work need to check for false in measure.rb and add return false there as well.
      #     end

  if ashraeClimateZone == '2A'
        starttime_cooling = '11:59:00'
        endtime_cooling = '15:59:00'
        starttime_heating = '11:59:00'
        endtime_heating = '15:59:00'
      elsif ashraeClimateZone == '2B'
        starttime_cooling = '2:59:00'
        endtime_cooling = '6:59:00'
        starttime_heating = '11:59:00'
        endtime_heating = '15:59:00'
      elsif ashraeClimateZone == '3A'
        starttime_cooling = '2:59:00'
        endtime_cooling = '6:59:00'
        starttime_heating = '11:59:00'
        endtime_heating = '15:59:00'
      elsif ashraeClimateZone == '3B'
        starttime_cooling = '2:59:00'
        endtime_cooling = '6:59:00'
        starttime_heating = '11:59:00'
        endtime_heating = '15:59:00'
      elsif ashraeClimateZone == '3C'
        starttime_cooling = '10:59:00'
        endtime_cooling = '14:59:00'
        starttime_heating = '10:59:00'
        endtime_heating = '14:59:00'
      elsif ashraeClimateZone == '4A'
        starttime_cooling = '2:59:00'
        endtime_cooling = '6:59:00'
        starttime_heating = '9:59:00'
        endtime_heating = '13:59:00'
      elsif ashraeClimateZone == '4B'
        starttime_cooling = '2:59:00'
        endtime_cooling = '6:59:00'
        starttime_heating = '9:59:00'
        endtime_heating = '13:59:00'
      elsif ashraeClimateZone == '4C'
        starttime_cooling = '0:59:00'
        endtime_cooling = '4:59:00'
        starttime_heating = '10:59:00'
        endtime_heating = '14:59:00'
      elsif ashraeClimateZone == '5A'
        starttime_cooling = '2:59:00'
        endtime_cooling = '6:59:00'
        starttime_heating = '9:59:00'
        endtime_heating = '13:59:00'
      elsif ashraeClimateZone == '5B'
        starttime_cooling = '1:59:00'
        endtime_cooling = '5:59:00'
        starttime_heating = '10:59:00'
        endtime_heating = '14:59:00'
      elsif ashraeClimateZone == '5C'
        starttime_cooling = '0:59:00'
        endtime_cooling = '4:59:00'
        starttime_heating = '10:59:00'
        endtime_heating = '14:59:00'
      elsif ashraeClimateZone == '6A'
        starttime_cooling = '2:59:00'
        endtime_cooling = '6:59:00'
        starttime_heating = '1:59:00'
        endtime_heating = '5:59:00'
      elsif ashraeClimateZone == '6B'
        starttime_cooling = '0:59:00'
        endtime_cooling = '4:59:00'
        starttime_heating = '10:59:00'
        endtime_heating = '14:59:00'
      elsif ashraeClimateZone == '7A'
        starttime_cooling = '2:59:00'
        endtime_cooling = '6:59:00'
        starttime_heating = '1:59:00'
        endtime_heating = '5:59:00'
      end
    end

    
    if starttime_cooling.to_f > endtime_cooling.to_f
      runner.registerError('The end time should be larger than the start time.')
      return false
    end

    # ruby test to see if first charter of string is uppercase letter
    if cooling_adjustment < 0
      runner.registerWarning('Lowering the cooling setpoint will increase energy use.')
    elsif cooling_adjustment.abs > 500
      runner.registerError("#{cooling_adjustment} is a larger than typical setpoint adjustment")
      return false
    elsif cooling_adjustment.abs > 50
      runner.registerWarning("#{cooling_adjustment} is a larger than typical setpoint adjustment")
    end
    if heating_adjustment > 0
      runner.registerWarning('Raising the heating setpoint will increase energy use.')
    elsif heating_adjustment.abs > 500
      runner.registerError("#{heating_adjustment} is a larger than typical setpoint adjustment")
      return false
    elsif heating_adjustment.abs > 50
      runner.registerWarning("#{heating_adjustment} is a larger than typical setpoint adjustment")
    end

    # setup OpenStudio units that we will need
    temperature_ip_unit = OpenStudio.createUnit('F').get
    temperature_si_unit = OpenStudio.createUnit('C').get

    shift_time1 = OpenStudio::Time.new(starttime_cooling)
    shift_time2 = OpenStudio::Time.new(endtime_cooling)
    shift_time3 = OpenStudio::Time.new(0,6,0,0)
    shift_time4 = OpenStudio::Time.new(starttime_heating)
    shift_time5 = OpenStudio::Time.new(endtime_heating)


    # define starting units
    cooling_adjustment_ip = OpenStudio::Quantity.new(cooling_adjustment, temperature_ip_unit)
    heating_adjustment_ip = OpenStudio::Quantity.new(heating_adjustment, temperature_ip_unit)

  if ((shift_time1 < shift_time3) || (shift_time4 < shift_time3))  #HVAC Operation Schedule will be altered to achieve the pre-cooling/heating
    schedules = []
    schedule_args = model.getScheduleRulesets
    schedule_args.each do |schedule_arg|
      if schedule_arg.name.to_s == "OfficeMedium HVACOperationSchd"
      #if schedule_arg.name.to_s == "OfficeLarge HVACOperationSchd"
      #if schedule_arg.name.to_s == "HotelLarge HVACOperationSchd"
        schedules << schedule_arg
      end
    end
    schedules.each do |schedule|
      # array of all profiles to change
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

      cloned_day_summer = rules[1].daySchedule.clone(model)
      cloned_day_winter = rules[1].daySchedule.clone(model)

      summerStartMonth = OpenStudio::MonthOfYear.new(summer_start_month)
      summerEndMonth = OpenStudio::MonthOfYear.new(summer_end_month)
      startDate = OpenStudio::Date.new(summerStartMonth, 1)
      endDate = OpenStudio::Date.new(summerEndMonth, 30)
      summer_rule = OpenStudio::Model::ScheduleRule.new(schedule)
      summer_rule.setStartDate(startDate)
      summer_rule.setEndDate(endDate)
      summer_rule.setApplyMonday(true)
      summer_rule.setApplyTuesday(true)
      summer_rule.setApplyWednesday(true)
      summer_rule.setApplyThursday(true)
      summer_rule.setApplyFriday(true)
      cloned_day_summer.setParent(summer_rule)

      summer_day = summer_rule.daySchedule
      if (shift_time1 < shift_time3)
        new_times = []
        new_values = []
        day_time_vector = summer_day.times
        day_value_vector = summer_day.values

        day_time_vector.each do |time|
          new_times << time
        end

        # push values to array
        day_value_vector.each do |value|
          new_values << value
        end

        summer_day.clearValues

        summer_day.addValue(shift_time1,0)       
        for i in 1..(new_values.length - 1)
          summer_day.addValue(new_times[i], new_values[i])
        end
      end


      winterStartMonth1 = OpenStudio::MonthOfYear.new(winter_start_month1)
      winterEndMonth1 = OpenStudio::MonthOfYear.new(winter_end_month1)
      startDate = OpenStudio::Date.new(winterStartMonth1, 1)
      endDate = OpenStudio::Date.new(winterEndMonth1, 30)
      winter_rule1 = OpenStudio::Model::ScheduleRule.new(schedule)
      winter_rule1.setStartDate(startDate)
      winter_rule1.setEndDate(endDate)
      winter_rule1.setApplyMonday(true)
      winter_rule1.setApplyTuesday(true)
      winter_rule1.setApplyWednesday(true)
      winter_rule1.setApplyThursday(true)
      winter_rule1.setApplyFriday(true)
      cloned_day_winter.setParent(winter_rule1)

      winter_day1 = winter_rule1.daySchedule
      if (shift_time4 < shift_time3)
        new_times = []
        new_values = []
        day_time_vector = winter_day1.times
        day_value_vector = winter_day1.values

        day_time_vector.each do |time|
          new_times << time
        end

        # push values to array
        day_value_vector.each do |value|
          new_values << value
        end

        winter_day1.clearValues

        winter_day1.addValue(shift_time4,0)       
        for i in 1..(new_values.length - 1)
          winter_day1.addValue(new_times[i], new_values[i])
        end
      end

      winterStartMonth2 = OpenStudio::MonthOfYear.new(winter_start_month2)
      winterEndMonth2 = OpenStudio::MonthOfYear.new(winter_end_month2)
      startDate = OpenStudio::Date.new(winterStartMonth2, 1)
      endDate = OpenStudio::Date.new(winterEndMonth2, 30)
      cloned_day = winter_day1.clone(model)
      winter_rule2 = OpenStudio::Model::ScheduleRule.new(schedule)
      winter_rule2.setStartDate(startDate)
      winter_rule2.setEndDate(endDate)
      winter_rule2.setApplyMonday(true)
      winter_rule2.setApplyTuesday(true)
      winter_rule2.setApplyWednesday(true)
      winter_rule2.setApplyThursday(true)
      winter_rule2.setApplyFriday(true)      
      cloned_day.setParent(winter_rule2)



      # add design days to array
      summer_design = schedule.summerDesignDaySchedule
      winter_design = schedule.winterDesignDaySchedule
      profiles << summer_design
      profiles << winter_design
    end
  end


    # push schedules to hash to avoid making unnecessary duplicates
    clg_set_schs = {}
    htg_set_schs = {}

    # get spaces
    thermostats = model.getThermostatSetpointDualSetpoints
    thermostats.each do |thermostat|
      # setup new cooling setpoint schedule
      clg_set_sch = thermostat.coolingSetpointTemperatureSchedule
      if !clg_set_sch.empty?
        # clone of not alredy in hash
        if clg_set_schs.key?(clg_set_sch.get.name.to_s)
          new_clg_set_sch = clg_set_schs[clg_set_sch.get.name.to_s]
        else
          new_clg_set_sch = clg_set_sch.get.clone(model)
          new_clg_set_sch = new_clg_set_sch.to_Schedule.get
          new_clg_set_sch_name = new_clg_set_sch.setName("#{new_clg_set_sch.name} adjusted by #{cooling_adjustment_ip}")

          # add to the hash
          clg_set_schs[clg_set_sch.get.name.to_s] = new_clg_set_sch
        end
        # hook up clone to thermostat
        thermostat.setCoolingSetpointTemperatureSchedule(new_clg_set_sch)
      else
        runner.registerWarning("Thermostat '#{thermostat.name}' doesn't have a cooling setpoint schedule")
      end

      # setup new heating setpoint schedule
      htg_set_sch = thermostat.heatingSetpointTemperatureSchedule
      if !htg_set_sch.empty?
        # clone of not already in hash
        if htg_set_schs.key?(htg_set_sch.get.name.to_s)
          new_htg_set_sch = htg_set_schs[htg_set_sch.get.name.to_s]
        else
          new_htg_set_sch = htg_set_sch.get.clone(model)
          new_htg_set_sch = new_htg_set_sch.to_Schedule.get
          new_htg_set_sch_name = new_htg_set_sch.setName("#{new_htg_set_sch.name} adjusted by #{heating_adjustment_ip}")

          # add to the hash
          htg_set_schs[htg_set_sch.get.name.to_s] = new_htg_set_sch
        end
        # hook up clone to thermostat
        thermostat.setHeatingSetpointTemperatureSchedule(new_htg_set_sch)
      else
        runner.registerWarning("Thermostat '#{thermostat.name}' doesn't have a heating setpoint schedule.")
      end
    end

    # setting up variables to use for initial and final condition
    clg_sch_set_values = [] # may need to flatten this
    htg_sch_set_values = [] # may need to flatten this
    final_clg_sch_set_values = []
    final_htg_sch_set_values = []

    # consider issuing a warning if the model has un-conditioned thermal zones (no ideal air loads or hvac)
    zones = model.getThermalZones
    zones.each do |zone|
      # if you have a thermostat but don't have ideal air loads or zone equipment then issue a warning
      if !zone.thermostatSetpointDualSetpoint.empty? && !zone.useIdealAirLoads && (zone.equipment.size <= 0)
        runner.registerWarning("Thermal zone '#{zone.name}' has a thermostat but does not appear to be conditioned.")
      end
    end

    # make cooling schedule adjustments and rename. Put in check to skip and warn if schedule not ruleset
    
    clg_set_schs.each do |k, v| # old name and new object for schedule
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
        ######################################################################
        ############### to add a new rule to cooling setpoint schedule for the Winter season #############

        runner.registerInfo("Cooling sch rule length #{rules.length}")


        if rules.length > 0
          cloned_day_summer = rules[0].daySchedule.clone(model)
          cloned_day_winter = rules[0].daySchedule.clone(model)
          cloned_day_winter2 = rules[0].daySchedule.clone(model)
        elsif rules.length == 0
          cloned_day_summer = default_rule.clone(model)
          cloned_day_winter = default_rule.clone(model)
          cloned_day_winter2 = default_rule.clone(model)
        end

        winterStartMonth1 = OpenStudio::MonthOfYear.new(winter_start_month1)
        winterEndMonth1 = OpenStudio::MonthOfYear.new(winter_end_month1)
        startDate = OpenStudio::Date.new(winterStartMonth1, 1)
        endDate = OpenStudio::Date.new(winterEndMonth1, 30)
        winter_rule1 = OpenStudio::Model::ScheduleRule.new(schedule)
        winter_rule1.setStartDate(startDate)
        winter_rule1.setEndDate(endDate)
        winter_rule1.setApplyMonday(true)
        winter_rule1.setApplyTuesday(true)
        winter_rule1.setApplyWednesday(true)
        winter_rule1.setApplyThursday(true)
        winter_rule1.setApplyFriday(true)
        cloned_day_winter.setParent(winter_rule1)


        winterStartMonth2 = OpenStudio::MonthOfYear.new(winter_start_month2)
        winterEndMonth2 = OpenStudio::MonthOfYear.new(winter_end_month2)
        startDate = OpenStudio::Date.new(winterStartMonth2, 1)
        endDate = OpenStudio::Date.new(winterEndMonth2, 30)
        winter_rule2 = OpenStudio::Model::ScheduleRule.new(schedule)
        winter_rule2.setStartDate(startDate)
        winter_rule2.setEndDate(endDate)
        winter_rule2.setApplyMonday(true)
        winter_rule2.setApplyTuesday(true)
        winter_rule2.setApplyWednesday(true)
        winter_rule2.setApplyThursday(true)
        winter_rule2.setApplyFriday(true)

        cloned_day_winter2.setParent(winter_rule2)
        ######################################################################
        ## to add a new rule to cooling setpoint schedule for pre-cooling in the Summer season
        
        summerStartMonth = OpenStudio::MonthOfYear.new(summer_start_month)
        summerEndMonth = OpenStudio::MonthOfYear.new(summer_end_month)
        startDate = OpenStudio::Date.new(summerStartMonth, 1)
        endDate = OpenStudio::Date.new(summerEndMonth, 30)

        #cloned_day = rules[0].daySchedule.clone(model)

        summer_rule = OpenStudio::Model::ScheduleRule.new(schedule)
        summer_rule.setStartDate(startDate)
        summer_rule.setEndDate(endDate)
        summer_rule.setApplyMonday(true)
        summer_rule.setApplyTuesday(true)
        summer_rule.setApplyWednesday(true)
        summer_rule.setApplyThursday(true)
        summer_rule.setApplyFriday(true)
        cloned_day_summer.setParent(summer_rule)

        summer_day = summer_rule.daySchedule
        day_time_vector = summer_day.times
        day_value_vector = summer_day.values
        clg_sch_set_values << day_value_vector
        summer_day.clearValues
        count = 0
        for i in 0..(day_time_vector.size - 1)
          if day_time_vector[i]>shift_time1&&day_time_vector[i]<shift_time2 && count == 0
          v_si = OpenStudio::Quantity.new(day_value_vector[i], temperature_si_unit)
          v_ip = OpenStudio.convert(v_si, temperature_ip_unit).get
          target_v_ip = v_ip + cooling_adjustment_ip
          target_temp_si = OpenStudio.convert(target_v_ip, temperature_si_unit).get
          summer_day.addValue(shift_time1, day_value_vector[i])
          summer_day.addValue(day_time_vector[i],target_temp_si.value)
          count=1
          elsif day_time_vector[i]>shift_time2 && count == 0
          v_si = OpenStudio::Quantity.new(day_value_vector[i], temperature_si_unit)
          v_ip = OpenStudio.convert(v_si, temperature_ip_unit).get
          target_v_ip = v_ip + cooling_adjustment_ip
          target_temp_si = OpenStudio.convert(target_v_ip, temperature_si_unit).get
          summer_day.addValue(shift_time1,day_value_vector[i])
          summer_day.addValue(shift_time2,target_temp_si.value)
          summer_day.addValue(day_time_vector[i],day_value_vector[i])
          count = 2
          elsif day_time_vector[i]>shift_time1 && day_time_vector[i]<=shift_time2 && count==1
          v_si = OpenStudio::Quantity.new(day_value_vector[i], temperature_si_unit)
          v_ip = OpenStudio.convert(v_si, temperature_ip_unit).get
          target_v_ip = v_ip + cooling_adjustment_ip
          target_temp_si = OpenStudio.convert(target_v_ip, temperature_si_unit).get
          summer_day.addValue(day_time_vector[i], day_value_vector[i])
          elsif day_time_vector[i]>shift_time2 && count == 1
          v_si = OpenStudio::Quantity.new(day_value_vector[i], temperature_si_unit)
          v_ip = OpenStudio.convert(v_si, temperature_ip_unit).get
          target_v_ip = v_ip + cooling_adjustment_ip
          target_temp_si = OpenStudio.convert(target_v_ip, temperature_si_unit).get
          summer_day.addValue(shift_time2, target_temp_si)
          summer_day.addValue(day_time_vector[i], day_value_vector[i])
          count=2
          else 
          v_si = OpenStudio::Quantity.new(day_value_vector[i], temperature_si_unit)
          v_ip = OpenStudio.convert(v_si, temperature_ip_unit).get
          target_v_ip = v_ip
          target_temp_si = OpenStudio.convert(target_v_ip, temperature_si_unit).get
          summer_day.addValue(day_time_vector[i], target_temp_si.value)
          end

        end
        final_clg_sch_set_values << summer_day.values
        # add design days to array
        if alter_design_days == true
          summer_design = schedule.summerDesignDaySchedule
          winter_design = schedule.winterDesignDaySchedule
          profiles << summer_design
          # profiles << winter_design
        end

        ######################################################################
      else
        runner.registerWarning("Schedule '#{k}' isn't a ScheduleRuleset object and won't be altered by this measure.")
        v.remove # remove un-used clone
      end
    end
    
    # make heating schedule adjustments and rename. Put in check to skip and warn if schedule not ruleset
    htg_set_schs.each do |k, v| # old name and new object for schedule
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

        ###########
        runner.registerInfo("Heating sch rule length #{rules.length}")


        if rules.length > 1
          cloned_day_summer = rules[0].daySchedule.clone(model)
          cloned_day_winter = rules[0].daySchedule.clone(model)
        elsif rules.length == 0
          cloned_day_summer = default_rule.clone(model)
          cloned_day_winter = default_rule.clone(model)
        end

        summerStartMonth = OpenStudio::MonthOfYear.new(summer_start_month)
        summerEndMonth = OpenStudio::MonthOfYear.new(summer_end_month)
        startDate = OpenStudio::Date.new(summerStartMonth, 1)
        endDate = OpenStudio::Date.new(summerEndMonth, 30)
        cloned_day_summer = default_rule.clone(model)
        summer_rule = OpenStudio::Model::ScheduleRule.new(schedule)
        summer_rule.setStartDate(startDate)
        summer_rule.setEndDate(endDate)
        summer_rule.setApplyMonday(true)
        summer_rule.setApplyTuesday(true)
        summer_rule.setApplyWednesday(true)
        summer_rule.setApplyThursday(true)
        summer_rule.setApplyFriday(true)
        cloned_day_summer.setParent(summer_rule)

        ###############

        ## to add a new rule to cooling setpoint schedule for pre-cooling in the Summer season
        
        winterStartMonth = OpenStudio::MonthOfYear.new(winter_start_month1)
        winterEndMonth = OpenStudio::MonthOfYear.new(winter_end_month1)
        startDate = OpenStudio::Date.new(winterStartMonth, 1)
        endDate = OpenStudio::Date.new(winterEndMonth, 30)
        winter_rule1 = OpenStudio::Model::ScheduleRule.new(schedule)
        winter_rule1.setStartDate(startDate)
        winter_rule1.setEndDate(endDate)
        winter_rule1.setApplyMonday(true)
        winter_rule1.setApplyTuesday(true)
        winter_rule1.setApplyWednesday(true)
        winter_rule1.setApplyThursday(true)
        winter_rule1.setApplyFriday(true)
        cloned_day_winter.setParent(winter_rule1)

        winter_day1 = winter_rule1.daySchedule
        day_time_vector = winter_day1.times
        day_value_vector = winter_day1.values
        htg_sch_set_values << day_value_vector

        winter_day1.clearValues
        count = 0


        for i in 0..(day_time_vector.size - 1)
          if day_time_vector[i]>shift_time4&&day_time_vector[i]<shift_time5 && count == 0
          v_si = OpenStudio::Quantity.new(day_value_vector[i], temperature_si_unit)
          v_ip = OpenStudio.convert(v_si, temperature_ip_unit).get
          target_v_ip = v_ip + heating_adjustment_ip
          target_temp_si = OpenStudio.convert(target_v_ip, temperature_si_unit).get
          winter_day1.addValue(shift_time4, day_value_vector[i])
          winter_day1.addValue(day_time_vector[i],target_temp_si.value)
          count=1
          elsif day_time_vector[i]>shift_time5 && count == 0
          v_si = OpenStudio::Quantity.new(day_value_vector[i], temperature_si_unit)
          v_ip = OpenStudio.convert(v_si, temperature_ip_unit).get
          target_v_ip = v_ip + heating_adjustment_ip
          target_temp_si = OpenStudio.convert(target_v_ip, temperature_si_unit).get
          winter_day1.addValue(shift_time4,day_value_vector[i])
          winter_day1.addValue(shift_time5,target_temp_si.value)
          winter_day1.addValue(day_time_vector[i],day_value_vector[i])
          count = 2
          elsif day_time_vector[i]>shift_time4 && day_time_vector[i]<=shift_time5 && count==1
          v_si = OpenStudio::Quantity.new(day_value_vector[i], temperature_si_unit)
          v_ip = OpenStudio.convert(v_si, temperature_ip_unit).get
          target_v_ip = v_ip + heating_adjustment_ip
          target_temp_si = OpenStudio.convert(target_v_ip, temperature_si_unit).get
          winter_day1.addValue(day_time_vector[i], day_value_vector[i])
          htgvalues << target_temp_si.value
          elsif day_time_vector[i]>shift_time5 && count == 1
          v_si = OpenStudio::Quantity.new(day_value_vector[i], temperature_si_unit)
          v_ip = OpenStudio.convert(v_si, temperature_ip_unit).get
          target_v_ip = v_ip + heating_adjustment_ip
          target_temp_si = OpenStudio.convert(target_v_ip, temperature_si_unit).get
          winter_day1.addValue(shift_time5, target_temp_si)
          winter_day1.addValue(day_time_vector[i], day_value_vector[i])
          count=2
          else 
          v_si = OpenStudio::Quantity.new(day_value_vector[i], temperature_si_unit)
          v_ip = OpenStudio.convert(v_si, temperature_ip_unit).get
          target_v_ip = v_ip
          target_temp_si = OpenStudio.convert(target_v_ip, temperature_si_unit).get
          winter_day1.addValue(day_time_vector[i], target_temp_si.value)
          end
        end
        final_htg_sch_set_values << winter_day1.values


        winterStartMonth = OpenStudio::MonthOfYear.new(winter_start_month2)
        winterEndMonth = OpenStudio::MonthOfYear.new(winter_end_month2)
        startDate = OpenStudio::Date.new(winterStartMonth, 1)
        endDate = OpenStudio::Date.new(winterEndMonth, 30)
        cloned_day_winter2 = winter_day1.clone(model)
        winter_rule2 = OpenStudio::Model::ScheduleRule.new(schedule)
        winter_rule2.setStartDate(startDate)
        winter_rule2.setEndDate(endDate)
        winter_rule2.setApplyMonday(true)
        winter_rule2.setApplyTuesday(true)
        winter_rule2.setApplyWednesday(true)
        winter_rule2.setApplyThursday(true)
        winter_rule2.setApplyFriday(true)

        cloned_day_winter2.setParent(winter_rule2)

        # add design days to array
        if alter_design_days == true
          summer_design = schedule.summerDesignDaySchedule
          winter_design = schedule.winterDesignDaySchedule
          # profiles << summer_design
          profiles << winter_design
        end

      else
        runner.registerWarning("Schedule '#{k}' isn't a ScheduleRuleset object and won't be altered by this measure.")
        v.remove # remove un-used clone
      end
    end


    # get min and max heating and cooling and convert to IP
    clg_sch_set_values = clg_sch_set_values.flatten
    htg_sch_set_values = htg_sch_set_values.flatten

    # set NA flag if can't get values for schedules (e.g. if all compact)
    applicable_flag = false

    # get min and max if values exist
    if !clg_sch_set_values.empty?
      min_clg_si = OpenStudio::Quantity.new(clg_sch_set_values.min, temperature_si_unit)
      max_clg_si = OpenStudio::Quantity.new(clg_sch_set_values.max, temperature_si_unit)
      min_clg_ip = OpenStudio.convert(min_clg_si, temperature_ip_unit).get
      max_clg_ip = OpenStudio.convert(max_clg_si, temperature_ip_unit).get
      applicable_flag = true
    else
      min_clg_ip = 'NA'
      max_clg_ip = 'NA'
    end

    # get min and max if values exist
    if !htg_sch_set_values.empty?
      min_htg_si = OpenStudio::Quantity.new(htg_sch_set_values.min, temperature_si_unit)
      max_htg_si = OpenStudio::Quantity.new(htg_sch_set_values.max, temperature_si_unit)
      min_htg_ip = OpenStudio.convert(min_htg_si, temperature_ip_unit).get
      max_htg_ip = OpenStudio.convert(max_htg_si, temperature_ip_unit).get
      applicable_flag = true
    else
      min_htg_ip = 'NA'
      max_htg_ip = 'NA'
    end

    # not applicable if no schedules can be altered
    if applicable_flag == false
      runner.registerAsNotApplicable('No thermostat schedules in the models could be altered.')
    end

    # reporting initial condition of model
    starting_spaces = model.getSpaces
    runner.registerInitialCondition("Initial cooling setpoints used in the model range from #{min_clg_ip} to #{max_clg_ip}. Initial heating setpoints used in the model range from #{min_htg_ip} to #{max_htg_ip}.")

    # get min and max heating and cooling and convert to IP for final
    final_clg_sch_set_values = final_clg_sch_set_values.flatten
    final_htg_sch_set_values = final_htg_sch_set_values.flatten

    if !clg_sch_set_values.empty?
      final_min_clg_si = OpenStudio::Quantity.new(final_clg_sch_set_values.min, temperature_si_unit)
      final_max_clg_si = OpenStudio::Quantity.new(final_clg_sch_set_values.max, temperature_si_unit)
      final_min_clg_ip = OpenStudio.convert(final_min_clg_si, temperature_ip_unit).get
      final_max_clg_ip = OpenStudio.convert(final_max_clg_si, temperature_ip_unit).get
    else
      final_min_clg_ip = 'NA'
      final_max_clg_ip = 'NA'
    end

    # get min and max if values exist
    if !htg_sch_set_values.empty?
      final_min_htg_si = OpenStudio::Quantity.new(final_htg_sch_set_values.min, temperature_si_unit)
      final_max_htg_si = OpenStudio::Quantity.new(final_htg_sch_set_values.max, temperature_si_unit)
      final_min_htg_ip = OpenStudio.convert(final_min_htg_si, temperature_ip_unit).get
      final_max_htg_ip = OpenStudio.convert(final_max_htg_si, temperature_ip_unit).get
    else
      final_min_htg_ip = 'NA'
      final_max_htg_ip = 'NA'
    end

    # reporting final condition of model
    finishing_spaces = model.getSpaces
    runner.registerFinalCondition("Final cooling setpoints used in the model range from #{final_min_clg_ip} to #{final_max_clg_ip}. Final heating setpoints used in the model range from #{final_min_htg_ip} to #{final_max_htg_ip}.\n The cooling setpoints are increased by #{cooling_adjustment}F，from #{starttime_cooling} to #{endtime_cooling}. \n The heating setpoints are decreased by #{0-heating_adjustment}F，from #{starttime_heating} to #{endtime_heating}.")

    return true
  end
end

# this allows the measure to be used by the application
PreCoolingAndHeating.new.registerWithApplication
