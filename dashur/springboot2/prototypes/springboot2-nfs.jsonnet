// @apiVersion 0.1
// @name com.dashur.springboot2-nfs
// @description Dashur springboot app with nfs
// @shortDescription springboot2 app with nfs.
// @param namespace string Namespace in which to put the application
// @param name string Metadata name for each of the deployment components
// @param version string version


local k = import 'k.libsonnet';
local springboot2 = import 'dashur/springboot2/springboot2.libsonnet';
local defaultConfig = import 'dashur/springboot2/globals.libsonnet';
local namespace = import 'param://namespace';
local name = import 'param://name';
local version = import 'param://version';

  local project = defaultConfig.config[name];
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
