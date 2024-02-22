# units are in meter kelvin second (m,kg,s)

# frequency
f = 100
omega = '${fparse 2*pi*f}'

tcharge = 10800 # 3hr*3600
end_time = '${tcharge}'

dtmax = 60
dt = 1

T_melting = '${fparse 350+273.15}'
delta_T_pc = 8 # The temperature range of the melting/solidification process
L = 373.9e3 # Latent heat

# kappa_PCMGF = 18.8 # W/m-K (average of Kxy = 14 W/m-K, Kz = 23.6 W/mK at T=700C) #from Singh et al. Solar energy 159(2018) 270-282 (Prototype 1)
kappa_PCMGF_rr = 14 # W/m-K
kappa_PCMGF_tt = 14 # W/m-K
kappa_PCMGF_zz = 23.6 # W/m-K
rho_PCMGF = 2050 # kg/m^3
cp_PCMGF = 1074 # J/kg-K

kappa_tube_T = '298.15 373.15 473.15 573.15 673.15 773.15 873.15 973.15 1023.15'
kappa_tube = '14.1 15.4 16.8 18.3 19.7 21.2 22.4 23.9 24.6' # W/m-K
rho_tube = 8030 # kg/m^3
cp_tube = 550 # J/kg-K

kappa_container_T = '298.15 373.15 473.15 573.15 673.15 773.15 873.15 973.15 1023.15'
kappa_container = '14.1 15.4 16.8 18.3 19.7 21.2 22.4 23.9 24.6' # W/m-K
rho_container = 8030 # kg/m^3
cp_container = 550 # J/kg-K

kappa_insulation = 0.12 # W/m-K (Durablanket S from UNIFRAX) Wen emailed on 2023-03-31
rho_insulation = 2730 # kg/m^3 (Durablanket S from UNIFRAX) Wen emailed on 2023-03-31
cp_insulation = 1130 # J/kg-K (Durablanket S from UNIFRAX) Wen emailed on 2023-03-31

htc_insul = 5
T_inf_insul = 300
htc_tube = 5
T_inf_tube = 300
T0 = 300

# applied current density
V = 100 # Volt
R_coil = 0.23775 # m
n_coil = 9
sigma_coil = 5.8e7 # S/m
i = '${fparse sigma_coil*V/2/pi/R_coil/n_coil}'
# r_coil = 0.0127 # m
# coil_ratio = 0.1 # 90% of coil cross-section is hollow for coolant run-through
# I = '${fparse i*pi*r_coil^2*coil_ratio}'
# P = '${fparse V*I}'

[GlobalParams]
  energy_densities = 'H'
[]

[MultiApps]
  [induction]
    type = TransientMultiApp
    input_files = 'induction.i'
    cli_args = 'omega=${omega};i=${i};sigma_coil=${sigma_coil}'
  []
[]

[Transfers]
  [to_T]
    type = MultiAppShapeEvaluationTransfer
    to_multi_app = 'induction'
    source_variable = 'T'
    variable = 'T'
  []
  [from_q]
    type = MultiAppShapeEvaluationTransfer
    from_multi_app = 'induction'
    source_variable = 'q'
    variable = 'q'
  []
[]

[Mesh]
  [fmg0]
    type = FileMeshGenerator
    file = 'gold/model_v002.exo'
  []
  [fmg]
    type = MeshRepairGenerator
    input = fmg0
    fix_elements_orientation = true
  []
  [scale]
    type = TransformGenerator
    input = fmg
    transform = SCALE
    vector_value = '1e-3 1e-3 1e-3'
  []
  [delete]
    type = BlockDeletionGenerator
    input = scale
    block = 'coil air'
  []
  coord_type = RZ
[]

[Variables]
  [T]
    initial_condition = ${T0}
  []
[]

[AuxVariables]
  [q]
    order = CONSTANT
    family = MONOMIAL
  []
  [T_old]
    [AuxKernel]
      type = ParsedAux
      expression = 'T'
      coupled_variables = 'T'
      execute_on = 'INITIAL TIMESTEP_BEGIN'
    []
  []
  [phase]
    block = 'PCMGF'
    [AuxKernel]
      type = ParsedAux
      expression = 'if(T<Tm, 0, if(T<Tm+dT, (T-Tm)/dT, 1))'
      coupled_variables = 'T'
      constant_names = 'Tm dT'
      constant_expressions = '${T_melting} ${delta_T_pc}'
      execute_on = 'INITIAL TIMESTEP_BEGIN'
    []
  []
[]

[Kernels]
  [energy_balance_1]
    type = EnergyBalanceTimeDerivative
    variable = T
    density = rho
    specific_heat = cp
  []
  [energy_balance_2]
    type = RankOneDivergence
    variable = T
    vector = h
  []
  [heat_source]
    type = CoupledForce
    variable = T
    v = q
  []
[]

[BCs]
  [hconv_insul]
    type = ADMatNeumannBC
    variable = T
    boundary = 'insul_top insul_od insul_bot'
    value = -1
    boundary_material = qconv_insul
  []
  [hconv_tube]
    type = ADMatNeumannBC
    variable = T
    boundary = 'pipe_id'
    value = -1
    boundary_material = qconv_tube
  []
[]

[Materials]
  [tube]
    type = ADGenericConstantMaterial
    prop_names = 'rho cp'
    prop_values = '${rho_tube} ${cp_tube}'
    block = 'tube'
  []
  [tube_kappa]
    type = ADPiecewiseLinearInterpolationMaterial
    property = 'kappa_iso'
    variable = 'T'
    x = ${kappa_tube_T}
    y = ${kappa_tube}
    block = 'tube'
  []
  [PCMGF]
    type = ADGenericConstantMaterial
    prop_names = 'rho'
    prop_values = '${rho_PCMGF}'
    block = 'PCMGF'
  []
  [PCMGF_kappa]
    type = ADGenericConstantRankTwoTensor
    tensor_name = 'kappa'
    tensor_values = '${kappa_PCMGF_rr} ${kappa_PCMGF_tt} ${kappa_PCMGF_zz}'
    block = 'PCMGF'
  []
  [container]
    type = ADGenericConstantMaterial
    prop_names = 'rho cp'
    prop_values = '${rho_container} ${cp_container}'
    block = 'container_pipe container_plate'
  []
  [container_kappa]
    type = ADPiecewiseLinearInterpolationMaterial
    property = 'kappa_iso'
    variable = 'T'
    x = ${kappa_container_T}
    y = ${kappa_container}
    block = 'container_pipe container_plate'
  []
  [insulation]
    type = ADGenericConstantMaterial
    prop_names = 'rho cp'
    prop_values = '${rho_insulation} ${cp_insulation}'
    block = 'insulation'
  []
  [insulation_kappa]
    type = ADGenericConstantMaterial
    prop_names = 'kappa_iso'
    prop_values = '${kappa_insulation}'
    block = 'insulation'
  []
  # For melting and solidification
  [gaussian_function]
    type = ADParsedMaterial
    property_name = D
    expression = 'exp(-T*(T-Tm)^2/dT^2)/sqrt(3.1415926*dT^2)'
    coupled_variables = 'T'
    constant_names = 'Tm dT'
    constant_expressions = '${T_melting} ${delta_T_pc}'
    block = 'PCMGF'
  []
  [specific_heat_PCMGF]
    type = ADParsedMaterial
    property_name = cp
    expression = '${cp_PCMGF} + ${L} * D'
    material_property_names = 'D'
    block = 'PCMGF'
  []
  [heat_conduction]
    type = FourierPotential
    thermal_energy_density = H
    thermal_conductivity = kappa_iso
    temperature = T
    block = 'tube container_pipe container_plate insulation'
  []
  [heat_conduction_PCMGF]
    type = AnisotropicFourierPotential
    thermal_energy_density = H
    thermal_conductivity = kappa
    temperature = T
    block = 'PCMGF'
  []
  [heat_flux]
    type = HeatFlux
    heat_flux = h
    temperature = T
  []
  [qconv_insul]
    type = ADParsedMaterial
    property_name = qconv_insul
    expression = 'htc*(T-T_inf)'
    coupled_variables = 'T'
    constant_names = 'htc T_inf'
    constant_expressions = '${htc_insul} ${T_inf_insul}'
    boundary = 'insul_top insul_od insul_bot'
  []
  [qconv_tube]
    type = ADParsedMaterial
    property_name = qconv_tube
    expression = 'htc*(T-T_inf)'
    coupled_variables = 'T'
    constant_names = 'htc T_inf'
    constant_expressions = '${htc_tube} ${T_inf_tube}'
    boundary = 'pipe_id'
  []
  [delta_enthalpy]
    type = ADParsedMaterial
    property_name = 'dh'
    expression = 'rho*cp*(T-T_old)/2'
    material_property_names = 'rho cp'
    coupled_variables = 'T T_old'
  []
[]

[Postprocessors]
  [PCMGF_volume]
    type = VolumePostprocessor
    block = 'PCMGF'
    execute_on = 'INITIAL'
    outputs = none
  []
  [PCMGF_molten]
    type = ElementIntegralVariablePostprocessor
    variable = phase
    block = 'PCMGF'
    execute_on = 'INITIAL TIMESTEP_END'
    outputs = none
  []
  [molten_fraction]
    type = ParsedPostprocessor
    pp_names = 'PCMGF_molten PCMGF_volume'
    function = 'PCMGF_molten/PCMGF_volume'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [PCMGF_Tmax]
    type = NodalExtremeValue
    variable = T
    block = 'PCMGF'
    value_type = max
    execute_on = 'INITIAL TIMESTEP_END'
  []
  # energy in tube
  [dH_tube]
    type = ADElementIntegralMaterialProperty
    mat_prop = dh
    execute_on = 'INITIAL TIMESTEP_END'
    block = 'tube'
    outputs = none
  []
  [H_tube]
    type = CumulativeValuePostprocessor
    postprocessor = 'dH_tube'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  # energy in PCMGF
  [dH_PCMGF]
    type = ADElementIntegralMaterialProperty
    mat_prop = dh
    execute_on = 'INITIAL TIMESTEP_END'
    block = 'PCMGF'
    outputs = none
  []
  [H_PCMGF]
    type = CumulativeValuePostprocessor
    postprocessor = 'dH_PCMGF'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  # energy in container
  [dH_container]
    type = ADElementIntegralMaterialProperty
    mat_prop = dh
    execute_on = 'INITIAL TIMESTEP_END'
    block = 'container_pipe container_plate'
    outputs = none
  []
  [H_container]
    type = CumulativeValuePostprocessor
    postprocessor = 'dH_container'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  # energy in insulation
  [dH_insulation]
    type = ADElementIntegralMaterialProperty
    mat_prop = dh
    execute_on = 'INITIAL TIMESTEP_END'
    block = 'insulation'
    outputs = none
  []
  [H_insulation]
    type = CumulativeValuePostprocessor
    postprocessor = 'dH_insulation'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [power]
    type = ElementIntegralVariablePostprocessor
    variable = q
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[UserObjects]
  [kill]
    type = Terminator
    expression = 'molten_fraction>0.95'
    message = '95% of PCM has molten.'
    execute_on = 'TIMESTEP_END'
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON

  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  automatic_scaling = true

  end_time = ${end_time}
  dtmax = ${dtmax}
  dtmin = 0.01
  [TimeStepper]
    type = IterationAdaptiveDT
    dt = ${dt}
    cutback_factor = 0.2
    cutback_factor_at_failure = 0.1
    growth_factor = 1.2
    optimal_iterations = 7
    iteration_window = 2
    linear_iteration_ratio = 100000
  []
  [Predictor]
    type = SimplePredictor
    scale = 1
    skip_after_failed_timestep = true
  []

  nl_abs_tol = 1e-8
  nl_rel_tol = 1e-6
  nl_max_its = 12
[]

[Outputs]
  file_base = 'charging_f_${f}/out'
  exodus = true
  csv = true
  print_linear_residuals = false
[]
