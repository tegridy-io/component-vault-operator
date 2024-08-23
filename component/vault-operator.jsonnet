// main template for cm-hetznercloud
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.vault_operator;

local vaultOperator = com.Kustomization(
  'https://github.com/bank-vaults/vault-operator//deploy/default',
  params.manifestVersion,
  {
    'ghcr.io/bank-vaults/vault-operator': {
      newTag: params.images.operator.tag,
      newName: '%(registry)s/%(repository)s' % params.images.operator,
    },
  },
  {
    resources: [
      'https://github.com/bank-vaults/vault-operator//deploy/manager?ref=%s' % params.manifestVersion,
    ],
    patchesStrategicMerge: [
      'rm-namespace.yaml',
    ],
  } + com.makeMergeable(params.kustomizeInput),
) {
  'rm-namespace': {
    '$patch': 'delete',
    apiVersion: 'v1',
    kind: 'Namespace',
    metadata: {
      name: 'system',
    },
  },
};

vaultOperator
