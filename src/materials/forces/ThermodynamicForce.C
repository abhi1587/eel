// Copyright 2023, UChicago Argonne, LLC All Rights Reserved
// License: L-GPL 3.0
#include "ThermodynamicForce.h"

template <typename T>
InputParameters
ThermodynamicForce<T>::validParams()
{
  InputParameters params = DerivativeMaterialInterface<Material>::validParams();
  params.addRequiredParam<std::vector<MaterialPropertyName>>("energy_densities",
                                                             "Vector of energy densities");
  params.addParam<Real>("factor", 1, "Factor to be multiplied");
  return params;
}

template <typename T>
ThermodynamicForce<T>::ThermodynamicForce(const InputParameters & parameters)
  : DerivativeMaterialInterface<Material>(parameters),
    _force(nullptr),
    _psi_names(getParam<std::vector<MaterialPropertyName>>("energy_densities")),
    _d_psi_d_s(_psi_names.size()),
    _factor(getParam<Real>("factor"))
{
}

template <typename T>
void
ThermodynamicForce<T>::getThermodynamicForces(std::vector<const ADMaterialProperty<T> *> & forces,
                                              const std::vector<MaterialPropertyName> & densities,
                                              const std::string var)
{
  for (auto i : make_range(densities.size()))
    forces[i] =
        &getDefaultMaterialPropertyByName<T, true>(derivativePropertyName(densities[i], {var}));
}

template <typename T>
void
ThermodynamicForce<T>::computeQpProperties()
{
  (*_force)[_qp] = _factor * computeQpThermodynamicForce(_d_psi_d_s);
}

template <typename T>
typename Moose::ADType<T>::type
ThermodynamicForce<T>::computeQpThermodynamicForce(
    const std::vector<const ADMaterialProperty<T> *> forces) const
{
  typename Moose::ADType<T>::type f;
  MathUtils::mooseSetToZero(f);
  for (const auto & force : forces)
    f += (*force)[_qp];
  return f;
}

template class ThermodynamicForce<Real>;
template class ThermodynamicForce<RealVectorValue>;
template class ThermodynamicForce<RankTwoTensor>;
