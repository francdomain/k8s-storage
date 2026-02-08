## Prerequisites

**Docker installed and running**

- Update Package Index

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release
```

- Add Docker's Official GPG Key

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

- Set Up Docker Repository

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

- Install Docker Engine

```bash
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

- Start and Enable Docker

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

- Add Your User to Docker Group (to run without sudo)

```bash
sudo groupadd docker  # If docker group doesn't exist
sudo usermod -aG docker $USER
```

- Apply the group changes (need to log out/in or use newgrp)

```bash
newgrp docker
```

- Install Docker Compose (Optional but useful)

```bash
sudo apt-get install -y docker-compose

# Or install the latest version:
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

- Check Docker Version

```bash
docker --version
docker-compose --version
```

### Install kubectl (Kubernetes CLI)

```bash
# Download latest kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Make it executable
chmod +x kubectl

# Move to PATH
sudo mv kubectl /usr/local/bin/

# Verify
kubectl version --client
```

## Set up kubernetes cluster using k3d

```bash
cd k8s-storage
./01-setup-cluster-k3d.sh
```

This creates a k3d cluster with:
- 1 server node + 3 agent nodes
- Built-in `local-path` StorageClass (default)
- Host storage mapped to `~/k3d-storage/storage-lab`

## Exercises Implementation

All exercises from this lab are now implemented in the `exercises/` directory:

k8s-storage/exercises/
├── exercise-1-database/                     # PostgreSQL with persistent storage
│   ├── 01-postgres-pvc.yaml
│   ├── 02-postgres-deployment.yaml
│   ├── 03-test-data.yaml
│   ├── 04-backup-cronjob.yaml
│   └── README.md
├── exercise-2-multi-replica-webapp/         # RWX shared storage with NFS
│   ├── 01-nfs-server.yaml
│   ├── 02-nfs-service.yaml
│   ├── 03-rwx-pvc.yaml
│   ├── 04-webapp-deployment.yaml
│   ├── 05-test-script.sh
│   └── README.md
├── exercise-3-storageclass-comparison/      # Retain vs Delete policies
│   ├── 01-retain-storageclass.yaml
│   ├── 02-delete-storageclass.yaml
│   ├── 03-pvc-retain.yaml
│   ├── 04-pvc-delete.yaml
│   ├── 05-observations.sh
│   └── README.md
└── exercise-4-volume-expansion/              # Volume expansion demonstration
    ├── 01-expandable-storageclass.yaml
    ├── 02-pvc-initial.yaml
    ├── 03-test-pod.yaml
    ├── 04-expand-pvc.yaml
    ├── 05-verification.sh
    └── README.md


### Each exercise has its own README with instructions.

The exercises include:

- Complete Kubernetes manifests
- Test scripts
- Verification steps
- Cleanup instructions