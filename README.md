# iron-kluster
Local Kubernetes Cluster Automation for Iron Project

## Next

https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart


## Goals:

1. Self managed cluster in
  1. AWS
  2. GCP
  3. Azure
2. Optimize to use as much shared code as possible in the environments
  1. As much as possible used shared TF Modules & Ansible Playbooks
3. Setup a spanned istio environment
4. Setup an example application in the environment
5. Secure the environment
6. Make this so it can be deployed securely using an intermediate VM or container
  1. For now all TF & ansible will be run from local system
  2. Design should allow for this to be done from the cloud to lock down configuration

## Current Setup Instructions

```sh
cd terraform/aws
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
tf init
tf apply

cd ../../ansible
ansible-playbook -i ../state_files/inventory.ini kube_install_base.yml
ansible-playbook -i ../state_files/inventory.ini kube_install_control.yml
ansible-playbook -i ../state_files/inventory.ini kube_install_worker.yml
```

### Cleanup

```sh
cd terraform/aws
tf destroy -auto-approve
```

To access these system from local add something like the following to your `~/.ssh/config` file:

```ssh.config
Host *.iron.lcsas.net
    IdentityFile ~/src/ssimpson/iron-kluster/state_files/iron_id
    IdentitiesOnly yes
    StrictHostKeyChecking yes
    User ubuntu
    UserKnownHostsFile ~/src/ssimpson/iron-kluster/state_files/ssh_known_hosts
```

## Methods and Design Decisions

I want to make small changes so I can get domain knowledge without trying to eat the elephant in 1 bite.

This whole project will be done via automation tools, but I may need to use GUI or system access to determine next steps.

Secrets will be used, but not protected like production until the end stage.
I will not store any secrets in git so as not to leave something lying around,
but I'm not going to jump through a lot of hopes initially to protect a science fair project.

I want to build in redundancy but cost is a huge consideration, so where in a real production env, I would use 3 instances, here I will limit that to 2. If I wanted to scale this work out, 
adding a 3rd zone / instance would be easy. - Once the multicloud environment is up, then I might consider using that for redundancy.

## Schema

### IP nets

- AWS CIDR 10.50.0.0/16
  - AZ1 will be odd nets
    - Control AZ1 ..1.0/24
    - Worker AZ1 ..3.0/24
  - AZ2 will be even nets
    - Control AZ2 ..2.0/24
    - Worker AZ2 ..4.0/24
- GCP CIDR 10.51.0.0/16
- Azure CIDR 10.52.0.0/16
- Cluster IPAM 10.64.0.0/12
  - more than 1M pod IPs (10.64.0.1 - 10.79.255.254) should be enough for this project
  - start with 10.64.0.0/16, but reserve the /12 in our schema

## Container Runtime Interface (CRI)

For this project `containerd` was selected. This was primrily or the native package on Ubuntu.
CRI-O has a slightly smaller footprint, but requires installing additional apt repos.
There did not seem to be enough of an advantage at this point to warrant the additional isntallation configuration and maintenance.



## Container Network Interface (CNI)

Options considered with pro / cons:

1. Flannel - simple encapsulated network 
  1. Pros: Probably the simplest to setup; Would get things running quickly
  2. Cons: No network policy; does not appear easy to work with mesh layer
2. Calico - network & network policy in one
  1. Pros: 1 plugin provides network and network policy; very effcient; integrates with service mesh (istio); native debugging tools
  2. Cons: More to configure
3. Weave - network, network policy & encryption in one
  1. Pros: definitely a 1 stop shop; takes place of istio
  2. Cons: takes place of istio; 

Flannel was ruled out because of lack of network policy & possible problems getting to work with side car mesh / encryption.

Weave is appealing because of its all encompasing nature. However, doing encryption on the node means that data between pods on the same node will not be secured, so a compromoside pod could endanger the entire nodes (& probably clusters) traffic.

Calico with istio is tho solution selected. This will allow a phased approach to implementation:

1. CNI
2. Network Policies
3. Encryption with istio side cars

## Referencs

- https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin
- https://github.com/Ahmad-Faqehi/Terraform-Bulding-K8S
- https://mrmaheshrajput.medium.com/deploy-kubernetes-cluster-on-aws-ec2-instances-f3eeca9e95f1

### CRI Research

- https://charleswan111.medium.com/cri-o-vs-containerd-choosing-and-managing-kubernetes-container-runtimes-effectively-7b40b7194e9d
- https://cri-o.io/
- https://vineetcic.medium.com/the-differences-between-docker-containerd-cri-o-and-runc-a93ae4c9fdac
- https://phoenixnap.com/kb/docker-vs-containerd-vs-cri-o

### CNI Research

- https://www.tigera.io/learn/guides/kubernetes-networking/kubernetes-cni/
- https://github.com/flannel-io/flannel
- https://www.suse.com/c/rancher_blog/comparing-kubernetes-cni-providers-flannel-calico-canal-and-weave/
- https://kubernetes.io/docs/concepts/cluster-administration/addons/
