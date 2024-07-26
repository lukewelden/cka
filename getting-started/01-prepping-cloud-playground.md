# Preparing the Cloud Playground Environment
Whilst following along with the course we can make use of ACG's cloud playgrounds. Specifically the Cloud Servers. Run through the following steps to setup the Cloud Servers. 

## Steps
1. Browse to [Cloud Servers](https://learn.acloud.guru/cloud-playground/cloud-servers)
2. Create 3 Ubuntu 20.04 Focal Fossa LTS servers. Use the size Medium. 
3. SSH into the servers 
4. Set hostnames: `sudo hostnamectl set-hostname ['k8s-control' | 'k8s-worker1' | 'k8s-worker1']`
5. Setup the hostfiles: `sudo vi /etc/hosts` add in private ips followed by the hostname for all servers. It should looks something like this 
```
172.0.0.1 k8s-control
172.0.0.2 k8s-worker1
172.0.0.3 k8s-worker2
```
6. Log out and back in from the servers 