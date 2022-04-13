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
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class M9Example9DemandManagement < OpenStudio::Measure::ModelMeasure

  # Note this measure was specifically designed to run against xxx.osm file which includes a datacenter thermal
  # zones and generated using the 'Create Prototype Building' OpenStudio measure using the following arguments
  # Building Type: "Large Office"
  # Template: "90.1-2010"
  # Climate Zone: "ASHRAE 169-2006-5A"
  # Weather File = Chicago Ohare Intl Ap_IL_USA.epw (TMY3)
  
  # note: demand management actions will NOT affect datacenter thermal zones. 
  
  # An initial annual simulation was executed to generate the following Peak Demand (kW) information:     
  
  # Report Name: Report: BUILDING ENERGY PERFORMANCE - ELECTRICITY PEAK DEMAND
  # For: Meter
  # Custom Monthly Report 
  # Values: (a demand reduction level of 15% is used to set the demand target level) 
  
  #  Month      |   Peak Demand (kW)    |   15% reduction (Target) Peak Demand (kW)   
  # January     |   1612.51361	        |   1370.636569
  # February    |   1570.18069	        |   1334.653587
  # March       |   1691.54039	        |   1437.809332
  # April       |   2010.47742	        |   1708.905807
  # May         |   2086.2997	        |   1773.354745
  # June        |   2283.99999	        |   1941.399992
  # July        |   2304.07204	        |   1958.461234
  # August      |   2247.15181	        |   1910.079039
  # September   |   2039.76759	        |   1733.802452
  # October     |   1777.0498	        |   1510.49233
  # November    |   1880.00032	        |   1598.000272
  # December    |   1612.14196	        |   1370.320666
  
  
  #                  Table 8.2 Demand Management Adjustments by Control State
  #     Control State           |   Lighting Power Adjustment Factor      |       Cooling Thermostat Offset
  #     0 no change             |             None                        |                None
  #     1 moderately aggressive |              0.9                        |                - 0.8ºC
  #     2 more aggressive       |              0.8                        |                - 1.5ºC
  #     3 most aggressive       |              0.7                        |                - 2.0ºC
  
  

  # human readable name
  def name
    return "M9 Example 9. Demand Management"
  end
  
  # human readable description
  def description
    return "Needs to be coupled with an E+ tariff measure that includes electricity demand charges"
  end

  # human readable description of modeling approach
  def modeler_description
    return "ipsum"
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # Add a check box for specifying verbose info statements
	verbose_info_statements = OpenStudio::Ruleset::OSArgument::makeBoolArgument("verbose_info_statements", false)
	verbose_info_statements.setDisplayName("Check to allow measure to generate verbose runner.registerInfo statements.")
	verbose_info_statements.setDefaultValue(false)
	args << verbose_info_statements
    
    # Argument #1 - choice list of lighting schedules to modify use to reduce the power demand
    sch_handles = OpenStudio::StringVector.new
    sch_display_names = OpenStudio::StringVector.new

    #putting schedule names into hash
    sch_hash = {}
    model.getSchedules.each do |sch|
      sch_hash[sch.name.to_s] = sch
    end

    #looping through sorted hash of schedules
    sch_hash.sort.map do |sch_name, sch|
      if not sch.scheduleTypeLimits.empty?
        unitType = sch.scheduleTypeLimits.get.unitType
        #puts "#{sch.name}, #{unitType}"
        if unitType == "Dimensionless"
          sch_handles << sch.handle.to_s
          sch_display_names << sch_name
        end
      end
    end

    # Make a Choice Argument for the Fractional Lighting Schedule to be used for to apply demand reduction reductions to
    lighting_sch = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("lighting_sch", sch_handles, sch_display_names, true)
    lighting_sch.setDisplayName("Choose a Schedule attached to Lighting Definitons which will be altered to meet demand reduction targets. Lighting demand will be reduced for datacenter thermal zones if this schedule is attached to them.")
    args << lighting_sch    
 
    # Argument #2 - choice list of T-stat schedules to modify the cooling setpiont use to reduce the power demand
    sch_handles2 = OpenStudio::StringVector.new
    sch_display_names2 = OpenStudio::StringVector.new

    #putting schedule names into hash
    sch_hash2 = {}
    model.getSchedules.each do |sch_2|
      sch_hash2[sch_2.name.to_s] = sch_2
    end

    #looping through sorted hash of schedules
    sch_hash2.sort.map do |sch_name_2, sch_2|
      if not sch_2.scheduleTypeLimits.empty?
        unitType = sch_2.scheduleTypeLimits.get.unitType
        if unitType == "Temperature"
          sch_handles2 << sch_2.handle.to_s
          sch_display_names2 << sch_name_2
        end
      end
    end

    # Make a Choice Argument for the Cooling T=stat Schedule to be used for to apply demand reduction reductions to
    clg_tstat_sch = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("clg_tstat_sch", sch_handles2, sch_display_names2, true)
    clg_tstat_sch.setDisplayName("Choose a Temp Schedule representing the Clg T-Stat Sch to be reduced to meet demand reduction targets. The chosen schedule should not serve datacenter areas, as they are not effected by demand response actions.")
    args << clg_tstat_sch    
    
    # Make a double precision argument for the relative electrical demand reduction target 
    relative_demand_reduction_target = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("relative_demand_reduction_target",true)
    relative_demand_reduction_target.setDisplayName("Relative Demand Reduction Target")
    relative_demand_reduction_target.setDescription("% of Whole Building Demand Reduction expected (Min 0 - Max 0.35).")
    relative_demand_reduction_target.setDefaultValue(0.15)
    relative_demand_reduction_target.setMinValue(0.0)
    relative_demand_reduction_target.setMaxValue(0.35)
    args << relative_demand_reduction_target

     # Make a choice argument for setting EMS InternalVariableAvailabilityDictionaryReporting value
    int_var_avail_dict_rep_chs = OpenStudio::StringVector.new
    int_var_avail_dict_rep_chs << 'None'
    int_var_avail_dict_rep_chs << 'NotByUniqueKeyNames'
    int_var_avail_dict_rep_chs << 'Verbose'
     
    internal_variable_availability_dictionary_reporting = OpenStudio::Measure::OSArgument.makeChoiceArgument('internal_variable_availability_dictionary_reporting', int_var_avail_dict_rep_chs, true)
    internal_variable_availability_dictionary_reporting.setDisplayName('Level of output reporting related to the EMS internal variables that are available.')
    internal_variable_availability_dictionary_reporting.setDefaultValue('None')
    args << internal_variable_availability_dictionary_reporting
    
    # Make a choice argument for setting EMSRuntimeLanguageDebugOutputLevel value
    ems_runtime_language_debug_level_chs = OpenStudio::StringVector.new
    ems_runtime_language_debug_level_chs << 'None'
    ems_runtime_language_debug_level_chs << 'ErrorsOnly'
    ems_runtime_language_debug_level_chs << 'Verbose'
    
    ems_runtime_language_debug_output_level = OpenStudio::Measure::OSArgument.makeChoiceArgument('ems_runtime_language_debug_output_level', ems_runtime_language_debug_level_chs, true)
    ems_runtime_language_debug_output_level.setDisplayName('Level of output reporting related to the execution of EnergyPlus Runtime Language, written to .edd file.')
    ems_runtime_language_debug_output_level.setDefaultValue('None')
    args << ems_runtime_language_debug_output_level
    
    # Make a choice argument for setting EMS ActuatorAvailabilityDictionaryReportingvalue
    actuator_avail_dict_rep_chs = OpenStudio::StringVector.new
    actuator_avail_dict_rep_chs << 'None'
    actuator_avail_dict_rep_chs << 'NotByUniqueKeyNames'
    actuator_avail_dict_rep_chs << 'Verbose'
    
    actuator_availability_dictionary_reporting = OpenStudio::Measure::OSArgument.makeChoiceArgument('actuator_availability_dictionary_reporting', actuator_avail_dict_rep_chs, true)
    actuator_availability_dictionary_reporting.setDisplayName('Level of output reporting related to the EMS actuators that are available.')
    actuator_availability_dictionary_reporting.setDefaultValue('None')
    args << actuator_availability_dictionary_reporting
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    verbose_info_statements = runner.getBoolArgumentValue("verbose_info_statements",user_arguments)
    lighting_sch = runner.getOptionalWorkspaceObjectChoiceValue("lighting_sch",user_arguments,model) #model is passed in because of argument type
    clg_tstat_sch = runner.getOptionalWorkspaceObjectChoiceValue("clg_tstat_sch",user_arguments,model) #model is passed in because of argument type
    relative_demand_reduction_target = runner.getDoubleArgumentValue("relative_demand_reduction_target",user_arguments)
    internal_variable_availability_dictionary_reporting = runner.getStringArgumentValue('internal_variable_availability_dictionary_reporting', user_arguments)
    ems_runtime_language_debug_output_level = runner.getStringArgumentValue('ems_runtime_language_debug_output_level', user_arguments)
    actuator_availability_dictionary_reporting = runner.getStringArgumentValue('actuator_availability_dictionary_reporting', user_arguments)
    
    runner.registerInitialCondition("Measure began with #{model.getEnergyManagementSystemSensors.count} EMS sensors, #{model.getEnergyManagementSystemActuators.count} EMS Actuators, #{model.getEnergyManagementSystemPrograms.count} EMS Programs, #{model.getEnergyManagementSystemSubroutines.count} EMS Subroutines, #{model.getEnergyManagementSystemProgramCallingManagers.count} EMS Program Calling Manager objects")
     
    # declare arrays for proper scope
    ems_lights_actuator_array = []
    ems_lights_internal_variable_array = []
    
    # Get the selected cooling lighting schedule
    ltg_schedule = nil
    if lighting_sch.is_initialized
      if lighting_sch.get.to_Schedule.is_initialized
        ltg_schedule = lighting_sch.get.to_Schedule.get
        ltg_sch_clone = ltg_schedule.clone
      else
        runner.registerError("Script Error - lighting schedule argument not showing up as schedule.")
        return false
      end
    else
      handle = runner.getStringArgumentValue("lighting_sch",user_arguments)
      if handle.empty?
        runner.registerError("No schedule was chosen.")
      else
        runner.registerError("The selected schedule with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    end
    
    # Get the selected cooling t-stat schedule
    clg_schedule = nil
    if clg_tstat_sch.is_initialized
      if clg_tstat_sch.get.to_Schedule.is_initialized
        clg_schedule = clg_tstat_sch.get.to_Schedule.get
        clg_sch_clone = clg_schedule.clone
      else
        runner.registerError("Script Error - cooling t-stat achedule argument not showing up as schedule.")
        return false
      end
    else
      handle = runner.getStringArgumentValue("clg_tstat_sch",user_arguments)
      if handle.empty?
        runner.registerError("No schedule was chosen.")
      else
        runner.registerError("The selected schedule with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    end 
    
    target_demand_value = 1.0 - relative_demand_reduction_target
    
    # Values for the peak demand array are documented in lines 14 - 33 above
    peak_demand_array = [1612.51361, 1570.18069, 1691.54039, 2010.477420, 2086.2997, 2283.99999, 2304.07204, 2247.15181, 2039.76759, 1777.0498, 1880.00032, 1612.14196]
    
    # Create new EnergyManagementSystem:GlobalVariable object and configure to hold the input kW level target
    ems_argument_target_demand_gv = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "argTargetDemand")
    
    # Create new EnergyManagementSystem:GlobalVariable object and configure to hold the current Demand Manager State
    ems_demand_manager_state_gv = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "argDmndMngrState")
    
    # Create new EnergyManagementSystem:GlobalVariable object and configure to hold the Input kW level current
    ems_argument_current_demand_gv = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "argCrntDmnd")

    # Create new EnergyManagementSystem:GlobalVariable object and configure to hold the current demand trend direction
    ems_argument_trend_direction_gv = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "argTrendDirection")
    
    # Create new EnergyManagementSystem:Actuator object for changing the value of the cooling setpoint schedule 
    ems_clg_setpt_sched_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(clg_sch_clone ,'Schedule:Year','Schedule Value')
    ems_clg_setpt_sched_actuator.setName("Set_Cooling_Setpoint_Sched")
    runner.registerInfo("An EMS Actuator object named '#{ems_clg_setpt_sched_actuator.name}' representing the cooling setpoing schedule value that will be raised to reduce electrical demand was added to the model.") 
            
    # create new EnergyManagementSystem:Actuator and paired EnergyManagementSystem:InternalVariable objects for lights associated with the "WholeBuilding - Lg Office" Spacetype 
    model.getLightss.each do |lights|
        
    spacetype = lights.spaceType.get                          # .spaceType returns an optional parent SpaceType
      if spacetype.name.get == "Office WholeBuilding - Lg Office"
        spaces_with_lights = spacetype.spaces                   # .spaces returns a vector of spaces having this space type, including spaces that inherit this space type.  
        tz = []
        spaces_with_lights.each do |space|
          if (space.thermalZone)
            tz = space.thermalZone.get
            ems_lights_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(lights ,'Lights','Electric Power Level', tz)
            ems_lights_actuator.setName("Set_#{tz.name}_Lights".gsub("-","_"))
            runner.registerInfo("An EMS Actuator object named '#{ems_lights_actuator.name}' representing the Lighting Power Level associated with thermal zone named '#{tz.name}' was added to the model.") 
            ems_lights_actuator_array << ems_lights_actuator
          
            ems_lights_internal_variable = OpenStudio::Model::EnergyManagementSystemInternalVariable.new(model, 'Lighting Power Design Level')
            ems_lights_internal_variable.setName("#{tz.name}_Lights".gsub("-","_"))
            ems_lights_internal_variable.setInternalDataIndexKeyName("#{tz.name} #{lights.name}")
            runner.registerInfo("An EMS Internal Variable named '#{ems_lights_internal_variable.name}' representing the Lighting Power Level associated with thermal zone named '#{tz.name}' was added to the model.") 
            ems_lights_internal_variable_array << ems_lights_internal_variable
          end 
        end
      end
    end    
 
    # Create new EnergyManagementSystem:Sensor object representing the “Current Facility Total Electric Demand” output variable
    ems_current_facility_electric_demand_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Facility Total Electric Demand Power")
    ems_current_facility_electric_demand_sensor.setName("CurntFacilityElectDemand")
    ems_current_facility_electric_demand_sensor.setKeyName("Whole Building") 
    if verbose_info_statements == true
      runner.registerInfo("An EMS Sensor object named '#{ems_current_facility_electric_demand_sensor.name}' representing the Facility Total Electric Demand Power was added to the model.") 
    end
    
    # Create new EnergyManagementSystem:Sensor object representing the current value of the cooling setpoint schedule
    ems_clg_setpt_sched_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
    ems_clg_setpt_sched_sensor.setName("Cooling_Setpoint_Sched")
    ems_clg_setpt_sched_sensor.setKeyName("#{clg_sch_clone.name}") 
    if verbose_info_statements == true
      runner.registerInfo("An EMS Sensor object named '#{ems_clg_setpt_sched_sensor.name}' representing the value of the selected cooling T-stat schedule was added to the model.") 
     end
     
    # Create new EnergyManagementSystem:Sensor object representing the current value of the lighting schedule
    ems_ltg_setpt_sched_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
    ems_ltg_setpt_sched_sensor.setName("BLDG_LIGHT_SCH")
    ems_ltg_setpt_sched_sensor.setKeyName("#{ltg_sch_clone.name}") 
    if verbose_info_statements == true
      runner.registerInfo("An EMS Sensor object named '#{ems_ltg_setpt_sched_sensor.name}' representing the value of the selected lighting schedule was added to the model.") 
    end
    
    # Create new EnergyManagementSystem:TrendVariable object and configure to hold the current facility elec demand trend
    ems_current_facility_elec_demand_trend = OpenStudio::Model::EnergyManagementSystemTrendVariable.new(model, ems_current_facility_electric_demand_sensor)
    ems_current_facility_elec_demand_trend.setName("FacilityElectTrend")
    ems_current_facility_elec_demand_trend.setNumberOfTimestepsToBeLogged(144)
    if verbose_info_statements == true
      runner.registerInfo("An EMS Trend Variable object named '#{ems_current_facility_elec_demand_trend.name}' representing a trend of the current facility electrical demand was added to the model.") 
    end
    
    # Create new EnergyManagementSystem:TrendVariable object and configure to hold the demand state trend
    ems_demand_manager_state_trend = OpenStudio::Model::EnergyManagementSystemTrendVariable.new(model, ems_demand_manager_state_gv)
    ems_demand_manager_state_trend.setName("Demand_Mgr_State_Trend")
    ems_demand_manager_state_trend.setNumberOfTimestepsToBeLogged(48)
    if verbose_info_statements == true
      runner.registerInfo("An EMS Trend Variable object named '#{ems_demand_manager_state_trend.name}' representing the Lighting schedule that will be modified to reduce office lighting power was added to the model.") 
    end
    
    # Create new EnergyManagementSystem:Subroutine object for unsetting the demand level controls 
    ems_unset_demand_controls_subroutine = OpenStudio::Model::EnergyManagementSystemSubroutine.new(model)
    ems_unset_demand_controls_subroutine.setName("Unset_Demand_Controls")
    ems_unset_demand_controls_subroutine.addLine("SET #{ems_clg_setpt_sched_actuator.name} = Null")
    ems_lights_actuator_array.each do |ems_lights_actuator|
      ems_unset_demand_controls_subroutine.addLine("SET #{ems_lights_actuator.name} = Null")
    end
    if verbose_info_statements == true
      runner.registerInfo("An EMS Subroutine object named '#{ems_unset_demand_controls_subroutine.name}' to unset demand limiting controls was added to the model.") 
    end
    
    # Create new EnergyManagementSystem:Subroutine object for setting level1 demand control actions
    ems_set_demand_level1_controls_subroutine = OpenStudio::Model::EnergyManagementSystemSubroutine.new(model)
    ems_set_demand_level1_controls_subroutine.setName("Set_Demand_Level1_Controls")
    ems_set_demand_level1_controls_subroutine.addLine("SET #{ems_clg_setpt_sched_actuator.name} = #{ems_clg_setpt_sched_sensor.name} + 0.8")
    index = 0
    ems_lights_actuator_array.each do |ems_lights_actuator|
      internal_var = ems_lights_internal_variable_array[index] 
      ems_set_demand_level1_controls_subroutine.addLine("SET #{ems_lights_actuator.name} = 0.9 * #{internal_var.name} * #{ems_ltg_setpt_sched_sensor.name}")
      index += 1
    end
    if verbose_info_statements == true
      runner.registerInfo("An EMS Subroutine object named '#{ems_set_demand_level1_controls_subroutine.name}' to initiale level one demand reduction actions was added to the model.") 
    end
    
    # Create new EnergyManagementSystem:Subroutine object for setting level2 demand control actions
    ems_set_demand_level2_controls_subroutine = OpenStudio::Model::EnergyManagementSystemSubroutine.new(model)
    ems_set_demand_level2_controls_subroutine.setName("Set_Demand_Level1_Controls")
    ems_set_demand_level2_controls_subroutine.addLine("SET #{ems_clg_setpt_sched_actuator.name} = #{ems_clg_setpt_sched_sensor.name} + 1.5")
    index = 0
    ems_lights_actuator_array.each do |ems_lights_actuator|
      internal_var = ems_lights_internal_variable_array[index] 
      ems_set_demand_level2_controls_subroutine.addLine("SET #{ems_lights_actuator.name} = 0.8 * #{internal_var.name} * #{ems_ltg_setpt_sched_sensor.name}")
      index += 1
    end
    if verbose_info_statements == true
      runner.registerInfo("An EMS Subroutine object named '#{ems_set_demand_level2_controls_subroutine.name}' to initiale level two demand reduction actions was added to the model.") 
    end
    
    # Create new EnergyManagementSystem:Subroutine object for setting level3 demand control actions
    ems_set_demand_level3_controls_subroutine = OpenStudio::Model::EnergyManagementSystemSubroutine.new(model)
    ems_set_demand_level3_controls_subroutine.setName("Set_Demand_Level1_Controls")
    ems_set_demand_level3_controls_subroutine.addLine("SET #{ems_clg_setpt_sched_actuator.name} = #{ems_clg_setpt_sched_sensor.name} + 2")
    index = 0
    ems_lights_actuator_array.each do |ems_lights_actuator|
      internal_var = ems_lights_internal_variable_array[index] 
      ems_set_demand_level3_controls_subroutine.addLine("SET #{ems_lights_actuator.name} = 0.7 * #{internal_var.name} * #{ems_ltg_setpt_sched_sensor.name}")
      index += 1
    end
    if verbose_info_statements == true
      runner.registerInfo("An EMS Subroutine object named '#{ems_set_demand_level3_controls_subroutine.name}' to initiale level three demand reduction actions was added to the model.") 
    end
    
    # Create new EnergyManagementSystem:Subroutine object for determining the demand state (0, 1, 2, or 3) 
    ems_find_demand_state_subroutine = OpenStudio::Model::EnergyManagementSystemSubroutine.new(model)
    ems_find_demand_state_subroutine.setName("Find_Demand_State")
    ems_find_demand_state_subroutine.addLine("SET DmndStateX1 = @TrendValue #{ems_demand_manager_state_trend.name} 1")
    ems_find_demand_state_subroutine.addLine("SET DmndStateX2 = @TrendValue #{ems_demand_manager_state_trend.name} 2")
    ems_find_demand_state_subroutine.addLine("SET Level1Demand = 0.9 * #{ems_argument_target_demand_gv.name}")
    ems_find_demand_state_subroutine.addLine("SET #{ems_argument_current_demand_gv.name} = #{ems_argument_current_demand_gv.name}")
    ems_find_demand_state_subroutine.addLine("SET #{ems_argument_target_demand_gv.name} = #{ems_argument_target_demand_gv.name}")
    ems_find_demand_state_subroutine.addLine("SET #{ems_demand_manager_state_gv.name} = DmndStateX1")
    ems_find_demand_state_subroutine.addLine("IF (#{ems_argument_current_demand_gv.name} > Level1Demand) && (#{ems_argument_current_demand_gv.name} < #{ems_argument_target_demand_gv.name}) && (#{ems_argument_trend_direction_gv.name} > 0.0)")
    ems_find_demand_state_subroutine.addLine("IF DmndStateX1 <= 1.0")
    ems_find_demand_state_subroutine.addLine("SET #{ems_demand_manager_state_gv.name} = 1.0")
    ems_find_demand_state_subroutine.addLine("ELSEIF (DmndStateX1 == 2.0) && (DmndStateX2 < 2.0)")
    ems_find_demand_state_subroutine.addLine("SET #{ems_demand_manager_state_gv.name} = 2.0")
    ems_find_demand_state_subroutine.addLine("ELSEIF (DmndStateX1 == 3.0) && (DmndStateX2 == 3.0)")
    ems_find_demand_state_subroutine.addLine("SET #{ems_demand_manager_state_gv.name} = 2.0")
    ems_find_demand_state_subroutine.addLine("ELSEIF (DmndStateX1 == 3.0) && (DmndStateX2 == 2.0)")
    ems_find_demand_state_subroutine.addLine("SET #{ems_demand_manager_state_gv.name} = 3.0")
    ems_find_demand_state_subroutine.addLine("ENDIF")
    ems_find_demand_state_subroutine.addLine("ELSEIF (#{ems_argument_current_demand_gv.name} > #{ems_argument_target_demand_gv.name}) && (#{ems_argument_trend_direction_gv.name} < 0.0)")
    ems_find_demand_state_subroutine.addLine("IF DmndStateX1 <= 2.0")
    ems_find_demand_state_subroutine.addLine("SET #{ems_demand_manager_state_gv.name} = 2.0")
    ems_find_demand_state_subroutine.addLine("ELSEIF (DmndStateX1 == 3.0) && (DmndStateX2 == 2.0)")
    ems_find_demand_state_subroutine.addLine("SET #{ems_demand_manager_state_gv.name} = 3.0")
    ems_find_demand_state_subroutine.addLine("ELSEIF (DmndStateX1 == 3.0) && (DmndStateX2 == 3.0)")
    ems_find_demand_state_subroutine.addLine("SET #{ems_demand_manager_state_gv.name} = 2.0")
    ems_find_demand_state_subroutine.addLine("ENDIF")
    ems_find_demand_state_subroutine.addLine("ELSEIF (#{ems_argument_current_demand_gv.name} > #{ems_argument_target_demand_gv.name}) && (#{ems_argument_trend_direction_gv.name} >= 0.0)")
    ems_find_demand_state_subroutine.addLine("SET #{ems_demand_manager_state_gv.name} = 3.0")
    ems_find_demand_state_subroutine.addLine("ENDIF")
    
    # Create new EnergyManagementSystem:Program object for dispatching demand controls for the given state
    ems_dispatch_demand_controls_by_state_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    ems_dispatch_demand_controls_by_state_program.setName("Dispatch_Demand_Controls_By_State")
    ems_dispatch_demand_controls_by_state_program.addLine("IF (#{ems_demand_manager_state_gv.name} == 0.0)")
    ems_dispatch_demand_controls_by_state_program.addLine("RUN #{ems_unset_demand_controls_subroutine.name}")
    ems_dispatch_demand_controls_by_state_program.addLine("ELSEIF (#{ems_demand_manager_state_gv.name} == 1.0)")
    ems_dispatch_demand_controls_by_state_program.addLine("RUN #{ems_set_demand_level1_controls_subroutine.name}")
    ems_dispatch_demand_controls_by_state_program.addLine("ELSEIF (#{ems_demand_manager_state_gv.name} == 2.0)")
    ems_dispatch_demand_controls_by_state_program.addLine("Run #{ems_set_demand_level2_controls_subroutine.name}")
    ems_dispatch_demand_controls_by_state_program.addLine("ELSEIF (#{ems_demand_manager_state_gv.name} == 3.0)")
    ems_dispatch_demand_controls_by_state_program.addLine("RUN #{ems_set_demand_level3_controls_subroutine.name}")
    ems_dispatch_demand_controls_by_state_program.addLine("ENDIF")
    if verbose_info_statements == true
      runner.registerInfo("EMS Program object named '#{ems_dispatch_demand_controls_by_state_program.name}' added to dispatch demand controls by state.") 
    end
    
    # Create new EnergyManagementSystem:Program object for determining the state of the current demand manager
    ems_determine_current_demand_manager_state_prgm = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    ems_determine_current_demand_manager_state_prgm.setName("Determine_Current_Demand_Manage_State")
    ems_determine_current_demand_manager_state_prgm.addLine("SET localDemand = #{ems_current_facility_electric_demand_sensor.name} / 1000.0")
    ems_determine_current_demand_manager_state_prgm.addLine("SET CurrntTrend = @TrendDirection #{ems_current_facility_elec_demand_trend.name} 4")
    for i in 1..12   
      if i == 1 
        ems_determine_current_demand_manager_state_prgm.addLine("IF (Month == #{i})")
      else
        ems_determine_current_demand_manager_state_prgm.addLine("ELSEIF (Month == #{i})")
      end
      ems_determine_current_demand_manager_state_prgm.addLine("SET #{ems_argument_target_demand_gv.name} = #{target_demand_value} * #{peak_demand_array[i-1]}") 
      ems_determine_current_demand_manager_state_prgm.addLine("SET #{ems_argument_current_demand_gv.name} = localDemand") 
      ems_determine_current_demand_manager_state_prgm.addLine("SET #{ems_argument_trend_direction_gv.name} = CurrntTrend") 
    end
    ems_determine_current_demand_manager_state_prgm.addLine("ENDIF") 
    ems_determine_current_demand_manager_state_prgm.addLine("RUN #{ems_find_demand_state_subroutine.name}") 
    if verbose_info_statements == true
      runner.registerInfo("EMS Program object named '#{ems_determine_current_demand_manager_state_prgm.name}' added to determining the state of the current demand manager.") 
    end
    
    # Create a new EnergyManagementSystem:ProgramCallingManager object configured to call the EMS programs
    ems_prgm_calling_mngr = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    ems_prgm_calling_mngr.setName("Demand Manager Demonstration")
    ems_prgm_calling_mngr.setCallingPoint("BeginTimestepBeforePredictor")
    ems_prgm_calling_mngr.addProgram(ems_determine_current_demand_manager_state_prgm)
    ems_prgm_calling_mngr.addProgram(ems_dispatch_demand_controls_by_state_program)
    if verbose_info_statements == true
      runner.registerInfo("EMS Program Calling Manager object named '#{ems_prgm_calling_mngr.name}' added to call #{ems_determine_current_demand_manager_state_prgm.name} and #{ems_dispatch_demand_controls_by_state_program.name} EMS programs.") 
    end
    
    # create OutputEnergyManagementSystem object (a 'unique' object) and configure to allow EMS reporting
    output_EMS = model.getOutputEnergyManagementSystem
    output_EMS.setInternalVariableAvailabilityDictionaryReporting('internal_variable_availability_dictionary_reporting')
    output_EMS.setEMSRuntimeLanguageDebugOutputLevel('ems_runtime_language_debug_output_level')
    output_EMS.setActuatorAvailabilityDictionaryReporting('actuator_availability_dictionary_reporting')
    if verbose_info_statements == true
      runner.registerInfo("EMS OutputEnergyManagementSystem object configured per user arguments.") 
    end
    
    runner.registerFinalCondition("Measure finished with #{model.getEnergyManagementSystemSensors.count} EMS sensors, #{model.getEnergyManagementSystemActuators.count} EMS Actuators, #{model.getEnergyManagementSystemPrograms.count} EMS Programs, #{model.getEnergyManagementSystemSubroutines.count} EMS Subroutines, #{model.getEnergyManagementSystemProgramCallingManagers.count} EMS Program Calling Manager objects")

  end # end run method
  
end # end class

# register the measure to be used by the application
M9Example9DemandManagement.new.registerWithApplication


