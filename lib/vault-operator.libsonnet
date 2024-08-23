// main template for vault-operator
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.vault_operator;

// --- Non Public

local serviceAccount(vault) = kube.ServiceAccount(vault.spec.serviceAccount) {
  metadata+: {
    namespace: vault.metadata.namespace,
  },
};

local role(vault) = kube.Role('vault') {
  metadata+: {
    namespace: vault.metadata.namespace,
  },
  rules: [
    { apiGroups: [ '' ], resources: [ 'secrets' ], verbs: [ '*' ] }
    { apiGroups: [ '' ], resources: [ 'pods' ], verbs: [ 'get', 'update', 'patch' ] },
  ],
};
local roleBinding(vault) = kube.RoleBinding('vault') {
  metadata+: {
    namespace: vault.metadata.namespace,
  },
  roleRef_:: role(vault),
  subjects_:: [ serviceAccount(vault) ],
};
local clusterRoleBinding(vault) = kube.ClusterRoleBinding('vault-auth-delegator') {
  roleRef: {
    apiGroup: 'rbac.authorization.k8s.io',
    kind: 'ClusterRole',
    name: 'system:auth-delegator',
  },
  subjects_:: [ serviceAccount(vault) ],
};

// --- End Non Public

local Vault(namespace, name) = kube._Object('vault.banzaicloud.com/v1alpha1', 'Vault', name) {
  metadata+: {
    namespace: namespace,
  },
  spec: {
    size: 3,
    image: '%(registry)s/%(repository)s:%(version)s' % params.images.vault,
    serviceAccount: name,
  },
};

local RBAC(vault) = [
  serviceAccount(vault),
  role(vault),
  roleBinding(vault),
  clusterRoleBinding(vault),
];

{
  Vault: Vault,
  RBAC: RBAC,
}
