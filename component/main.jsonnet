// main template for vault-operator
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
local vo = import 'lib/vault-operator.libsonnet';

// The hiera parameters for the component
local params = inv.parameters.vault_operator;
local isOpenshift = std.startsWith(inv.parameters.facts.distribution, 'openshift');

local namespace = kube.Namespace(params.namespace) {
  metadata+: {
    labels+: {
      'app.kubernetes.io/name': params.namespace,
      // Configure the namespaces so that the OCP4 cluster-monitoring
      // Prometheus can find the servicemonitors and rules.
      [if isOpenshift then 'openshift.io/cluster-monitoring']: 'true',
    },
  },
};

local instance(instanceName, spec) =
  local vault = vo.Vault(instanceName, 'vault') { spec+: com.makeMergeable(spec) };
  vo.RBAC(vault) + [ vault ];

// Define outputs below
{
  '00_namespace': namespace,
} + {
  ['20_instance_%s' % name]: instance(name, params.instances[name])
  for name in std.objectFields(params.instances)
}
