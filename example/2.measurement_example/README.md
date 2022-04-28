# How EFOnt can help building energy flexibility analytics using measured data.

As sensing and metering technologies become widely available, more and more building operational data are collected from building automation systems (BAS) and smart thermostats at scale. In general, those data provides opportunity to unlock building energy flexibility from two perspectives:
1. Analyzing energy flexibility of past operation strategies using historical measurements (post hoc).
2. Developing data-driven models which could then be used to predict energy flexibility in the future (ex ante).

Either approach needs to clearly define, characterize, and quantify energy flexibility. The lack of commonly agreed energy flexibility terminologies, data requirements, and quantification methods lead to confusion and redundancy. EFOnt aims to serve as common ground of energy flexibility, where researchers and practitioners can co-develop standardized terminologies and KPIs.


# Example

In the following example, we show how EFOnt can help quantify energy flexibility using the EcoBee smart thermostat data. The thermostat data include timeseries of indoor air temperature, cooling and heating setpoint temperature, supply fan runtime, cooling and heating system runtime. It also recorded special events such as demand response (DR), during which the thermostat can adjust the temperature setpoint to reduce power demand. A KPI called Flexibility Factor (FF) shown in the below equation is used to quantify daily energy flexibility during a demand response event.

<table align="center" border=0>
  <tr>
    <td align="center"><img src="../../resources/EFOnt_FF_equation.png" style="width:100%"></td>
    <td><figcaption><b>Equation 1. Flexibility Factor</b></figcaption></td>
  </tr>
</table>

FF needs the system runtime profile and DR event start and end timestamps. Figure 1 shows how EFOnt defines the KPI and acronym, specifies the required data, performance goals, and stakeholders who might be interested  (left). It also shows how the specified inputs are used in the calculation (right). In this particular day, the purple dash line indicates the cooling system (compressor) runtime, the black dashline shows the cooling setpoint temperature, the green line shows the room air temperature, and the pink shaded area indicates the DR event. It can be seen that the cooling setpoint temperature was raised from around 74.2 °F to 78 °F as the DR event started, the system paused running, and the room air temperature gradually increased. Since most the cooling system almost didn't operate during the DR event, its FF was 0.983.

<table align="center" border=0>
  <tr>
    <td align="center"><img src="../../resources/EFOnt_FF_example.png" style="width:100%"></td>
  </tr>
  <tr>
    <td><figcaption><b>Figure 1. Flexibility Factor example</b></figcaption></td>
  </tr>
</table>


# Notes
