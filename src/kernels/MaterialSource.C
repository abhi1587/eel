// Copyright 2023, UChicago Argonne, LLC All Rights Reserved
// License: L-GPL 3.0
#include "MaterialSource.h"

registerMooseObject("EelApp", MaterialSource);

InputParameters
MaterialSource::validParams()
{
  InputParameters params = ADKernelValue::validParams();
  params.addClassDescription("Source term defined by the material property");
  params.addRequiredParam<MaterialPropertyName>(
      "prop", "Name of the material property to provide the multiplier");
  params.addParam<Real>("coefficient", 1, "Coefficient to be multiplied to the source");
  return params;
}

MaterialSource::MaterialSource(const InputParameters & parameters)
  : ADKernelValue(parameters),
    _prop(getADMaterialProperty<Real>("prop")),
    _coef(getParam<Real>("coefficient"))
{
}

ADReal
MaterialSource::precomputeQpResidual()
{
  return _coef * _prop[_qp];
}
