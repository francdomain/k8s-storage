# Exercise 2: Multi-Replica Web App

This exercise demonstrates deploying an application where multiple pods share storage using RWX (ReadWriteMany).

## Steps:

1. **Deploy NFS Server**: Simple NFS server for RWX storage
2. **Create RWX PVC**: Persistent volume claim using NFS
3. **Deploy Web Application**: 3 replicas sharing the same storage
4. **Test Shared Access**: Verify writes from one pod are visible in others