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

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
require 'minitest/autorun'

class ReduceElectricEquipmentLoadsByPercentageAndTimePeriod_Test < Minitest::Test
  # def setup
  # end

  # def teardown
  # end

  def test_ReduceElectricEquipmentLoadsByPercentage_01_BadInputs
    # create an instance of the measure
    measure = ReduceElectricEquipmentLoadsByPercentageAndTimePeriod.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/MediumOfficeDetailed_2004_1A.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(6, arguments.size)
    assert_equal('space_type', arguments[0].name)
    assert_equal('occupied_space_type', arguments[1].name)
    assert_equal('unoccupied_space_type', arguments[2].name)
    assert_equal('single_space_type', arguments[3].name)
    assert_equal('starttime', arguments[4].name)
    assert_equal('endtime', arguments[5].name)

    # fill in argument_map
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    space_type = arguments[0].clone
    assert(space_type.setValue('*Entire Building*'))
    argument_map['space_type'] = space_type

    occupied_space_type = arguments[1].clone
    assert(occupied_space_type.setValue(30.0))
    argument_map['occupied_space_type'] = occupied_space_type

    unoccupied_space_type = arguments[2].clone
    assert(unoccupied_space_type.setValue(95.0))
    argument_map['unoccupied_space_type'] = unoccupied_space_type

    single_space_type = arguments[3].clone
    assert(single_space_type.setValue(30.0))
    argument_map['single_space_type'] = single_space_type

    starttime = arguments[4].clone
    assert(starttime.setValue('13:00:00'))
    argument_map['starttime'] = starttime

    endtime = arguments[5].clone
    assert(endtime.setValue('15:00:00'))
    argument_map['endtime'] = endtime


    measure.run(model, runner, argument_map)
    result = runner.result
    # show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.size == 1)
    assert(result.info.empty?)
  end


  #################################################################################################
  #################################################################################################

  def test_ReduceElectricEquipmentLoadsByPercentageAndTimePeriod_02_failonvalue
    # create an instance of the measure
    measure = ReduceElectricEquipmentLoadsByPercentageAndTimePeriod.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(6, arguments.size)
    assert_equal('space_type', arguments[0].name)
    assert_equal('occupied_space_type', arguments[1].name)
    assert_equal('unoccupied_space_type', arguments[2].name)
    assert_equal('single_space_type', arguments[3].name)
    assert_equal('starttime', arguments[4].name)
    assert_equal('endtime', arguments[5].name)

    # set argument values to bad values and run the measure
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    occupied_space_type = arguments[1].clone
    assert(occupied_space_type.setValue(120.0))
    argument_map['occupied_space_type'] = occupied_space_type
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Fail')
  end

  #################################################################################################
  #################################################################################################

  def test_ReduceElectricEquipmentLoadsByPercentageAndTimePeriod_03_failontimeperiod
    # create an instance of the measure
    measure = ReduceElectricEquipmentLoadsByPercentageAndTimePeriod.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(6, arguments.size)
    assert_equal('space_type', arguments[0].name)
    assert_equal('occupied_space_type', arguments[1].name)
    assert_equal('unoccupied_space_type', arguments[2].name)
    assert_equal('single_space_type', arguments[3].name)
    assert_equal('starttime', arguments[4].name)
    assert_equal('endtime', arguments[5].name)

    # set argument values to bad values and run the measure
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    starttime = arguments[4].clone
    assert(starttime.setValue('13:00:00'))
    argument_map['starttime'] = starttime
    endtime = arguments[5].clone
    assert(endtime.setValue('10:00:00'))
    argument_map['endtime'] = endtime
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Fail')
  end


end
