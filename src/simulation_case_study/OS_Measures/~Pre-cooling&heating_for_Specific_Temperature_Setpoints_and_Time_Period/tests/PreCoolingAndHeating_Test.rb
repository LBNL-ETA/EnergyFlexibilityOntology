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

class PreCoolingAndHeating_Test < Minitest::Test
  def test_PreCoolingAndHeating_good_design_day
    # create an instance of the measure
    measure = PreCoolingAndHeating.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/ThermostatTestModel.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(5, arguments.size)
    assert_equal('cooling_adjustment', arguments[0].name)
    assert_equal('heating_adjustment', arguments[1].name)
    assert_equal('starttime', arguments[2].name)
    assert_equal('enttime', arguments[3].name)
    assert_equal('alter_design_days', arguments[4].name)

    # set argument values to bad values and run the measure
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    cooling_adjustment = arguments[0].clone
    assert(cooling_adjustment.setValue(2.0))
    argument_map['cooling_adjustment'] = cooling_adjustment
 
    heating_adjustment = arguments[1].clone
    assert(heating_adjustment.setValue(-1.0))
    argument_map['heating_adjustment'] = heating_adjustment

    starttime = arguments[2].clone
    assert(starttime.setValue('13:00:00'))
    argument_map['starttime'] = starttime

    enttime = arguments[3].clone
    assert(enttime.setValue('15:00:00'))
    argument_map['enttime'] = enttime

    alter_design_days = arguments[4].clone
    assert(alter_design_days.setValue(true))
    argument_map['alter_design_days'] = alter_design_days

    measure.run(model, runner, argument_map)##
    result = runner.result
    # show_output(result)
    assert(result.value.valueName == 'Success')
    #assert(result.warnings.size == 5)           
    #assert(result.info.empty?)
  end

  def test_PreCoolingAndHeating_good__no_design_day
    # create an instance of the measure
    measure = PreCoolingAndHeating.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/ThermostatTestModel.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(5, arguments.size)
    assert_equal('cooling_adjustment', arguments[0].name)
    assert_equal('heating_adjustment', arguments[1].name)
    assert_equal('starttime', arguments[2].name)
    assert_equal('enttime', arguments[3].name)
    assert_equal('alter_design_days', arguments[4].name)

    # set argument values to good values and run the measure on model with spaces
    # set argument values to bad values and run the measure
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    cooling_adjustment = arguments[0].clone
    assert(cooling_adjustment.setValue(2.0))
    argument_map['cooling_adjustment'] = cooling_adjustment

    heating_adjustment = arguments[1].clone
    assert(heating_adjustment.setValue(-1.0))
    argument_map['heating_adjustment'] = heating_adjustment

    starttime = arguments[2].clone
    assert(starttime.setValue('13:00:00'))
    argument_map['starttime'] = starttime

    enttime = arguments[3].clone
    assert(enttime.setValue('15:00:00'))
    argument_map['enttime'] = enttime

    alter_design_days = arguments[4].clone
    assert(alter_design_days.setValue(false))
    argument_map['alter_design_days'] = alter_design_days

    measure.run(model, runner, argument_map)
    result = runner.result
    # show_output(result)
    assert(result.value.valueName == 'Success')
    #assert(result.warnings.size == 5)
    #assert(result.info.empty?)

  end

def test_PreCoolingAndHeating_good__HVACOperationModified
    # create an instance of the measure
    measure = PreCoolingAndHeating.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/ThermostatTestModel.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(5, arguments.size)
    assert_equal('cooling_adjustment', arguments[0].name)
    assert_equal('heating_adjustment', arguments[1].name)
    assert_equal('starttime', arguments[2].name)
    assert_equal('enttime', arguments[3].name)
    assert_equal('alter_design_days', arguments[4].name)

    # set argument values to good values and run the measure on model with spaces
    # set argument values to bad values and run the measure
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    cooling_adjustment = arguments[0].clone
    assert(cooling_adjustment.setValue(2.0))
    argument_map['cooling_adjustment'] = cooling_adjustment

    heating_adjustment = arguments[1].clone
    assert(heating_adjustment.setValue(-1.0))
    argument_map['heating_adjustment'] = heating_adjustment

    starttime = arguments[2].clone
    assert(starttime.setValue('03:00:00'))
    argument_map['starttime'] = starttime

    enttime = arguments[3].clone
    assert(enttime.setValue('11:00:00'))
    argument_map['enttime'] = enttime

    alter_design_days = arguments[4].clone
    assert(alter_design_days.setValue(false))
    argument_map['alter_design_days'] = alter_design_days

    measure.run(model, runner, argument_map)
    result = runner.result
    # show_output(result)
    assert(result.value.valueName == 'Success')
    #assert(result.warnings.size == 5)
    #assert(result.info.empty?)

  end


  def test_PreCoolingAndHeating_fail_value
    # create an instance of the measure
    measure = PreCoolingAndHeating.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(5, arguments.size)
    assert_equal('cooling_adjustment', arguments[0].name)
    assert_equal('heating_adjustment', arguments[1].name)
    assert_equal('starttime', arguments[2].name)
    assert_equal('enttime', arguments[3].name)
    assert_equal('alter_design_days', arguments[4].name)

    # set argument values to bad values and run the measure
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    cooling_adjustment = arguments[0].clone
    assert(cooling_adjustment.setValue(5000.0))
    argument_map['cooling_adjustment'] = cooling_adjustment
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Fail')
  end



  def test_PreCoolingAndHeating_fail_timeperiods
    # create an instance of the measure
    measure = PreCoolingAndHeating.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(5, arguments.size)
    assert_equal('cooling_adjustment', arguments[0].name)
    assert_equal('heating_adjustment', arguments[1].name)
    assert_equal('starttime', arguments[2].name)
    assert_equal('enttime', arguments[3].name)
    assert_equal('alter_design_days', arguments[4].name)

    # set argument values to bad values and run the measure
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    cooling_adjustment = arguments[0].clone
    assert(cooling_adjustment.setValue(5000.0))
    argument_map['cooling_adjustment'] = cooling_adjustment

    starttime = arguments[2].clone
    assert(starttime.setValue('13:00:00'))
    argument_map['starttime'] = starttime

    endtime = arguments[3].clone
    assert(endtime.setValue('10:00:00'))
    argument_map['endtime'] = endtime


    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Fail')
  end


    # save the model
    # output_file_path = OpenStudio::Path.new('C:\SVN_Utilities\OpenStudio\measures\test.osm')
    # model.save(output_file_path,true)
  end
end
