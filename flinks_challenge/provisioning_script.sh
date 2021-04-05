#!/bin/bash

#Script to provision two Nginx services on microk8s cluster

microk8s kubectl version &> /dev/null
if [ `echo $?` == 1 ];
then
echo "Please install microk8s in your environment"
else

#Enabling the microk8s addons

echo "Working on addons for microk8s..."

{
microk8s enable dns
microk8s enable registry
microk8s enable helm3
} &> /dev/null

echo "Enabled dns registry and helm3"

#Build and push the docker image to microk8s docker regsitry
echo "Building an nginx docker image and pushing the image to micork8s docker registry..."

docker build ./docker/ -t localhost:32000/nginxapp:2.1
docker push localhost:32000/nginxapp:2.1

#Create namespace on cluster
echo "Creating namespaces on microk8s.."
microk8s kubectl create namespace flinks
microk8s kubectl create namespace ingress-controller

#Deploy Nginx ingress controller using helm
echo "Add the Helm chart for Nginx Ingress"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
echo "Deploying nginx ingress controller"
helm install app-ingress ingress-nginx/ingress-nginx --namespace ingress-controller --set controller.replicaCount=2 > /tmp/helm_out
head -n 6 /tmp/helm_out

#Deploy Nginx applications on cluster
echo "Deploying first nginxapp on the cluster"
microk8s kubectl create -f ./nginx_app/nginxapp1.yaml

echo "Deploying second nginxapp on the cluster"
microk8s kubectl create -f ./nginx_app/nginxapp2.yaml

microk8s kubectl create -f ./nginx_app/ingress.yaml

echo "done with application deployments on microk8s cluster"
echo "================================================"
microk8s kubectl get all -n ingress-controller  -o wide | grep -i load
echo "================================================"
echo "map the LB ip to both challenge.domain.local and challenge-api.domain.local in /etc/hosts to access the service"

fi


