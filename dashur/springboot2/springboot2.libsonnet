local k = import 'k.libsonnet';
local deployment = k.extensions.v1beta1.deployment;
{
  parts:: {
    svc(defaults)::
      {
        apiVersion: 'v1',
        kind: 'Service',
        metadata: {
          name: defaults.appConfig.name,
          labels: {
            app: defaults.appConfig.name,
            type: 'app',
            version: defaults.appConfig.version,
          },
        },
        spec: {
          type: 'ClusterIP',
          ports: [
            {
              name: 'web',
              port: 80,
              targetPort: 'containerPort',
            },
          ],
          selector: {
            app: defaults.appConfig.name,
          },
        },
      },
    secret(defaults):: {
      apiVersion: 'v1',
      kind: 'Secret',
      metadata: {
        name: defaults.appConfig.name + "_"+defaults.appConfig.version,
        namespace: defaults.k8.namespace,
        labels: {
         app: defaults.appConfig.name,
        },
      },
      type: 'Opaque',
      data: {
        secret: std.base64("ABC"),
      },
    },

    configMap(defaults)::
      local config = |||
        "spring :
          security:
            filter-order: 0
            oauth2:
              resource:
                filter-order: 3
          http.converters.preferred-json-mapper : jackson"
      |||;
      {
        apiVersion: 'v1',
        kind: 'ConfigMap',
        metadata: {
          name: defaults.appConfig.name,
          namespace: defaults.k8.namespace,
        },
        data: {
          'application.yaml': config,
        },
      },
    deployment:: {
      nfs(defaults,nfsEnabled=true)::
      base(defaults, nfsEnabled),
      nonNfs(defaults , nfsEnabled=false)::
      base(defaults, nfsEnabled),
      local base(defaults, nfsEnabled) =
        {
          apiVersion: 'extensions/v1beta1',
          kind: 'Deployment',
          metadata: {
            name: defaults.appConfig.name,
            namespace: defaults.k8.namespace,
            labels: {
              app: defaults.appConfig.name,
              version: defaults.appConfig.version,
              type: 'app',
            },
          },
          spec: {
            revisionHistoryLimit: 3,
            minReadySeconds: 20,
            template: {
              metadata: {
                namespace: defaults.k8.namespace,
                labels: {
                    app : defaults.appConfig.name
                },
              },
              spec: {
                securityContext: {
                  fsGroup: 9999,
                },
                containers: [
                  {
                    name: 'app',
                    image: 'kube-registry.kube-system.svc.' + defaults.k8.registryClusterName + ':5000/dashur/' + defaults.appConfig.image + ':' + defaults.appConfig.version,
                    imagePullPolicy: defaults.imagePullPolicy,
                    env: [
                      {
                        name: 'APP_NAME',
                        value: defaults.appConfig.name,
                      },
                      {
                        name: 'APP_VERSION',
                        value: defaults.appConfig.version,
                      },
                      {
                        name: 'CONFIG_FILES',
                        value: defaults.appConfig.configLocation,
                      },
                      {
                        name: 'FLUENTD_HOST',
                        value: 'fluentd-logger.kube-system.svc.cluster.local',
                      },
                      {
                        name: 'MAX_HEAP_SPACE',
                        value: '2048M',
                      },
                      {
                        name: 'MIN_HEAP_SPACE',
                        value: '2048M',
                      },
                      {
                        name: 'POD_NAMESPACE',
                        valueFrom: {
                          fieldRef: {
                            fieldPath: 'metadata.namespace',
                          },
                        },
                      },
                    ] + defaults.parameter
                    ,
                    ports: [
                      {
                        name: 'containerPort',
                        containerPort: 8080,
                      },
                    ],
                    readinessProbe: {
                      httpGet: {
                        path: '/actuator/health',
                        port: 8080,
                      },
                      initialDelaySeconds: 20,
                      timeoutSeconds: 2,
                    },
                    livenessProbe: {
                      httpGet: {
                        path: '/actuator/health',
                        port: 8080,
                      },
                      initialDelaySeconds: 120,
                      timeoutSeconds: 2,
                    },
                    resources: defaults.resources,
                    volumeMounts: [
                      {
                        mountPath: '/conf',
                        name: 'config-volume',
                        readOnly: true,
                      },
                      +if nfsEnabled then {
                        mountPath: '/data',
                        name: 'data',
                        readOnly: false,
                      } else {},
                    ],
                  },
                ],
                volumes: [
                  {
                    name: 'config-volume',
                    configMap: {
                      name: defaults.appConfig.name+defaults.appConfig.version,
                    },
                  },
                  +if nfsEnabled then {
                    name: 'data',
                    nfs: {
                      path: '/',
                      server: 'nfs-reporting' + defaults.k8.namespace + '.svc.' + defaults.k8.clusterName,
                    },
                  }
                  else {},
                ],
              },
            },
          },
        },
    },
  },
}
