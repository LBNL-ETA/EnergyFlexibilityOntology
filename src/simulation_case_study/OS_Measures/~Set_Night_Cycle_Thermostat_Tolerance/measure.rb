# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class SetNightCycleThermostatTolerance < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Set Night Cycle Thermostat Tolerance {deltaC}'
  end

  # human readable description
  def description
    return 'This measure sets the Thermostat Tolerance {deltaC} based on the user input'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Input the value for the new value for Thermostat Tolerance {deltaC}'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    tolerance_value = OpenStudio::Measure::OSArgument.makeDoubleArgument('tolerance_value', true)
    tolerance_value.setDisplayName('New Thermostat Tolerance Value {deltaC} (between 1 and 4).')
    tolerance_value.setDefaultValue(4)
    args << tolerance_value

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
    tolerance_value = runner.getDoubleArgumentValue('tolerance_value', user_arguments)

    # check the input argument for resonableness
    if tolerance_value < 0
      runner. registerError('Thermostat tolerance should be larger than 0.')
    end

    if tolerance_value > 8
      runner. registerWarning('A thermostat tolerance of #{tolerance} delta C is abnormally high.')
    end

    # check the availability manager night cycle for reasonableness
    amnightcycles = []
    managertyp_ch_log = []
    raw_amnightcycles = model.getAvailabilityManagerNightCycles
    raw_amnightcycles.each do |raw_amnightcycle|
      amnightcycles << raw_amnightcycle
    end

    amnightcycles.each do |amnightcycle|
      old_thermostat_tolerance = amnightcycle.getThermostatTolerance
      # add the old conditon to the change log
      managertyp_ch_log << [amnightcycle.name, old_thermostat_tolerance]
      amnightcycle.setThermostatTolerance(tolerance_value)
    end

    # report out the initial and final conditions to the user
    initial_condition = ""
    final_condition = ""
    managertyp_ch_log.each do |ch|
      initial_condition << "#{ch[0]} had a thermostat tolerance of #{ch[1]} delta C.\n"
      final_condition << "#{ch[0]}, "
    end
    final_condition << "were all set to a thermostat tolerance of #{tolerance_value} delta C."
    runner.registerInitialCondition(initial_condition)
    runner.registerFinalCondition(final_condition)
    #runner.registerFinalCondition("Adjust thermostat tolerance for #{tolerance_value}")
    return true
  end
end

# register the measure to be used by the application
SetNightCycleThermostatTolerance.new.registerWithApplication
