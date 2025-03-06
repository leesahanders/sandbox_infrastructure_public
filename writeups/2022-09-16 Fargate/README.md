---
title: "Using Amazon Fargate with Posit Team"
date-meta: NA
last-update: 2022-09-16
# categories:
# tags:
---

This article explains how to set up Amazon Fargate with Posit Team and details the different mechanisms for its use as well as limitations and drawbacks and was up to date as of 2024-02. 

# Introduction

[Amazon Fargate](https://docs.aws.amazon.com/AmazonECS/latest/userguide/what-is-fargate.html) represents "containers as a service" in Amazon Web Services (AWS). It has two canonical uses: 

- Inside the Elastic Container Service (ECS)
- Inside the Elastic Kubernetes Service (EKS)

The usage of Posit products inside these different services will vary.

# Elastic Container Service (ECS)

It is possible to run Posit Workbench and Posit Package Manager inside of ECS with Amazon Fargate. In order to do this, verify that neither product is running in `--privileged` mode as Fargate does not allow privileged containers. 

This is enabled by default in our [public docker images](https://github.com/rstudio/rstudio-docker-products), [as discussed here](https://github.com/rstudio/rstudio-docker-products#privileged-containers).

It is currently not possible to run Posit Connect in `unprivileged` mode in Amazon ECS. As a result, we would recommend using another deployment mechanism. You can still use ECS on nodes, or you can use the EKS architecture, outlined below.

Please keep in mind that Posit products do not have a direct integration with ECS or Amazon Fargate. As a result, all workloads (user sessions, app deployments, etc.) will run _inside of the main service container(s)_. This is different from the "off host execution" model articulated below.

## Elastic Kubernetes Service (EKS)

Amazon EKS can be used to deploy all Posit products. When deploying Posit products into Kubernetes, we generally recommend making use of [our public helm charts](https://github.com/rstudio/helm). 

When deploying Posit Connect and Posit Workbench, it is important to consider the axis of "off-host execution." Posit Package Manager does not support (or need) off-host execution.

- Both products can run inside of Kubernetes with "local execution." This is the default for Posit Connect, and it requires `privileged` execution in this context.
- Both products can run inside of Kubernetes with "off-host execution." This means that user workloads are scheduled separately from the main service pods. This is the default for Posit Workbench. 

When using a Fargate Profile with Amazon EKS, scheduling is similar to ECS above. However, scheduling is done via the Kubernetes Cluster API. Namely, Posit Connect with local execution requires a `privileged` container and therefore cannot be scheduled to run on Fargate.

When using EKS, you do gain the ability to run off-host execution of user workloads and therefore for all Posit products to run in `unprivileged` containers. As a result, when using Kubernetes with off-host execution, all Posit products can be run via a Fargate profile.

In addition, all off-host execution user workloads are also possible to run via a Fargate profile on EKS.

### Fargate Profile Set-Up

In order to create a Fargate profile on AWS EKS, defining `selectors:` is required with [either a namespace or a label that will identify](https://docs.aws.amazon.com/eks/latest/userguide/fargate-profile.html) to Fargate that it is responsible for scheduling / running the container. 

For the purpose of our documentation, assume that our profile requires the selector label `fargate-job: true`.

### Fargate Pod Execution Role 

Specifying the [pod execution role](https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html) is needed for the components that will be run inside Fargate using the defined profile. 

### Tradeoffs

These tradeoffs were accurate as of Sep 16th, 2022. Fargate is a developing service by AWS and has likely changed and improved as an offering since these benchmarks were taken. Refer to further discussion [in the Amazon documentation on AWS Fargate](https://docs.aws.amazon.com/eks/latest/userguide/fargate.html). 

- **Sizing** - Fargate has [an upper bound](https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html) on container size. Please keep this in mind when deciding what workloads are ideal for Fargate
- **Startup time** - In our experience, container startup time on Fargate can vary wildly, from 2 minutes to 10 minutes. Startup on Fargate requires AWS to build a new EC2 instance, and then to pull the container image completely before starting the container. This makes it very useful for batch / asynchronous jobs, but a poor fit for interactive or on-demand workloads. Fargate is a constantly evolving service, so this may change in the future and this article will need to be revisited. 
- **Independent scheduling** - Every job on Fargate gets its own computational resources. This means you pay AWS more money for a given workload since there is no resource sharing; there is also a premium on those resources imposed by Fargate. However, this can be a great fit when workloads are highly sporadic (hard to schedule reliably / can affect one another) or utilize the resources completely. Again, this makes Fargate jobs well-suited for batch processes or when strict resource scheduling is required.
- **Timeouts** - Fargate jobs will continue running until they are complete. As discussed, this has implications on cost and on startup time to restart the task. VSCode sessions in Posit Workbench currently do not have a session timeout.
- **Orphans** - If a process is left around (i.e., sessions forgotten without timeout,  batch processes running forever, etc.), you will continue to incur costs on Amazon Fargate. This is at odds with an "EKS with nodes" paradigm where you pay for what your cluster collectively uses and node resources are often shared.
- **Volume options** - Fargate has limited [options for storage volumes](https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html#fargate-storage). EFS file system mounting and other static file mount options are supported, however dynamic persistent volume provisioning is not. Note that when [using EFS for file storage](https://docs.posit.co/rstudio-team/integration/efs/), Workbench will not be able to support project sharing due to the underlying requirement for ACL's. 

### Using the Helm Charts

The simplest configuration is to run the service on Fargate or all user workloads on Fargate (or both). A more advanced configuration is required to allow users to opt into running sessions on Fargate. Refer to the [Amazon documentation on using Helm with Amazon EKS here](https://docs.aws.amazon.com/eks/latest/userguide/helm.html). 

#### Service on Fargate

In order to run the service pod itself on Fargate as well as all launched user jobs, ensure that the service satisfies the Fargate profile. This is straightforward with a namespace, as discussed [in the amazon documentation for creating a Fargate profile for your cluster](https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html#fargate-gs-create-profile). If using a selector label, you can set the pod label in the helm chart by setting:

```yaml
pod:
  labels:
    # whatever label satisfies the Fargate profile
    fargate-job: true
```

#### User Workloads on Fargate

It is possible for either Posit Workbench or Posit Connect to run _all_ user workloads on Fargate. This can be done by setting selector labels under `launcher.templateValues`.

In order to run all jobs always inside of fargate, then you can just set the fargate label directly with `launcher.templateValues.pod.labels`. 

```yaml
launcher:
  enabled: true
  useTemplates: true
  templateValues:
    pod:
      labels:
        # whatever label satisfies the Fargate profile
        fargate-job: "true"
```

#### Advanced / Custom Configuration

However, for Posit Workbench, it is also possible to allow users (or just certain users) to opt into running jobs on AWS Fargate. This is achieved by using the notion of "placement constraints." We must still set the label to satisfy the Fargate profile, but placement constraints can be chosen by users in the User Interface.

The helm charts have not currently been tested with the modifications to run selective user workloads on AWS Fargate ( i.e., allow users to decide whether to run on Fargate or not). However, it is possible to use the helm charts to run the services on Fargate _or_ all user workloads on Fargate (or both).

In this case additional job templates `job.tpl` and `service.tpl` will be required. You can get the default template files by templating the chart directly (i.e. `helm template rstudio/rstudio-workbench --set launcher.useTemplates=true`), reviewing documentation, or using an existing Workbench installation.

Then you will need to modify `job.tpl` to set the appropriate Fargate selector label when the user selects the appropriate placement constraint.

_job.tpl_
```yaml
spec:
  backoffLimit: 0
  template:
    metadata:
      {{- /* BEGIN CHANGE */ -}}
      {{- $useFargate := false }}
      {{- range .Job.placementConstraints }}
        {{- if and (eq .name "eks.amazonaws.com/compute-type") (eq .value "fargate") }}
          {{- $useFargate := true }}
        {{- end }}
      {{- end }}
      labels:
        fargate-job: {{ $useFargate | quote }}
      {{- /* END CHANGE */}}
```

Values like the following will make this possible for all users:

_values.yaml_
```yaml
launcher:
  enabled: true
  useTemplates: true
  includeDefaultTemplates: false

config:
  profiles:
    launcher.kubernetes.profiles.conf:
      "*":
        placement-constraints: "eks.amazonaws.com/compute-type:not-fargate"
```

Finally the Kubernetes YAML manifest can be generated based on the specified helm chart using something like this: 

```bash
helm template rstudio/rstudio-workbench \
  -f values.yaml \
  --set-file launcher.extraTemplates.job\\.tpl=job.tpl \
  --set-file launcher.extraTemplates.service\\.tpl=service.tpl \
  | less
```

Posit Connect does not yet have a mechanism for exposing Fargate job selection or placement constraint selection to publishers.

### Standalone Workbench Configuration

In a standalone Workbench instance, you can either define that _all_ user jobs will launch into Fargate, or allow users to choose which jobs run in Fargate. As discussed above, configuration varies based on your choice here.

#### All Workloads

To run all user workloads in Fargate, you must ensure that your Fargate profile selector is set for every Workbench job. You can do this by using the namespace selector or using the [job templates](https://kubernetes.io/docs/concepts/workloads/controllers/job/) to hard-code a label. For instance,  using the label in the namespace by adding this line to `job.tpl` in pod labels: 

_job.tpl_
```yaml
labels:
  fargate-job: "true"
  {{- with .Job.metadata.pod.labels }}
  {{- range $key, $val := . }}
  {{ $key }}: {{ toYaml $val | indent 8 | trimPrefix (repeat 8 " ") }}
  {{- end }}
  {{- end }}
  {{- with $templateData.pod.labels }}
  {{- range $key, $val := . }}
  {{ $key }}: {{ toYaml $val | indent 8 | trimPrefix (repeat 8 " ") }}
  {{- end }}
  {{- end }}
```

Then change `service.tpl` to change the service type from `NodePort` to `ClusterIP`. This is required by Fargate, which as of the time of writing, does not advertise `NodePort` services correctly.

_service.tpl_
```yaml
  type: ClusterIP
```

#### Select Workloads

In order to run select workloads on Fargate, you must provide a `placement-constraint` to appropriate users on your system so that they can decide which jobs to run on Fargate. Let us presume that our Fargate profile requires the fargate-job: true label. To do this, configure `launcher.kubernetes.profiles.conf`:

_launcher.kubernetes.profiles.conf_
```ini
[*]
placement-constraints: eks.amazonaws.com/compute-type:fargate
```

Then the approach used is to: 

- Change `service.type` to `ClusterIP` (required for Fargate), see example above
- Add a `fargate-job: true` label by default
- When the `eks.amazonaws.com/compute-type` placement constraint equals `fargate`:
  - Add the `fargate-job: true` label

An example of how to customize the job templates so that labels are set appropriately upon placement constraint selection: 

_job.tpl_
```yaml
spec:
  backoffLimit: 0
  template:
    metadata:
      {{- /* BEGIN CHANGE */ -}}
      {{- $useFargate := false }}
      {{- range .Job.placementConstraints }}
        {{- if and (eq .name "eks.amazonaws.com/compute-type") (eq .value "fargate") }}
          {{- $useFargate := true }}
        {{- end }}
      {{- end }}
      labels:
        fargate-job: {{ $useFargate | quote }}
      {{- /* END CHANGE */}}
```

This example will enable users to switch to sending jobs to Fargate. 

![UI options for select workloads with Fargate](./imgs/fargate-ui.png){fig-alt="UI options for select workloads with Fargate"}

There are example templates here: 

- [Default Send Jobs to Fargate](https://github.com/rstudio/helm/tree/main/examples/launcher-templates/fargate/default-fargate)
- [Users Select Whether to Send Jobs to Fargate](https://github.com/rstudio/helm/tree/main/examples/launcher-templates/fargate/default-not)

### Standalone Connect Configuration

We do not recommend using a standalone Connect instance with the "off-host" execution feature required to use Fargate.


