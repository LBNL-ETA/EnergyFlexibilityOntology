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
    return 'Pre Cooling & Heating by Certain Time Period and Thermostat Setpoint'
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
    cooling_adjustment.setDefaultValue(2.0)
    args << cooling_adjustment

    
    # make an argument for adjustment to heating setpoint
    heating_adjustment = OpenStudio::Measure::OSArgument.makeDoubleArgument('heating_adjustment', true)
    heating_adjustment.setDisplayName('Degrees Fahrenheit to Adjust heating Setpoint By')
    heating_adjustment.setDefaultValue(-2.0)
    args << heating_adjustment

    # make an argument for the start time of pre-cooling/heating
    starttime = OpenStudio::Measure::OSArgument.makeStringArgument('starttime', true)
    starttime.setDisplayName('Start Time for Pre-cooling/heating')
    starttime.setDefaultValue('07:00:00')
    args << starttime

    # make an argument for the end time of pre-cooling/heating
    endtime = OpenStudio::Measure::OSArgument.makeStringArgument('endtime', true)
    endtime.setDisplayName('End Time for Pre-cooling/heating')
    endtime.setDefaultValue('11:00:00')
    args << endtime

    # make an argument for adjustment to heating setpoint
    alter_design_days = OpenStudio::Measure::OSArgument.makeBoolArgument('alter_design_days', true)
    alter_design_days.setDisplayName('Alter Design Day Thermostats')
    alter_design_days.setDefaultValue(false)
    args << alter_design_days

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
    starttime = runner.getStringArgumentValue('starttime', user_arguments)
    endtime = runner.getStringArgumentValue('endtime', user_arguments)
    
    if starttime.to_f > endtime.to_f
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

    shift_time1 = OpenStudio::Time.new(starttime)
    shift_time2 = OpenStudio::Time.new(endtime)
    shift_time3 = OpenStudio::Time.new(0,6,0,0)
    # define starting units
    cooling_adjustment_ip = OpenStudio::Quantity.new(cooling_adjustment, temperature_ip_unit)
    heating_adjustment_ip = OpenStudio::Quantity.new(heating_adjustment, temperature_ip_unit)

  if shift_time1 < (shift_time3)  #HVAC Operation Schedule will be altered to achieve the pre-cooling/heating
    schedules = []
    schedule_args = model.getScheduleRulesets
    schedule_args.each do |schedule_arg|
      if schedule_arg.name.to_s == "OfficeMedium HVACOperationSchd"
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

      # add design days to array
      summer_design = schedule.summerDesignDaySchedule
      winter_design = schedule.winterDesignDaySchedule
      profiles << summer_design
      profiles << winter_design

      # give info messages as I change specific profiles
      runner.registerInfo("#{schedule.name} has changed to achieve the pre-cooling/heating requirement.")

      # edit profiles
      profiles.each do |day_sch|
        times = day_sch.times
        values = day_sch.values

        # time objects to use in meausre
        time_0 = OpenStudio::Time.new(0, 0, 0, 0)
        time_24 =  OpenStudio::Time.new(0, 24, 0, 0)

        # arrays for values to avoid overlap conflict of times
        new_times = []
        new_values = []

           # push times to array
        times.each do |time|
           new_times << time
         end

        # push values to array
        values.each do |value|
          new_values << value
        end

        # clear values
        day_sch.clearValues
       day_sch.addValue(shift_time1,0)
        # make new values
        for i in 1..(new_values.length - 1)
          day_sch.addValue(new_times[i], new_values[i])
        end
      end
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

        # add design days to array
        if alter_design_days == true
          summer_design = schedule.summerDesignDaySchedule
          winter_design = schedule.winterDesignDaySchedule
          profiles << summer_design
          # profiles << winter_design
        end

        profiles.each do |sch_day|
          day_time_vector = sch_day.times
          day_value_vector = sch_day.values
          clg_sch_set_values << day_value_vector
          sch_day.clearValues
          count = 0
          for i in 0..(day_time_vector.size - 1)
            if day_time_vector[i]>shift_time1&&day_time_vector[i]<shift_time2 && count == 0
            v_si = OpenStudio::Quantity.new(day_value_vector[i], temperature_si_unit)
            v_ip = OpenStudio.convert(v_si, temperature_ip_unit).get
            target_v_ip = v_ip + cooling_adjustment_ip
            target_temp_si = OpenStudio.convert(target_v_ip, temperature_si_unit).get
            sch_day.addValue(shift_time1, day_value_vector[i])
            sch_day.addValue(day_time_vector[i],target_temp_si.value)
            count=1
            elsif day_time_vector[i]>shift_time2 && count == 0
            v_si = OpenStudio::Quantity.new(day_value_vector[i], temperature_si_unit)
            v_ip = OpenStudio.convert(v_si, temperature_ip_unit).get
            target_v_ip = v_ip + cooling_adjustment_ip
            target_temp_si = OpenStudio.convert(target_v_ip, temperature_si_unit).get
            sch_day.addValue(shift_time1,day_value_vector[i])
            sch_day.addValue(shift_time2,target_temp_si.value)
            sch_day.addValue(day_time_vector[i],day_value_vector[i])
            count = 2
            elsif day_time_vector[i]>shift_time1 && day_time_vector[i]<=shift_time2 && count==1
            v_si = OpenStudio::Quantity.new(day_value_vector[i], temperature_si_unit)
            v_ip = OpenStudio.convert(v_si, temperature_ip_unit).get
            target_v_ip = v_ip + cooling_adjustment_ip
            target_temp_si = OpenStudio.convert(target_v_ip, temperature_si_unit).get
            sch_day.addValue(day_time_vector[i], day_value_vector[i])
            elsif day_time_vector[i]>shift_time2 && count == 1
            v_si = OpenStudio::Quantity.new(day_value_vector[i], temperature_si_unit)
            v_ip = OpenStudio.convert(v_si, temperature_ip_unit).get
            target_v_ip = v_ip + cooling_adjustment_ip
            target_temp_si = OpenStudio.convert(target_v_ip, temperature_si_unit).get
            sch_day.addValue(shift_time2, target_temp_si)
            sch_day.addValue(day_time_vector[i], day_value_vector[i])
            count=2
            else 
            v_si = OpenStudio::Quantity.new(day_value_vector[i], temperature_si_unit)
            v_ip = OpenStudio.convert(v_si, temperature_ip_unit).get
            target_v_ip = v_ip
            target_temp_si = OpenStudio.convert(target_v_ip, temperature_si_unit).get
            sch_day.addValue(day_time_vector[i], target_temp_si.value)
            end
          end
          final_clg_sch_set_values << sch_day.values
        end
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

        # add design days to array
        if alter_design_days == true
          summer_design = schedule.summerDesignDaySchedule
          winter_design = schedule.winterDesignDaySchedule
          # profiles << summer_design
          profiles << winter_design
        end

        profiles.each do |sch_day|
          day_time_vector = sch_day.times
          day_value_vector = sch_day.values
          htg_sch_set_values << day_value_vector
          sch_day.clearValues
          count = 0
          for i in 0..(day_time_vector.size - 1)
            if day_time_vector[i]>shift_time1&&day_time_vector[i]<shift_time2 && count == 0
            v_si = OpenStudio::Quantity.new(day_value_vector[i], temperature_si_unit)
            v_ip = OpenStudio.convert(v_si, temperature_ip_unit).get
            target_v_ip = v_ip + heating_adjustment_ip
            target_temp_si = OpenStudio.convert(target_v_ip, temperature_si_unit).get
            sch_day.addValue(shift_time1, day_value_vector[i])
            sch_day.addValue(day_time_vector[i],target_temp_si.value)
            count=1
            elsif day_time_vector[i]>shift_time2 && count == 0
            v_si = OpenStudio::Quantity.new(day_value_vector[i], temperature_si_unit)
            v_ip = OpenStudio.convert(v_si, temperature_ip_unit).get
            target_v_ip = v_ip + heating_adjustment_ip
            target_temp_si = OpenStudio.convert(target_v_ip, temperature_si_unit).get
            sch_day.addValue(shift_time1,day_value_vector[i])
            sch_day.addValue(shift_time2,target_temp_si.value)
            sch_day.addValue(day_time_vector[i],day_value_vector[i])
            count = 2
            elsif day_time_vector[i]>shift_time1 && day_time_vector[i]<=shift_time2 && count==1
            v_si = OpenStudio::Quantity.new(day_value_vector[i], temperature_si_unit)
            v_ip = OpenStudio.convert(v_si, temperature_ip_unit).get
            target_v_ip = v_ip + heating_adjustment_ip
            target_temp_si = OpenStudio.convert(target_v_ip, temperature_si_unit).get
            sch_day.addValue(day_time_vector[i], day_value_vector[i])
            elsif day_time_vector[i]>shift_time2 && count == 1
            v_si = OpenStudio::Quantity.new(day_value_vector[i], temperature_si_unit)
            v_ip = OpenStudio.convert(v_si, temperature_ip_unit).get
            target_v_ip = v_ip + heating_adjustment_ip
            target_temp_si = OpenStudio.convert(target_v_ip, temperature_si_unit).get
            sch_day.addValue(shift_time2, target_temp_si)
            sch_day.addValue(day_time_vector[i], day_value_vector[i])
            count=2
            else 
            v_si = OpenStudio::Quantity.new(day_value_vector[i], temperature_si_unit)
            v_ip = OpenStudio.convert(v_si, temperature_ip_unit).get
            target_v_ip = v_ip
            target_temp_si = OpenStudio.convert(target_v_ip, temperature_si_unit).get
            sch_day.addValue(day_time_vector[i], target_temp_si.value)
            end
          end
          final_htg_sch_set_values << sch_day.values
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
    runner.registerFinalCondition("Final cooling setpoints used in the model range from #{final_min_clg_ip} to #{final_max_clg_ip}. Final heating setpoints used in the model range from #{final_min_htg_ip} to #{final_max_htg_ip}.\n The cooling setpoints are increased by #{cooling_adjustment}F，from #{starttime} to #{endtime}. \n The heating setpoints are decreased by #{0-heating_adjustment}F，from #{starttime} to #{endtime}.")

    return true
  end
end

# this allows the measure to be used by the application
PreCoolingAndHeating.new.registerWithApplication
