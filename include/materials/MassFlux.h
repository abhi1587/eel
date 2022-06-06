#pragma once

#include "Material.h"
#include "BaseNameInterface.h"
#include "DerivativeMaterialInterface.h"

/**
 * This class computes the mass flux associated with given energy densities for a given species.
 */
class MassFlux : public DerivativeMaterialInterface<Material>, public BaseNameInterface
{
public:
  static InputParameters validParams();

  MassFlux(const InputParameters & parameters);

  virtual void computeQpProperties() override;

protected:
  /// The mass flux
  ADMaterialProperty<RealVectorValue> & _J;

  /// Name of the concentration variable
  const VariableName _c_name;

  /// @{ Energy densities
  std::vector<MaterialPropertyName> _psi_names;
  std::vector<const ADMaterialProperty<RealVectorValue> *> _d_psi_d_grad_c;
  /// @}
};
