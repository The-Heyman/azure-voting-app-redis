#!/bin/bash
export resourceGroup=demorg
virtualMachine=myVM
adminUser=azureuser
pathToKubeConfig=~/.kube/config

if [ -f $pathToKubeConfig ]
then

    # Create a resource group.
    # az group create --name $resourceGroup --location westeurope

    # Create a new virtual machine, this creates SSH keys if not present.
    az vm create --resource-group $resourceGroup --name $virtualMachine --admin-username $adminUser --image UbuntuLTS --generate-ssh-keys

    # Open port 80 to allow web traffic to host.
    az vm open-port --port 80 --resource-group $resourceGroup --name $virtualMachine  --priority 101

    # Open port 22 to allow ssh traffic to host.
    az vm open-port --port 22 --resource-group $resourceGroup --name $virtualMachine --priority 102

    # Open port 8080 to allow web traffic to host.
    az vm open-port --port 8080 --resource-group $resourceGroup --name $virtualMachine --priority 103

    # Use CustomScript extension to install NGINX.
    az vm extension set --publisher Microsoft.Azure.Extensions --name CustomScript --vm-name $virtualMachine --resource-group $resourceGroup --settings '{"fileUris": ["https://raw.githubusercontent.com/Azure-Samples/azure-voting-app-redis/master/jenkins-tutorial/config-jenkins.sh"],"commandToExecute": "./config-jenkins.sh"}'

    # Get public IP
    ip=$(az vm list-ip-addresses --resource-group $resourceGroup --name $virtualMachine --query [0].virtualMachine.network.publicIpAddresses[0].ipAddress -o tsv)

    # Copy Kube config file to Jenkins
    ssh -o "StrictHostKeyChecking no" $adminUser@$ip sudo chmod 777 /var/lib/jenkins
    yes | scp $pathToKubeConfig $adminUser@$ip:/var/lib/jenkins/config
    ssh -o "StrictHostKeyChecking no" $adminUser@$ip sudo chmod 777 /var/lib/jenkins/config

    # Get Jenkins Unlock Key
    url="http://$ip:8080"
    echo "Open a browser to $url"
    echo "Enter the following to Unlock Jenkins:"
    ssh -o "StrictHostKeyChecking no" $adminUser@$ip sudo "cat /var/lib/jenkins/secrets/initialAdminPassword"

else
    echo "Kubernetes configuration / authentication file not found. Run az aks get-credentials to download this file."
fi


# ssh -o "StrictHostKeyChecking no" azureuser@52.186.142.23 sudo chmod 777 /var/lib/jenkins
# yes | scp ~/.kube/config azureuser@52.186.142.23:/var/lib/jenkins/config
# ssh -o "StrictHostKeyChecking no" azureuser@52.186.142.23 sudo chmod 777 /var/lib/jenkins/config


# imagePullSecrets:
#         - name: registry-secret


# kubectl create secret docker-registry newsecret \
#     --docker-server=domoacr.azurecr.io \
#     --docker-username=fa769200-f73a-4387-a78d-dc9534c01847 \
#     --docker-password=8hu0GmerBEFM.PFE-yuosXTGnntAtnQ7Ma

# ssh -o "StrictHostKeyChecking no" azureuser@52.186.142.23 sudo chmod 777 /var/lib/jenkins
# yes | scp ~/.kube/config azureuser@52.186.142.23:/var/lib/jenkins/config
# ssh -o "StrictHostKeyChecking no" azureuser@52.186.142.23 sudo chmod 777 /var/lib/jenkins/config