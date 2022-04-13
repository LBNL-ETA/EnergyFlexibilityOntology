# -------------------------------- Import gems ------------------------------- #
# Change to the path where OpenStudio is installed
require 'C:/openstudio-2.9.1/Ruby/openstudio.rb' # Desktop, Z8

# Change to the path where openstudio-standards is cloned
# require 'D:/GitHub/OpenStudio_related/openstudio-standards/lib/openstudio-standards.rb' # Desktop
require 'F:/GitHub/openstudio-standards/lib/openstudio-standards.rb' # Z8
require 'fileutils'
require 'parallel'
require './measure_steps.rb'

# --------------------------------- functions -------------------------------- #
def loadOSM(pathStr)
  translator = OpenStudio::OSVersion::VersionTranslator.new
  path = OpenStudio::Path.new(pathStr)
  model = translator.loadModel(path)
  if model.empty?
    raise "Input #{pathStr} is not valid, please check."
  else
    model = model.get
  end
  return model
end


def create_single_model(building_type, vintage, climate_zone, osm_directory)
  model = OpenStudio::Model::Model.new
  @debug = false
  epw_file = 'Not Applicable'
  prototype_creator = Standard.build("#{vintage}_#{building_type}")
  prototype_creator.model_create_prototype_model(climate_zone, epw_file, osm_directory, @debug, model)
end


def process_model(old_osm_path, new_osm_path)
  osm_dir = File.dirname(new_osm_path)
  unless File.directory?(osm_dir)
    FileUtils.mkdir_p(osm_dir)
  end
  # Do the following:
  # 1. Change the simulation run period to match weather data
  model = loadOSM(old_osm_path)
  model.getSimulationControl.setRunSimulationforSizingPeriods(false)
  model.getSimulationControl.setRunSimulationforWeatherFileRunPeriods(true)
  model.save(new_osm_path, true) # Save processed model
end


def create_seed_model(working_dir, building_type, climate_zone, vintage)
  puts "Creating a seed OpenStudio model"
  model_name = building_type + '_' + vintage + '_' + climate_zone.split('-').last.to_s
  seed_model_folder = File.join(working_dir, '1~seeds', model_name)
  new_model_folder = File.join(working_dir, '2~processed_models', model_name)
  old_osm_path = File.expand_path(File.join(seed_model_folder, 'SR1/in.osm'))
  old_epw_path = File.expand_path(File.join(seed_model_folder, 'SR1/in.epw'))
  new_osm_path = File.expand_path(File.join(new_model_folder, "#{model_name}.osm"))
  new_epw_path = File.expand_path(File.join(new_model_folder, "#{model_name}.epw"))
  ## Create raw building model
  create_single_model(building_type, vintage, climate_zone, seed_model_folder)
  ## Process model
  process_model(old_osm_path, new_osm_path)
  FileUtils.mv(old_epw_path, new_epw_path)
  puts '-' * 50
  puts "A seed OpenStudio model was creates at #{new_osm_path}"
  return new_osm_path, new_epw_path
end

def prepare_single_osw(seed_osm_path, epw_path, measures_dir, osw_path, scenario)
  # Prepare OSW to add dynamic occupancy, lighting, MELs schedules.
  osw_dir = File.dirname(osw_path)
  unless File.directory?(osw_dir)
    FileUtils.mkdir_p(osw_dir)
  end

  osw_str =
  %({
    "weather_file": "#{epw_path}",
    "seed_file": "#{seed_osm_path}",
    "measure_paths": [
      "#{measures_dir}"
    ],
    "steps": [#{get_steps(scenario)}]
  })

  f = File.new(osw_path, "w")
  f.write(osw_str)
  f.close
end

def run_osws(os_exe, v_osw_paths, number_of_threads)
  n = v_osw_paths.length
  Parallel.each_with_index(v_osw_paths, :in_threads => number_of_threads) do |osw_path, index|
    puts "Running #{index + 1}/#{n}"
    command = "#{os_exe} run -w '#{osw_path}'"
    puts command
    system command
  end
end


# --------------------------------- main loop -------------------------------- #
bldg_type = 'SmallOffice'
# bldg_type = 'MediumOfficeDetailed'

climate_zones = [
  'ASHRAE 169-2006-1A',
  'ASHRAE 169-2006-2A',
  'ASHRAE 169-2006-2B',
  'ASHRAE 169-2006-3A',
  'ASHRAE 169-2006-3B',
  'ASHRAE 169-2006-3C',
  'ASHRAE 169-2006-4A',
  'ASHRAE 169-2006-4B',
  'ASHRAE 169-2006-4C',
  'ASHRAE 169-2006-5A',
  'ASHRAE 169-2006-5B',
  'ASHRAE 169-2006-6A',
  'ASHRAE 169-2006-6B',
  'ASHRAE 169-2006-7A',
  'ASHRAE 169-2006-8A',
]
# measure_steps 
scenario = 'baseline'
scenario = 'baseline+pv'
scenario = 'baseline+pv+ev'
scenario = 'baseline+dynamic_dr' # doesn't work
scenario = 'baseline+ST_adjust_steps'
scenario = 'baseline+pre_cond_steps'

# Desktop
dir_workflows = 'D:/GitHub/EnergyFlexibilityOntology/example/local_exp/EF_PV_generation/workflows_pv_ev'
measures_dir = 'D:/GitHub/EnergyFlexibilityOntology/example/local_exp/OS_Measures'

# Z8
dir_workflows = "G:/SDI/FY22_EF/EnergyFlexibilityOntology/example/case_study_1/EF_sim/workflows_#{bldg_type}_#{scenario}"
measures_dir = 'G:/SDI/FY22_EF/EnergyFlexibilityOntology/example/case_study_1/OS_Measures'

arr_osw_paths = []
climate_zones.each do |clm|
  seed_osm, seed_epw = create_seed_model('./', bldg_type, clm, '90.1-2013')
  osw_path = File.join(dir_workflows, clm, "#{clm}.osw")
  prepare_single_osw(seed_osm, seed_epw, measures_dir, osw_path, scenario)
  arr_osw_paths << osw_path
end

File.open("#{bldg_type}_#{scenario}_osws.txt", "w+") do |f|
  arr_osw_paths.each { |element| f.puts("\"#{element}\"") }
end


# Read OSW order from text file and run 

run_osws('os291', arr_osw_paths, 8)



