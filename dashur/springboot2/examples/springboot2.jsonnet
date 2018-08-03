local env = std.extVar("__ksonnet/environments");
local params = std.extVar("__ksonnet/params").components["parquet-processor"];

local k = import 'k.libsonnet';
local springboot2 = import 'dashur/springboot2/springboot2.libsonnet';
local defaultConfig = import 'dashur/springboot2/globals.libsonnet';
local namespace = params.namespace;
local name = params.name;
local version = params.version;

  local project = defaultConfig[name];
  local defaults = {
    k8: {
      content: 'dev-context',
      namespace: 'dev',
      clusterName: 'cluster.local',
      registryClusterName: 'dev-cluster',
    },
    parameter: [{
      name: 'JAVA_OPTS',
      value: '-Djava.net.preferIPv4Stack=true',
    }],
    imagePullPolicy: 'Always',
    resources: {
      requests: {
        memory: '2200Mi',
        cpu: '1000m',
      },
    },
    appConfig: {
      name: name,
      image:  project.image,
      version: version,
      configLocation: project.config,
    },
  };

k.core.v1.list.new([
springboot2.parts.deployment.nfs(defaults),
springboot2.parts.secret(defaults),
springboot2.parts.svc(defaults)
])
