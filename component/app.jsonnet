local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.vault_operator;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('vault-operator', params.namespace);

{
  'vault-operator': app,
}
