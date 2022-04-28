# How EFOnt can help building energy flexibility simulations

Traditionaly, BEM tools were designed to simulate building energy and thermal performance. As energy flexibility becomes an increasingly important building performance aspect, there are growing needs for simulating energy flexibility using BEM. However, the data dictionaries and input/output specifications of existing BEM tools do not have clear guidance on how to simulate energy flexibility. The barriers are mainly two-folds. Firstly, there is no description of which energy flexibility resources could be simulated using which objects in the BEM tools. Secondly, there is no description of which KPIs can be used to evaluate the energy flexibility, and which BEM sensor, meter, and variables are needed to compute the KPIs.

As a result, energy modelers who want to simulate energy flexibility need to understand which objects to modify in their models, extract the simulation results and compute the KPIs case-by-case, which can be tedious and error-prone. EFOnt can serve as an interface between energy modelers and BEM tools, which maps typical energy flexibility resources and related output variables with BEM objects. Figure 1 shows an example of such mapping. 

<figure>
<img src="../../resources/EFOnt_BEM_map_1.png" style="width:100%">
<figcaption align = "center"><b>Figure 1. EFOnt for simulating Energy Flexibility with EnergyPlus objects</b></figcaption>
</figure>

# Examples

The following two examples will demonstrate how EFOnt could help simulating and quantifying building energy flexibility in more details. Both examples used DOE prototype small office building models with OpenStudio and EnergyPlus. 15 climate zones were considered to show the geographical differences. Table 1 shows the geometry and basic information of the building.

<table>
    <caption><b>Table 1. Model Description</b></caption>
    <thead>
        <tr>
            <th>Building Geometry</th>
            <th>Basic Information</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><figure>
                    <img src="../../resources/EFOnt_example_bldg.png" style="width:100%">
            </figure></td>
            <td><ul>
                <li>Building: DOE small office building</li>
                <li>Total floor area: 511.2 m²</li>
                <li>Roof area: 598.8 m²</li>
                <li>Lighting power density: 8.8 W/m²</li>
                <li>MELs power density: 6.8 W/m²</li>
                <li>Climate Zones (15): 1A, 2A, 2B, 3A, 3B, 3C, 4A, 4B, 4C, 5A, 5B, 6A, 6B, 7A, 8A</li>
            </ul></td>
        </tr>
    </tbody>
</table>


## Example 1 - EF with on-site PV generation and EV-charging
In the first example, we show how EFOnt can help quantify the on-site PV utilization performance using two EF KPIs - Self-Sufficiency and Self-Consumption. As introduced, EFOnt maps energy flexibility resources with BEM objects. 

<b>Figure 2</b> shows the flexibility resources defined in EFOnt and corresponding EnergyPlus objects to model PV generation and EV demand.

<figure>
<img src="../../resources/EFOnt_BEM_map_2.png" style="width:100%">
<figcaption align = "center"><b>Figure 2. EFOnt maps energy flexibility resources with EnergyPlus objects</b></figcaption>
</figure>

<b>Figure 3</b> maps the energy EnergyPlus outputs to KPI computation inputs.

<figure>
<img src="../../resources/EFOnt_BEM_map_3.png" style="width:100%">
<figcaption align = "center"><b>Figure 3. EFOnt maps energy EnergyPlus outputs to KPI computation inputs</b></figcaption>
</figure>






## Example 2 - EF with peak reduction operations (pre-cooling and pre-heating, lighting and MELs reduction)

![](sim_case_building.png)
![](sim_case_precond_objects.png)
![](sim_case_peak_reduction_results_1.png)
![](sim_case_peak_reduction_results_2.png)


