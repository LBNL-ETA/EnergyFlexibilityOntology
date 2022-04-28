require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
require 'minitest/autorun'

require 'json'

class CreateDOEPrototypeBuildingTest < Minitest::Test
  def setup
    # Make a directory to save the resulting models
    @test_dir = "#{File.dirname(__FILE__)}/output"
    if !Dir.exist?(@test_dir)
      Dir.mkdir(@test_dir)
    end
  end

  # Create a set of models, return a list of failures
  def create_models(bldg_types, vintages, climate_zones, epw_files = [])
    #### Create the prototype building
    failures = []

    # Loop through all of the given combinations
    bldg_types.sort.each do |building_type|
      vintages.sort.each do |template|
        climate_zones.sort.each do |climate_zone|
          model_name = "#{building_type}-#{template}-#{climate_zone}"
          puts "****Testing #{model_name}****"

          # Create an instance of the measure
          measure = CreateDOEPrototypeBuilding.new

          # Create an instance of a runner
          runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

          # Make an empty model
          model = OpenStudio::Model::Model.new

          # Set argument values
          arguments = measure.arguments(model)
          argument_map = OpenStudio::Measure::OSArgumentMap.new
          building_type_arg = arguments[0].clone
          assert(building_type_arg.setValue(building_type))
          argument_map['building_type'] = building_type_arg

          template_arg = arguments[1].clone
          assert(template_arg.setValue(template))
          argument_map['template'] = template_arg

          climate_zone_arg = arguments[2].clone
          assert(climate_zone_arg.setValue(climate_zone))
          argument_map['climate_zone'] = climate_zone_arg

          epw_arg = arguments[3].clone
          assert(epw_arg.setValue('Not Applicable'))
          argument_map['epw_file'] = epw_arg

          measure.run(model, runner, argument_map)
          result = runner.result
          show_output(result)
          if result.value.valueName != 'Success'
            failures << "Error - #{model_name} - Model was not created successfully."
          end

          model_directory = "#{@test_dir}/#{building_type}-#{template}-#{climate_zone}"

          # Convert the model to energyplus idf
          forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new
          idf = forward_translator.translateModel(model)
          idf_path_string = "#{model_directory}/#{model_name}.idf"
          idf_path = OpenStudio::Path.new(idf_path_string)
          idf.save(idf_path, true)
        end
      end
    end

    #### Return the list of failures
    return failures
  end

  def dont_test_primary_school
    bldg_types = ['PrimarySchool']
    vintages = ['DOE Ref Pre-1980'] # , 'DOE Ref 1980-2004', '90.1-2004', '90.1-2007', '90.1-2010']
    climate_zones = ['ASHRAE 169-2006-3A']

    all_failures = []

    # Create the models
    all_failures += create_models(bldg_types, vintages, climate_zones)

    # Assert if there are any errors
    puts "There were #{all_failures.size} failures"
    assert(all_failures.empty?, "FAILURES: #{all_failures.join("\n")}")
  end

  def test_secondary_school
    bldg_types = ['SecondarySchool']
    vintages = ['DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2004', '90.1-2007', '90.1-2010']
    climate_zones = ['ASHRAE 169-2006-2A']

    all_failures = []

    # Create the models
    all_failures += create_models(bldg_types, vintages, climate_zones)

    # Assert if there are any errors
    puts "There were #{all_failures.size} failures"
    assert(all_failures.empty?, "FAILURES: #{all_failures.join("\n")}")
  end

  def test_primary_school
    bldg_types = ['PrimarySchool']
    vintages = ['DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2004', '90.1-2007', '90.1-2010']
    climate_zones = ['ASHRAE 169-2006-3A']

    all_failures = []

    # Create the models
    all_failures += create_models(bldg_types, vintages, climate_zones)

    # Assert if there are any errors
    puts "There were #{all_failures.size} failures"
    assert(all_failures.empty?, "FAILURES: #{all_failures.join("\n")}")
  end
end
