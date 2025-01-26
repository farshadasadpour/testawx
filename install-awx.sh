#!/bin/bash

# Step 1: Create necessary directories for k3s configuration
echo "Creating k3s configuration directory..."
sudo mkdir -p /etc/rancher/k3s/

# Step 2: Download the K3s installation script
echo "Downloading K3s installation script from the internet..."
curl -sfL https://get.k3s.io -o install.sh

# Step 3: Make the installation script executable
sudo chmod +x install.sh

# Step 4: Install K3s
echo "Installing K3s from the internet..."
sudo ./install.sh

# Cleanup: Remove the installation script
rm install.sh

echo "K3s installed successfully."

# Step 5: Download k3s binary
echo "Downloading k3s binary from the internet..."
wget https://github.com/k3s-io/k3s/releases/download/v1.26.5+k3s1/k3s

# Step 6: Install k3s binary
sudo cp k3s /usr/local/bin/
sudo chmod +x /usr/local/bin/k3s
sudo rm -rf k3s
echo "k3s binary installed successfully."

# Step 7: Download kubectl
echo "Downloading kubectl from the internet..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Step 8: Install kubectl binary
sudo mv kubectl /usr/local/bin/
sudo chmod +x /usr/local/bin/kubectl
echo "kubectl installed successfully."

# Step 9: Configure KUBECONFIG
export KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
echo "KUBECONFIG set and permissions updated."

# Step 10: Download Helm
echo "Downloading Helm from the internet..."
curl -LO https://get.helm.sh/helm-v3.13.1-linux-amd64.tar.gz

# Step 11: Install Helm
tar -zxf helm-v3.13.1-linux-amd64.tar.gz
sudo cp linux-amd64/helm /usr/local/bin/
rm -rf linux-amd64 helm-v3.13.1-linux-amd64.tar.gz
echo "Helm installed successfully."

# Step 12: Set up AWX Operator repository

echo "Setting up AWX Operator repository from the internet..."
# Add Helm repository
echo "Adding AWX Operator Helm repository..."
helm repo add awx-operator-helm https://ansible-community.github.io/awx-operator-helm/
helm repo update

echo "AWX Operator setup complete."

# Step 13: Install AWX

echo "Installing AWX..."
helm install my-awx-operator awx-operator-helm/awx-operator --version 2.18.0 -n awx --create-namespace --set AWX.enabled=true

echo "AWX Operator installed successfully."

# Step 14: Configure KUBECONFIG environment variable
echo "Configuring KUBECONFIG..."
export KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
echo "KUBECONFIG set and permissions updated. If kubectl does not work, use: KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl get pods -A"

# Step 15: Create NodePort service for AWX port 32000
echo "Creating NodePort service for AWX (port 32000)..."
cat << EOF | KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/component: awx
    app.kubernetes.io/managed-by: awx-operator
    app.kubernetes.io/operator-version: 2.18.0
    app.kubernetes.io/part-of: awx
  name: awx--nodeport-service
  namespace: awx
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 8052
    nodePort: 32000
  selector:
    app.kubernetes.io/component: awx
    app.kubernetes.io/managed-by: awx-operator
    app.kubernetes.io/name: awx-web
  type: NodePort
EOF

echo "NodePort service created successfully."

ip_address=$(hostname -I | awk '{print $1}')
echo "Your system's IP address is: $ip_address and awx node port is 32000"

# Step 16: Display AWX admin password
echo "Retrieving AWX admin password..."
KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl get secrets awx-admin-password -n awx -o jsonpath="{.data.password}" | base64 --decode
echo -e "\nAWX admin password displayed above."
