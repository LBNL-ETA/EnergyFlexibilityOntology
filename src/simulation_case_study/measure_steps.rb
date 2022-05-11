$baseline_steps = %(
  {"measure_dir_name":"AddOutputVariable","arguments":{"variable_name":"Facility Net Purchased Electric Energy","key_value":"*","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"Electricity:Facility","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"Gas:Facility","reporting_frequency":"timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"Facility Net Purchased Electric Energy","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"Electricity:Facility","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"Gas:Facility","reporting_frequency":"Zone Timestep"}}
)

$baseline_plus_pv_steps = %(
  {"measure_dir_name":"AddRooftopPV","arguments":{"fraction_of_surface":0.5, "cell_efficiency":0.18, "inverter_efficiency":0.98}},
  {"measure_dir_name":"AddOutputVariable","arguments":{"variable_name":"Generator Produced DC Electric Energy","key_value":"*","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddOutputVariable","arguments":{"variable_name":"Generator Produced DC Electric Power","key_value":"*","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddOutputVariable","arguments":{"variable_name":"Facility Net Purchased Electric Energy","key_value":"*","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"Electricity:Facility","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"Gas:Facility","reporting_frequency":"timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"Generator Produced DC Electric Energy","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"Generator Produced DC Electric Power","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"Facility Net Purchased Electric Energy","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"Electricity:Facility","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"Gas:Facility","reporting_frequency":"Zone Timestep"}}
)

$baseline_plus_pv_ev_steps = %(
  {"measure_dir_name":"AddRooftopPV","arguments":{"fraction_of_surface":0.5, "cell_efficiency":0.18, "inverter_efficiency":0.98}},
  {"measure_dir_name":"AddEVLoad","arguments":{"delay_type":"Max Delay","charge_behavior":"Free Workplace Charging at Project Site","chg_station_type":"Typical Work"}},
  {"measure_dir_name":"AddOutputVariable","arguments":{"variable_name":"Generator Produced DC Electric Energy","key_value":"*","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddOutputVariable","arguments":{"variable_name":"Generator Produced DC Electric Power","key_value":"*","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddOutputVariable","arguments":{"variable_name":"Facility Net Purchased Electric Energy","key_value":"*","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"Electricity:Facility","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"Gas:Facility","reporting_frequency":"timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"Generator Produced DC Electric Energy","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"Generator Produced DC Electric Power","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"Facility Net Purchased Electric Energy","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"Electricity:Facility","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"Gas:Facility","reporting_frequency":"Zone Timestep"}}
)


$baseline_dr_light_steps = %(
  {"measure_dir_name":"DR_Lighting","arguments":{}},
  {"measure_dir_name":"AddOutputVariable","arguments":{"variable_name":"Facility Net Purchased Electric Energy","key_value":"*","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"Electricity:Facility","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"Gas:Facility","reporting_frequency":"timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"Facility Net Purchased Electric Energy","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"Electricity:Facility","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"Gas:Facility","reporting_frequency":"Zone Timestep"}}
  )

$baseline_dr_mels_steps = %(
  {"measure_dir_name":"DR_MELs","arguments":{}},
  {"measure_dir_name":"AddOutputVariable","arguments":{"variable_name":"Facility Net Purchased Electric Energy","key_value":"*","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"Electricity:Facility","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"Gas:Facility","reporting_frequency":"timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"Facility Net Purchased Electric Energy","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"Electricity:Facility","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"Gas:Facility","reporting_frequency":"Zone Timestep"}}
  )


$baseline_dr_light_mels_steps = %(
  {"measure_dir_name":"DR_Lighting","arguments":{}},
  {"measure_dir_name":"DR_MELs","arguments":{}},
  {"measure_dir_name":"AddOutputVariable","arguments":{"variable_name":"Facility Net Purchased Electric Energy","key_value":"*","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"Electricity:Facility","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"Gas:Facility","reporting_frequency":"timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"Facility Net Purchased Electric Energy","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"Electricity:Facility","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"Gas:Facility","reporting_frequency":"Zone Timestep"}}
  )



$baseline_plus_ST_adjust_steps = %(
  {"measure_dir_name":"~Adjust_Thermostat_Setpoints_by_Degrees_for_Specific_Time_Period","arguments":{}},
  {"measure_dir_name":"AddOutputVariable","arguments":{"variable_name":"Facility Net Purchased Electric Energy","key_value":"*","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"Electricity:Facility","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"Gas:Facility","reporting_frequency":"timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"Facility Net Purchased Electric Energy","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"Electricity:Facility","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"Gas:Facility","reporting_frequency":"Zone Timestep"}}
)

$baseline_plus_pre_cond_steps = %(
  {"measure_dir_name":"~Pre-cooling&heating_for_Specific_Temperature_Setpoints_and_Time_Period","arguments":{}},
  {"measure_dir_name":"AddOutputVariable","arguments":{"variable_name":"Facility Net Purchased Electric Energy","key_value":"*","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"Electricity:Facility","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"Gas:Facility","reporting_frequency":"timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"Facility Net Purchased Electric Energy","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"Electricity:Facility","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"Gas:Facility","reporting_frequency":"Zone Timestep"}}
)


# -------------------------------- Not Working ------------------------------- #
$baseline_plus_dynamic_dr_steps = %(
  {"measure_dir_name":"~Dynamic_DR","arguments":{}},
  {"measure_dir_name":"AddOutputVariable","arguments":{"variable_name":"Facility Net Purchased Electric Energy","key_value":"*","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"Electricity:Facility","reporting_frequency":"timestep"}},
  {"measure_dir_name":"AddMeter","arguments":{"meter_name":"Gas:Facility","reporting_frequency":"timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportVariabletoCSV","arguments":{"variable_name":"Facility Net Purchased Electric Energy","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"CarbonEquivalentEmissions:Carbon Equivalent","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"Electricity:Facility","reporting_frequency":"Zone Timestep"}},
  {"measure_dir_name":"ExportMetertoCSV","arguments":{"meter_name":"Gas:Facility","reporting_frequency":"Zone Timestep"}}
)


def get_steps(str_step)
  if str_step == 'baseline'
    str_out = $baseline_steps
  elsif str_step == 'baseline+pv'
    str_out = $baseline_plus_pv_steps
  elsif str_step == 'baseline+pv+ev'
    str_out = $baseline_plus_pv_ev_steps
  elsif str_step == 'baseline+dynamic_dr'
    str_out = $baseline_plus_dynamic_dr_steps
  elsif str_step == 'baseline+ST_adjust'
    str_out = $baseline_plus_ST_adjust_steps
  elsif str_step == 'baseline+pre_cond'
    str_out = $baseline_plus_pre_cond_steps
  elsif str_step == 'baseline+dr_light'
    str_out = $baseline_dr_light_steps
  elsif str_step == 'baseline+dr_mels'
    str_out = $baseline_dr_mels_steps
  elsif str_step == 'baseline+dr_light_mels'
    str_out = $baseline_dr_light_mels_steps
  end
  return str_out 
end



# ---------------------------------- archive --------------------------------- #
# osm_path = 'D:/GitHub/EnergyFlexibilityOntology/example/local_exp/seed/SmallOffice_90.1-2013_1A.osm'
# epw_path = 'D:/GitHub/EnergyFlexibilityOntology/example/local_exp/seed/SmallOffice_90.1-2013_1A.epw'
# measures_dir = 'D:/GitHub/EnergyFlexibilityOntology/example/local_exp/OS_Measures'
# osw_path = 'D:/GitHub/EnergyFlexibilityOntology/example/local_exp/EF_PV_generation/workflows/w_pv/w_pv.osw'
# osw_path = 'D:/GitHub/EnergyFlexibilityOntology/example/local_exp/EF_PV_generation/workflows/wo_pv/wo_pv.osw'
# prepare_single_osw(seed_osm, seed_epw, measures_dir, osw_path)