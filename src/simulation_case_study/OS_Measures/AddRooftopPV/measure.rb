# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2021, Alliance for Sustainable Energy, LLC.
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
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# load OpenStudio measure libraries from openstudio-extension gem
require 'openstudio-extension'
require 'openstudio/extension/core/os_lib_helper_methods'
require 'openstudio/extension/core/os_lib_schedules'

# start the measure
class AddRooftopPV < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'Add Rooftop PV'
  end

  # human readable description
  def description
    return 'This measure will create new shading surface geometry above the roof for each thermal zone inyour model where the surface azmith falls within the user specified range. Arguments are exposed for panel efficiency, inverter efficiency, and the fraction of each roof surface that has PV.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'The fraction of surface containing PV will not only set the PV properties, but will also change the transmittance value for the shading surface. This allows the measure to avoid attempting to layout the panels. Simple PV will be used to model the PV.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # set fraction_of_surface
    fraction_of_surface = OpenStudio::Measure::OSArgument.makeDoubleArgument('fraction_of_surface', true)
    fraction_of_surface.setDisplayName('Fraction of Surface Area with Active Solar Cells')
    fraction_of_surface.setUnits('fraction')
    fraction_of_surface.setDefaultValue(0.75)
    args << fraction_of_surface

    # set cell_efficiency
    cell_efficiency = OpenStudio::Measure::OSArgument.makeDoubleArgument('cell_efficiency', true)
    cell_efficiency.setDisplayName('Cell Efficiency')
    cell_efficiency.setUnits('fraction')
    cell_efficiency.setDefaultValue(0.18)
    args << cell_efficiency

    # set inverter_efficiency
    inverter_efficiency = OpenStudio::Measure::OSArgument.makeDoubleArgument('inverter_efficiency', true)
    inverter_efficiency.setDisplayName('Inverter Efficiency')
    inverter_efficiency.setUnits('fraction')
    inverter_efficiency.setDefaultValue(0.98)
    args << inverter_efficiency

    # TODO: = add in min and max azimuth arguments, think about how I want to handle flat roofs.

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
    args = OsLib_HelperMethods.createRunVariables(runner, model, user_arguments, arguments(model))
    if !args then return false end

    # check expected values of double arguments
    # todo - not sure why this isn't working. Elsewhere it is used on E+ and reporting measures.
    # todo - maybe related is this error on test 'Asked to create a flat json serialization of a vector of attributes with non-unique names'
    # fraction_check = OsLib_HelperMethods.checkDoubleAndIntegerArguments(runner, user_arguments,{"min"=>0.0,"max"=>1.0,"min_eq_bool"=>true,"max_eq_bool"=>true,"arg_array" =>["fraction_of_surface","cell_efficiency","inverter_efficiency"]})
    # if !fraction_check then return false end

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getShadingSurfaces.size} shading surfaces.")

    # create copies of exterior roofs has shading surfaces 12 inches above teh roof. Maybe the height should become an argument.
    vertical_offset_ip = 1.0 # feet
    vertical_offset_si = OpenStudio.convert(vertical_offset_ip, 'ft', 'm').get

    # create the inverter
    inverter = OpenStudio::Model::ElectricLoadCenterInverterSimple.new(model)
    inverter.setInverterEfficiency(args['inverter_efficiency'])
    runner.registerInfo("Created inverter with efficiency of #{inverter.inverterEfficiency}")

    # create the distribution system
    elcd = OpenStudio::Model::ElectricLoadCenterDistribution.new(model)
    elcd.setInverter(inverter)

    # create shared shading transmittance schedule
    target_transmittance = 1.0 - args['fraction_of_surface'].to_f
    inputs = {
      'name' => 'PV Shading Transmittance Schedule',
      'winterTimeValuePairs' => { 24.0 => target_transmittance },
      'summerTimeValuePairs' => { 24.0 => target_transmittance },
      'defaultTimeValuePairs' => { 24.0 => target_transmittance }
    }
    pv_shading_transmittance_schedule = OsLib_Schedules.createSimpleSchedule(model, inputs)
    runner.registerInfo("Created transmittance schedule for PV shading surfaces with constant value of #{target_transmittance}")

    model.getSurfaces.each do |surface|
      next if !surface.space.is_initialized
      if (surface.surfaceType == 'RoofCeiling') && (surface.outsideBoundaryCondition == 'Outdoors')

        # store  vertices
        vertices = surface.vertices
        origin = [surface.space.get.xOrigin, surface.space.get.yOrigin, surface.space.get.zOrigin]

        # make shading surface group and set origin
        shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
        shading_surface_group.setXOrigin(origin[0])
        shading_surface_group.setYOrigin(origin[1])
        shading_surface_group.setZOrigin(origin[2] + vertical_offset_si)

        # make shading surface for new group
        shading_surface = OpenStudio::Model::ShadingSurface.new(vertices, model)
        shading_surface.setShadingSurfaceGroup(shading_surface_group)
        shading_surface.setName("PV - #{surface.name}")
        shading_surface.setTransmittanceSchedule(pv_shading_transmittance_schedule)

        # create the panel
        panel = OpenStudio::Model::GeneratorPhotovoltaic.simple(model)
        panel.setSurface(shading_surface)
        performance = panel.photovoltaicPerformance.to_PhotovoltaicPerformanceSimple.get
        performance.setFractionOfSurfaceAreaWithActiveSolarCells(args['fraction_of_surface'])
        performance.setFixedEfficiency(args['cell_efficiency'])

        # connect panel to electric load center distribution
        elcd.addGenerator(panel)

        runner.registerInfo("Created shading surface for PV over #{surface.name} with a cell efficiency of #{performance.fixedEfficiency} and surface coverage fraction of #{performance.fractionOfSurfaceAreaWithActiveSolarCells}")

      end
    end

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getShadingSurfaces.size} shading surfaces.")

    return true
  end
end

# register the measure to be used by the application
AddRooftopPV.new.registerWithApplication
