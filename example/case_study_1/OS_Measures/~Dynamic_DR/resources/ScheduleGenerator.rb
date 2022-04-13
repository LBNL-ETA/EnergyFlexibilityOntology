# *** Copyright Notice ***

# OS Measures Copyright (c) 2021, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any required
#   approvals from the U.S. Dept. of Energy). All rights reserved.

# If you have questions about your rights to use or distribute this software,
# please contact Berkeley Lab's Innovation & Partnerships Office at  IPO@lbl.gov.

# NOTICE.  This Software was developed under funding from the U.S. Department of
# Energy and the U.S. Governmen```````````````t consequently retains certain rights. As such,
# the U.S. Government has been granted for itself and others acting on its behalf
# a paid-up, nonexclusive, irrevocable, worldwide license in the Software to
# reproduce, distribute copies to the public, prepare derivative works, and
# perform publicly and display publicly, and to permit other to do so.

# ****************************
require 'time'
require 'csv'

class ScheduleGenerator
  def get_future_date_time(time, offset, format = "%m/%d/%Y %H:%M")
    time = time + (offset * 3600) #time.utc
    time.strftime(format)
    return time
  end

  def multi_array(sizes, default = nil)
    size, *remaining = sizes
    if remaining.empty?
      Array.new(size, default)
    else
      Array.new(size) { multi_array(remaining, default) }
    end
  end

  def save_to_csv(arr, headers, filename)
    CSV.open(@@root_path + filename, 'w') do |row|  # or mode 'a+'
      row << headers
      arr.each { |ar| row << ar }
    end
  end

  def load_from_csv(filename)
    return CSV.parse(File.read(@@root_path + filename), headers: true, converters: :all)
  end

  def float_rand(start_num, end_num)
    width = end_num-start_num
    return (rand*width)+start_num
  end


  def allyear_dr()
    start_year = Time.utc(2006, 1, 1, 1)
    end_year = Time.utc(2006, 12, 31, 23)

    # count days between 2 days and convert seconds to hours
    numdays = ((end_year - start_year).to_i / (24 * 60 * 60)) + 1

    dr_st = 15
    dr_en = 19
    pc_st = 0
    day_arr = Array.new(2) {Array.new()}

    lgti = 0  # lighting
    plgi = 1  # mels

    numdays.times do
      day_arr[lgti].push(float_rand(0,1).round(3))
      day_arr[plgi].push(float_rand(0,1).round(3))
    end

    year_arr = []
    for i in 0..8759
      hours_added = i
      future_date_time = get_future_date_time(start_year, hours_added)
      hour = future_date_time.strftime('%H').to_i
      weekday = future_date_time.strftime('%u').to_i ## 1-Monday

      if hour == 1
        lgt = plg = 0
      end
      if weekday < 6
        day = (i / 24).round()
        if hour == dr_st
          lgt = day_arr[lgti][day]
          plg = day_arr[plgi][day]

        end
        if hour == dr_en
          lgt = plg = 0
        end
      end

      hour_arr = []
      hour_arr.push(future_date_time)
      hour_arr.push(weekday)
      hour_arr.push(lgt)
      hour_arr.push(plg)

      year_arr.push(hour_arr)
    end

    headers = ["datetime","weekday","lighting","plugloads"]
    dr_fname = "out_allyear_dr.csv"
    save_to_csv(year_arr, headers, dr_fname)
    dr_sch = load_from_csv(dr_fname)
    return dr_sch
  end

  def summer_dr()
    start_year = Time.utc(2006, 1, 1, 1)
    start_summer = Time.utc(2006, 5, 1, 0)
    end_summer = Time.utc(2006, 10, 1, 0)
    # count days between 2 days and convert seconds to hours
    numdays = (end_summer - start_summer).to_i / (24 * 60 * 60)

    dr_st = 15
    dr_en = 19
    pc_st = 0
    day_arr = Array.new(5) {Array.new()}

    lgti = 0  # lighting
    plgi = 1  # mels
    gtai = 2  # cooling/heating
    pchi = 3  # precooling/heating magnitude
    pduri = 4 # precooling/heating duration

    numdays.times do
      pch = rand(0..5)
      pcdur = 0
      if pch > 0
        pcdur = rand(1..9)
      end
      day_arr[lgti].push(float_rand(0,1).round(3))
      day_arr[plgi].push(float_rand(0,1).round(3))
      day_arr[gtai].push(rand(1..7))
      day_arr[pchi].push(pch)
      day_arr[pduri].push(pcdur)
    end

    year_arr = []
    for i in 0..8759
      hours_added = i
      future_date_time = get_future_date_time(start_year, hours_added)
      hour = future_date_time.strftime('%H').to_i
      weekday = future_date_time.strftime('%u').to_i ## 1- Monday

      if hour == 1
        lgt = plg = gta = pch = 0
      end

      if future_date_time >= start_summer && future_date_time <= end_summer
        if future_date_time == start_summer
          j = 0
        end
        day = (j / 24).round()
        j = j + 1
        if weekday < 6
          if hour == 1
            pch = 0
            pcdur = day_arr[pduri][day]
            pc_st = (pcdur != 0) ? (dr_st - pcdur) : 0
          end

          if hour == pc_st
            if pc_st != 0
              pch = day_arr[pchi][day]
            end
          end
          if hour == dr_st
            lgt = day_arr[lgti][day]
            plg = day_arr[plgi][day]
            gta = day_arr[gtai][day]

            pch = 0
            pcdur = 0
          end
          if hour == dr_en
            lgt = plg = gta = 0
          end
        end
      end
      hour_arr = []
      hour_arr.push(future_date_time)
      hour_arr.push(weekday)
      hour_arr.push(lgt)
      hour_arr.push(plg)
      hour_arr.push(gta)
      hour_arr.push(pch)
      year_arr.push(hour_arr)
    end

    headers = ["datetime","weekday","lighting","plugloads","summer_gta","summer_precool"]
    dr_fname = "out_summer_dr.csv"
    save_to_csv(year_arr, headers, dr_fname)
    dr_sch = load_from_csv(dr_fname)
    return dr_sch
  end

  def winter_dr()
    start_year = Time.utc(2006, 1, 1, 1)
    start_winter1 = Time.utc(2006, 1, 1, 1)
    end_winter1 = Time.utc(2006, 2, 1, 0)
    start_winter2 = Time.utc(2006, 11, 1, 1)
    end_winter2 = Time.utc(2006, 12, 31, 23)

    dr_st = 7
    dr_en = 11
    pc_st = 0

    # count days between 2 days and convert seconds to hours
    numdays_winter1 = (end_winter1 - start_winter1).to_i / (24 * 60 * 60)
    numdays_winter2 = (end_winter2 - start_winter2).to_i / (24 * 60 * 60)
    numdays = numdays_winter1 + numdays_winter2 + 2

    day_arr = Array.new(3) {Array.new()}

    gtai = 0  # cooling/heating
    pchi = 1  # precooling/heating magnitude
    pduri = 2 # precooling/heating duration

    numdays.times do
      pch = rand(0..5)
      pcdur = 0
      if pch > 0
        pcdur = rand(1..5)
      end
      day_arr[gtai].push(rand(1..7))
      day_arr[pchi].push(pch)
      day_arr[pduri].push(pcdur)
    end

    year_arr = []
    for i in 0..8759
      hours_added = i
      future_date_time = get_future_date_time(start_year, hours_added)
      hour = future_date_time.strftime('%H').to_i
      weekday = future_date_time.strftime('%u').to_i ## 1-Monday

      if hour == 1
        gta = pch = 0
      end

      if (future_date_time >= start_winter1 && future_date_time <= end_winter1) ||
          (future_date_time >= start_winter2 && future_date_time <= end_winter2)
        if future_date_time == start_winter1
          j = 0
        end
        day = (j / 24).round()
        j = j + 1
        if weekday < 6
          if hour == 1
            pch = 0
            pcdur = day_arr[pduri][day]
            pc_st = (pcdur != 0) ? (dr_st - pcdur) : 0
          end

          if hour == pc_st
            if pc_st != 0
              pch = day_arr[pchi][day]
            end
          end
          if hour == dr_st
            gta = day_arr[gtai][day]

            pch = 0
            pcdur = 0
          end
          if hour == dr_en
            gta = 0
          end
        end
      end
      hour_arr = []
      hour_arr.push(future_date_time)
      hour_arr.push(weekday)
      hour_arr.push(gta)
      hour_arr.push(pch)
      year_arr.push(hour_arr)
    end

    headers = ["datetime","weekday","winter_gta","winter_preheat"]
    dr_fname = "out_winter_dr.csv"
    save_to_csv(year_arr, headers, dr_fname)
    dr_sch = load_from_csv(dr_fname)
    return dr_sch
  end

  def lighting_plugloads_adjusted(sch_orig, sch_adjust)
    new_sch = sch_orig.zip(sch_adjust).map{|x, y| ((1 - y) * x).round(4)}
    return new_sch
  end

  def cooling_adjusted(sch_C, cooling_adjust, pc_adjust)
    sch_F = sch_C.map { |c| (c * 9 / 5) + 32 }
    new_sch_F = sch_F.zip(cooling_adjust).map{|x, y| x + y}
    new_sch_F = (pc_adjust == 0) ? new_sch_F : new_sch_F.zip(pc_adjust).map{|x, y| x - y}
    new_sch_C = new_sch_F.map { |f| ((f - 32) * 5 / 9).round(4) }
    return new_sch_C
  end

  def heating_adjusted(sch_C, heating_adjust, ph_adjust)
    sch_F = sch_C.map { |c| (c * 9 / 5) + 32 }
    new_sch_F = sch_F.zip(heating_adjust).map{|x, y| x - y}
    new_sch_F = (ph_adjust == 0) ? new_sch_F  : new_sch_F.zip(ph_adjust).map{|x, y| x + y}
    new_sch_C = new_sch_F.map { |f| ((f - 32) * 5 / 9).round(4) }
    return new_sch_C
  end

  def apply_dr(building, vintage, drtype, period, orig_sch_all, usepredefined)

    buildings = ["bbr", "retail", "mediumofficedetailed", "largeofficedetailed"]
    periods = ["allyear", "summer", "winter"]
    drtypes = ["lighting", "plugloads", "summer_gta", "summer_precool","winter_gta","winter_preheat"]
    vintages = ["2010", "p1980",""]

    if buildings.include?(building) && vintages.include?(vintage) && drtypes.include?(drtype) && periods.include?(period)
      building_vintage = (building == "bbr") ? building + "_" : building + "_" + vintage + "_"
      

      if period == "allyear"
        dr_sch = allyear_dr()
      elsif period == "summer"
        dr_sch = summer_dr()
      elsif period == "winter"
        dr_sch = winter_dr()
      end
      # print dr_sch

      if drtype == "lighting" || drtype == "plugloads"
        orig_sch = usepredefined ? orig_sch_all[building_vintage + drtype] : orig_sch_all["my_schedule"]
        new_sch = lighting_plugloads_adjusted(orig_sch, dr_sch[drtype])

      elsif drtype == "summer_gta" || drtype == "summer_precool"
        orig_sch = usepredefined ? orig_sch_all[building_vintage + "cooling"] : orig_sch_all["my_schedule"]
        new_sch = (drtype == "summer_gta") ?
                      cooling_adjusted(orig_sch, dr_sch["summer_gta"], 0) :
                      cooling_adjusted(orig_sch, dr_sch["summer_gta"], dr_sch["summer_precool"])
      elsif drtype == "winter_gta" || drtype == "winter_preheat"
        orig_sch = usepredefined ? orig_sch_all[building_vintage + "heating"] : orig_sch_all["my_schedule"]
        new_sch = (drtype == "winter_gta") ?
                      cooling_adjusted(orig_sch, dr_sch["winter_gta"], 0) :
                      cooling_adjusted(orig_sch, dr_sch["winter_gta"], dr_sch["winter_preheat"])
      end
    end

    return new_sch
  end
  @@root_path = File.dirname(__FILE__) + '/'

  def initialize(building, vintage, drtype, period, usepredefined)

    osm_types = {"temperature" => "ScheduleTypeLimits,{99999999-9999-9999-9999-999999999999},Temperature,,,Continuous,Temperature;",
                 "fraction" => "ScheduleTypeLimits,{88888888-8888-8888-8888-888888888888},Fractional,0,1,Continuous;"}

    osm_headers = {"lighting" => "Schedule:Compact,{33333333-3333-3333-3333-333333333333}," + building + "_light_sch,{88888888-8888-8888-8888-888888888888},",
                   "plugloads" => "Schedule:Compact,{44444444-4444-4444-4444-444444444444}," + building + "_plugloads_sch,{88888888-8888-8888-8888-888888888888},",
                   "cooling" => "Schedule:Compact,{11111111-1111-1111-1111-111111111111}," + building + "_cooling_sch,{99999999-9999-9999-9999-999999999999},",
                   "heating" => "Schedule:Compact,{77777777-7777-7777-7777-777777777777}," + building + "_heating_sch,{99999999-9999-9999-9999-999999999999},"}

    osm_designdays = {"bbr_lighting" => "For: Saturday,Until: 06:00,0.1,Until: 09:00,0.5,Until: 15:00,0.9,Until: 19:00,0.9,Until: 21:00,0.9,Until: 24:00,0.5,For: Sunday,Until: 06:00,0.1,Until: 09:00,0.5,Until: 19:00,0.9,Until: 22:00,0.5,Until: 24:00,0.1,For: SummerDesignDay,Until: 24:00,1.0,For: WinterDesignDay,Until: 24:00,0.0,For: AllOtherDays,Until: 24:00,0.0",
                      "bbr_plugloads" => "For: Saturday,Until: 06:00,0.4,Until: 09:00,0.6,Until: 15:00,0.9,Until: 19:00,0.9,Until: 21:00,0.9,Until: 24:00,0.6,For: Sunday,Until: 06:00,0.4,Until: 09:00,0.6,Until: 19:00,0.9,Until: 22:00,0.6,Until: 24:00,0.4,For: SummerDesignDay,Until: 24:00,1.0,For: WinterDesignDay,Until: 24:00,0.0,For: AllOtherDays,Until: 24:00,0.0",
                      "bbr_cooling" => "For: Saturday,Until: 05:00,30.0,Until: 24:00,24.0,For: Sunday,Until: 05:00,30.0,Until: 22:00,24.0,Until: 24:00,30.0,For SummerDesignDay,Until: 24:00,24.0,For WinterDesignDay,Until: 24:00,30.0,For: AllOtherDays,Until: 24:00,30.0",
                      "retail_p1980_lighting" => "For:Saturdays,Until:7:00,0.05,Until:8:00,0.1,Until:9:00,0.3,Until:10:00,0.6,Until:18:00,0.9,Until:19:00,0.5,Until:21:00,0.3,Until:22:00,0.1,Until:24:00,0.05,For:Sundays,Until:8:00,0.05,Until:10:00,0.1,Until:12:00,0.4,Until:17:00,0.6,Until:18:00,0.4,Until:19:00,0.2,Until:24:00,0.05,For:SummerDesignDay,Until:24:00,1,For:WinterDesignDay,Until:24:00,0",
                      "retail_p1980_plugloads" => "For:Saturdays,Until:7:00,0.15,Until:8:00,0.3,Until:9:00,0.5,Until:10:00,0.8,Until:18:00,0.9,Until:19:00,0.7,Until:21:00,0.5,Until:22:00,0.3,Until:24:00,0.15,For:Sundays,Until:8:00,0.15,Until:10:00,0.3,Until:12:00,0.6,Until:17:00,0.8,Until:18:00,0.6,Until:19:00,0.4,Until:24:00,0.15,For:SummerDesignDay,Until:24:00,1,For:WinterDesignDay,Until:24:00,0",
                      "retail_p1980_cooling" => "For:Saturdays,Until:6:00,30,Until:22:00,24,Until:24:00,30,For:Sundays,Until:8:00,30,Until:19:00,24,Until:24:00,30,For:SummerDesignDay,Until:6:00,30,Until:21:00,24,Until:24:00,30,For:WinterDesignDay,Until:24:00,30",
                      "retail_2010_lighting" => "For: Saturdays,Until: 7:00,0.05,Until: 8:00,0.1,Until: 9:00,0.3,Until: 10:00,0.6,Until: 18:00,0.9,Until: 19:00,0.5,Until: 21:00,0.3,Until: 22:00,0.1,Until: 24:00,0.05,For: Sundays,Until: 9:00,0.05,Until: 10:00,0.1,Until: 12:00,0.4,Until: 17:00,0.6,Until: 18:00,0.4,Until: 19:00,0.2,Until: 24:00,0.05,For: SummerDesignDay,Until: 24:00,1,For: WinterDesignDay,Until: 24:00,0",
                      "retail_2010_plugloads" => "For:Saturdays,Until:7:00,0.15,Until:8:00,0.3,Until:9:00,0.5,Until:10:00,0.8,Until:18:00,0.9,Until:19:00,0.7,Until:21:00,0.5,Until:22:00,0.3,Until:24:00,0.15,For:Sundays,Until:9:00,0.15,Until:10:00,0.3,Until:12:00,0.6,Until:17:00,0.8,Until:18:00,0.6,Until:19:00,0.4,Until:24:00,0.15,For:SummerDesignDay,Until:24:00,1,For:WinterDesignDay,Until:24:00,0",
                      "retail_2010_cooling" => "For:SummerDesignDay,Until:6:00,29.44,Until:7:00,26.67,Until:21:00,23.89,Until:24:00,29.44,For:WinterDesignDay,Until:24:00,29.44",
                      "mediumofficedetailed_p1980_lighting" => "For:Saturdays,Until:6:00,0.05,Until:8:00,0.1,Until:12:00,0.3,Until:17:00,0.15,Until:24:00,0.05,For:Sundays,Until:24:00,0.05,For:SummerDesignDay,Until:24:00,1,For:WinterDesignDay,Until:24:00,0",
                      "mediumofficedetailed_p1980_plugloads" => "For:Saturdays,Until:6:00,0.3,Until:8:00,0.4,Until:14:00,0.5,Until:17:00,0.35,Until:24:00,0.3,For:Sundays,Until:24:00,0.3,For:SummerDesignDay,Until:24:00,1,For:WinterDesignDay,Until:24:00,0",
                      "mediumofficedetailed_p1980_cooling" => "For:Saturdays,Until:6:00,26.7,Until:18:00,24,Until:24:00,26.7,For:SummerDesignDay,Until:6:00,26.7,Until:22:00,24,Until:24:00,26.7,For:SundaysWinterDesignDay,Until:24:00,26.7",
                      "mediumofficedetailed_2010_lighting" => "For:Saturdays,Until:6:00,0.05,Until:8:00,0.0904,Until:12:00,0.2712,Until:17:00,0.1356,Until:19:00,0.0452,Until:24:00,0.05,For:Sundays,Until:6:00,0.05,Until:18:00,0.0452,Until:24:00,0.05,For:SummerDesignDay,Until:24:00,1,For:WinterDesignDay,Until:24:00,0",
                      "mediumofficedetailed_2010_plugloads" => "For:Saturdays,Until:6:00,0.23813625,Until:8:00,0.3841429,Until:12:00,0.480178625,Until:17:00,0.3361250375,Until:19:00,0.288107175,Until:24:00,0.23813625,For:Sundays,Until:6:00,0.23813625,Until:18:00,0.288107175,Until:24:00,0.23813625,For:SummerDesignDay,Until:24:00,1,For:WinterDesignDay,Until:24:00,0",
                      "mediumofficedetailed_2010_cooling" => "For:Weekends,Until:24:00,24,For:SummerDesignDay,Until:5:00,26.7,Until:6:00,25.7,Until:7:00,25,Until:22:00,24,Until:24:00,26.7,For:WinterDesignDay,Until:24:00,24",
                      "largeofficedetailed_2010_lighting" => "For:Saturdays,Until:6:00,0.05,Until:8:00,0.1,Until:12:00,0.3,Until:17:00,0.15,Until:24:00,0.05,For:Sundays,Until:24:00,0.05,For:SummerDesignDay,Until:24:00,1,For:WinterDesignDay,Until:24:00,0",
                      "largeofficedetailed_2010_plugloads" => "For:Saturdays,Until:6:00,0.3,Until:8:00,0.4,Until:12:00,0.5,Until:17:00,0.35,Until:24:00,0.3,For:Sundays,Until:24:00,0.3,For:SummerDesignDay,Until:24:00,1,For:WinterDesignDay,Until:24:00,0",
                      "largeofficedetailed_2010_cooling" => "For:Weekends,Until:24:00,24,For:SummerDesignDay,Until:5:00,26.7,Until:6:00,25.7,Until:7:00,25,Until:22:00,24,Until:24:00,26.7,For:WinterDesignDay,Until:24:00,24",
                      "largeofficedetailed_2010_heating" => "For:Saturdays,Until:4:00,15.6,Until:5:00,17.8,Until:6:00,20,Until:17:00,21,Until:24:00,15.6,For:SundaysHolidays,Until:24:00,15.6,For:SummerDesignDay,Until:24:00,15.6,For:WinterDesignDay,Until:5:00,15.6,Until:6:00,17.6,Until:7:00,19.6,Until:22:00,21,Until:24:00,15.6",
                      "largeofficedetailed_p1980_lighting" => "For:Saturdays,Until:6:00,0.05,Until:8:00,0.1,Until:12:00,0.3,Until:17:00,0.15,Until:24:00,0.05,For:Sundays,Until:24:00,0.05,For:SummerDesignDay,Until:24:00,1,For:WinterDesignDay,Until:24:00,0",
                      "largeofficedetailed_p1980_lighting_2" => "For:Saturdays,Until:6:00,0.05,Until:8:00,0.1,Until:12:00,0.3,Until:17:00,0.15,Until:24:00,0.05,For:Sundays,Until:24:00,0.05,For:SummerDesignDay,Until:24:00,1,For:WinterDesignDay,Until:24:00,0",
                      "largeofficedetailed_p1980_plugloads" => "For:Saturdays,Until:6:00,0.3,Until:8:00,0.4,Until:14:00,0.5,Until:17:00,0.35,Until:24:00,0.3,For:Sundays,Until:24:00,0.3,For:SummerDesignDay,Until:24:00,1,For:WinterDesignDay,Until:24:00,0",
                      "largeofficedetailed_p1980_plugloads_2" => "For:Saturdays,Until:6:00,0.3,Until:8:00,0.4,Until:12:00,0.5,Until:17:00,0.35,Until:24:00,0.3,For:Sundays,Until:24:00,0.3,For:SummerDesignDay,Until:24:00,1,For:WinterDesignDay,Until:24:00,0",
                      "largeofficedetailed_p1980_cooling" => "For:Saturdays,Until:6:00,26.7,Until:18:00,24,Until:24:00,26.7,For:SummerDesignDay,Until:6:00,26.7,Until:22:00,24,Until:24:00,26.7,For:Sundays WinterDesignDay,Until:24:00,26.7",
                      "largeofficedetailed_p1980_cooling_2" => "For:Weekends,Until:24:00,24,For:SummerDesignDay,Until:5:00,26.7,Until:6:00,25.7,Until:7:00,25,Until:22:00,24,Until:24:00,26.7,For:WinterDesignDay,Until:24:00,24",
                      "largeofficedetailed_p1980_heating" => "For:Saturdays,Until:6:00,15.6,Until:18:00,21,Until:24:00,15.6,For:Sundays,Until:24:00,15.6,For:SummerDesignDay,Until:24:00,15.6,For:WinterDesignDay,Until:24:00,21",
                      "largeofficedetailed_p1980_heating_2" => "For:Saturdays,Until:4:00,15.6,Until:5:00,17.8,Until:6:00,20,Until:17:00,21,Until:24:00,15.6,For:Sundays,Until:24:00,15.6,For:SummerDesignDay,Until:24:00,15.6,For:WinterDesignDay,Until:5:00,15.6,Until:6:00,17.6,Until:7:00,19.6,Until:22:00,21,Until:24:00,15.6,"}

    original_schedule = usepredefined ? load_from_csv("predefined_schedule.csv") : load_from_csv("my_schedule.csv")

    new_sch_arr = apply_dr(building, vintage, drtype, period, original_schedule, usepredefined)

    start_year = Time.utc(2006, 1, 1, 1)
    building_vintage = (building == "bbr") ? building + "_" : building + "_" + vintage + "_"
    if drtype == "lighting" || drtype == "plugloads"
      typ = "fraction"
      drt = drtype
    else
      typ = "temperature"
      if drtype == "summer_gta" || drtype == "summer_precool"
        drt = "cooling"
      elsif drtype == "winter_gta" || drtype == "winter_preheat"
        drt = "heating"
      end
    end
    dd_key = building_vintage + drt
    head = osm_types[typ] + "\n"
    compact_sch = osm_headers[drt] + "\n"
    if building != "bbr"
      head = "OS:" + head
      compact_sch = "OS:" + compact_sch
    end


    for i in 0..8759
      hours_added = i
      future_date_time = get_future_date_time(start_year, hours_added)
      month = future_date_time.strftime('%m').to_i
      day = future_date_time.strftime('%d').to_i
      date = month.to_s + "/" + day.to_s
      hour = future_date_time.strftime('%H').to_i

      hour = hour == 0 ? 24 : hour
      through_date = hour == 1 ? "Through:" + date + ",For:Weekdays," : ""
      if hour == 24
        design_days = osm_designdays[dd_key]
        design_days = i == 8759 ? design_days + ";" : design_days + ","
      else
        design_days = ""
      end
      value = new_sch_arr[i].to_s
      hour = "Until:" + hour.to_s + ":00," + value + ","

      compact_sch = compact_sch + through_date + hour + design_days + "\n"
    end

    File.write(@@root_path + "out_compact_schedule.osm", head + compact_sch)

    return head + compact_sch
  end

end
