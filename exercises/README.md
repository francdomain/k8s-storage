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